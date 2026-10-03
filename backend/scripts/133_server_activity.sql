-- ─────────────────────────────────────────────────────────────────────────────
-- 133: Durable server activity and consumption data (2026-10-02)
--
-- Until now the only durable trace of what the server itself did was the
-- analytics snapshot builder's run table; worker heartbeats, 5xx responses,
-- panics, refusals, sheds and timeouts lived in Prometheus series (not
-- scraped locally) and log lines. The mobile BFF now records them in five
-- low-volume tables that the command center reads through
-- /v1/admin/system/* (backend/internal/bff/mobile/admin_system.go):
--
--   platform.job_runs                 one row per background worker run.
--                                     Low-frequency workers write every run;
--                                     high-frequency workers (level_projection,
--                                     notification_delivery, sos_delivery,
--                                     sos_gauge_refresh, xp_award_spool_replay)
--                                     only failed runs and runs that handled
--                                     items. Written asynchronously from the
--                                     shared heartbeat (observability.WorkerRun).
--   platform.job_run_rollups_hourly   every run of every worker folded into
--                                     (worker, hour), additive upserts once a
--                                     minute; durations as a bucket histogram.
--   platform.request_rollups_hourly   every HTTP request (including refused,
--                                     shed and panicking ones) folded into
--                                     (hour, service, method, route template,
--                                     status class, status code). The exact
--                                     code is kept only for 401/403/404/409/
--                                     429 and 5xx; 0 means "another code of
--                                     this class". Latency buckets match the
--                                     Prometheus DefBuckets so p50/p95/p99 can
--                                     be derived.
--   platform.server_events            notable events: process start/stop,
--                                     panics, 5xx, refusals, worker failures,
--                                     stale workers, retention summaries,
--                                     applied migrations. Aggregated in memory
--                                     to at most one row per (kind, key) per
--                                     minute; the unique key makes the
--                                     once-a-minute flush an additive upsert.
--                                     Messages carry route templates, never
--                                     raw paths, member ids or request data.
--   platform.capacity_snapshots       hourly: database size, connections,
--                                     the 30 largest relations, row estimates
--                                     of the growth tables, stored media bytes
--                                     per kind, local disk.
--   platform.third_party_usage_daily  per day, provider and operation: calls,
--                                     failures and units, aggregated hourly
--                                     from tables the integrations already
--                                     write (no call-site instrumentation).
--
-- Retention (platform.retention_policies, run by
-- platform.run_server_activity_retention from the trust retention worker):
-- job runs 90 days, job and request rollups 400 days, server events 180 days,
-- capacity snapshots and third-party usage 400 days.
--
-- None of these tables is a registered domain event source or carries the
-- row-change audit trigger: they are operational telemetry about the server,
-- not member data, and must not feed the outbox.
--
-- Safe to run repeatedly. Additive only.
-- ─────────────────────────────────────────────────────────────────────────────

BEGIN;

CREATE SCHEMA IF NOT EXISTS platform;

-- ── Job runs ────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS platform.job_runs (
  id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  worker          TEXT NOT NULL CHECK (worker ~ '^[a-z0-9_]{1,64}$'),
  instance        TEXT NOT NULL CHECK (char_length(instance) <= 200),
  build_commit    TEXT CHECK (build_commit IS NULL OR char_length(build_commit) <= 64),
  started_at      TIMESTAMPTZ NOT NULL,
  finished_at     TIMESTAMPTZ NOT NULL,
  duration_ms     BIGINT NOT NULL CHECK (duration_ms >= 0),
  status          TEXT NOT NULL CHECK (status IN ('succeeded', 'failed', 'skipped', 'busy')),
  items_processed BIGINT NOT NULL DEFAULT 0 CHECK (items_processed >= 0),
  items_failed    BIGINT NOT NULL DEFAULT 0 CHECK (items_failed >= 0),
  backlog_after   BIGINT,
  error           TEXT CHECK (error IS NULL OR char_length(error) <= 500),
  details         JSONB NOT NULL DEFAULT '{}'::jsonb
                  CHECK (jsonb_typeof(details) = 'object' AND octet_length(details::text) <= 16384)
);

CREATE INDEX IF NOT EXISTS idx_job_runs_started ON platform.job_runs (started_at DESC, id DESC);
CREATE INDEX IF NOT EXISTS idx_job_runs_worker_started ON platform.job_runs (worker, started_at DESC);
CREATE INDEX IF NOT EXISTS idx_job_runs_status_started ON platform.job_runs (status, started_at DESC);

CREATE TABLE IF NOT EXISTS platform.job_run_rollups_hourly (
  worker           TEXT NOT NULL CHECK (worker ~ '^[a-z0-9_]{1,64}$'),
  -- A UTC hour (date_trunc in the session time zone would reject UTC hours
  -- under a half-hour offset such as Asia/Kolkata).
  hour             TIMESTAMPTZ NOT NULL CHECK (date_trunc('hour', hour AT TIME ZONE 'UTC') = hour AT TIME ZONE 'UTC'),
  runs             BIGINT NOT NULL DEFAULT 0 CHECK (runs >= 0),
  failures         BIGINT NOT NULL DEFAULT 0 CHECK (failures >= 0),
  items            BIGINT NOT NULL DEFAULT 0 CHECK (items >= 0),
  items_failed     BIGINT NOT NULL DEFAULT 0 CHECK (items_failed >= 0),
  sum_duration_ms  BIGINT NOT NULL DEFAULT 0 CHECK (sum_duration_ms >= 0),
  max_duration_ms  BIGINT NOT NULL DEFAULT 0 CHECK (max_duration_ms >= 0),
  -- Non-cumulative run counts per duration bucket, upper bounds in ms:
  -- 5, 25, 100, 500, 1000, 5000, 15000, 60000, 300000, 900000, +Inf.
  duration_buckets BIGINT[] NOT NULL CHECK (cardinality(duration_buckets) = 11),
  last_run_at      TIMESTAMPTZ,
  last_success_at  TIMESTAMPTZ,
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (worker, hour)
);

CREATE INDEX IF NOT EXISTS idx_job_run_rollups_hour ON platform.job_run_rollups_hourly (hour DESC);

-- ── Request rollups ─────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS platform.request_rollups_hourly (
  -- A UTC hour (date_trunc in the session time zone would reject UTC hours
  -- under a half-hour offset such as Asia/Kolkata).
  hour             TIMESTAMPTZ NOT NULL CHECK (date_trunc('hour', hour AT TIME ZONE 'UTC') = hour AT TIME ZONE 'UTC'),
  service          TEXT NOT NULL CHECK (char_length(service) <= 64),
  method           TEXT NOT NULL CHECK (method IN ('GET','POST','PUT','PATCH','DELETE','HEAD','OPTIONS','OTHER')),
  route            TEXT NOT NULL CHECK (char_length(route) <= 300),
  status_class     TEXT NOT NULL CHECK (status_class IN ('1xx','2xx','3xx','4xx','5xx','unknown')),
  -- Exact for 401/403/404/409/429 and every 5xx; 0 = another code of the class.
  status_code      SMALLINT NOT NULL DEFAULT 0,
  requests         BIGINT NOT NULL DEFAULT 0 CHECK (requests >= 0),
  -- Requests with a measured latency (upgraded WebSocket connections are
  -- counted in requests but have no latency).
  timed_requests   BIGINT NOT NULL DEFAULT 0 CHECK (timed_requests >= 0),
  sum_duration_ms  DOUBLE PRECISION NOT NULL DEFAULT 0,
  max_duration_ms  DOUBLE PRECISION NOT NULL DEFAULT 0,
  -- Non-cumulative counts per Prometheus DefBuckets bucket, upper bounds in
  -- seconds: .005 .01 .025 .05 .1 .25 .5 1 2.5 5 10 +Inf.
  duration_buckets BIGINT[] NOT NULL CHECK (cardinality(duration_buckets) = 12),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (hour, service, method, route, status_class, status_code)
);

CREATE INDEX IF NOT EXISTS idx_request_rollups_route_hour ON platform.request_rollups_hourly (route, hour DESC);

-- ── Server events ───────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS platform.server_events (
  id             BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  at             TIMESTAMPTZ NOT NULL,
  kind           TEXT NOT NULL CHECK (kind IN ('process_start','process_stop','panic','server_error','refused',
                                               'worker_failed','worker_stale','retention_summary','migration_applied')),
  severity       TEXT NOT NULL CHECK (severity IN ('info','warning','error','critical')),
  service        TEXT NOT NULL CHECK (char_length(service) <= 64),
  instance       TEXT NOT NULL CHECK (char_length(instance) <= 200),
  message        TEXT NOT NULL CHECK (char_length(message) <= 500),
  route          TEXT CHECK (route IS NULL OR char_length(route) <= 300),
  correlation_id TEXT CHECK (correlation_id IS NULL OR char_length(correlation_id) <= 128),
  count          BIGINT NOT NULL DEFAULT 1 CHECK (count >= 1),
  first_at       TIMESTAMPTZ NOT NULL,
  last_at        TIMESTAMPTZ NOT NULL,
  details        JSONB NOT NULL DEFAULT '{}'::jsonb
                 CHECK (jsonb_typeof(details) = 'object' AND octet_length(details::text) <= 16384),
  -- Aggregation key: one row per (kind, dedupe_key, bucket_at). bucket_at is
  -- the minute (the hour for worker_stale); dedupe_key is e.g. route+status
  -- for server_error, reason+route for refused, the worker for worker_*.
  dedupe_key     TEXT NOT NULL CHECK (char_length(dedupe_key) <= 400),
  bucket_at      TIMESTAMPTZ NOT NULL,
  CONSTRAINT server_events_bucket_key UNIQUE (kind, dedupe_key, bucket_at)
);

CREATE INDEX IF NOT EXISTS idx_server_events_at ON platform.server_events (at DESC, id DESC);
CREATE INDEX IF NOT EXISTS idx_server_events_kind_at ON platform.server_events (kind, at DESC);
CREATE INDEX IF NOT EXISTS idx_server_events_severity_at ON platform.server_events (severity, at DESC);

-- ── Capacity snapshots ──────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS platform.capacity_snapshots (
  id                  BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  at                  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  instance            TEXT NOT NULL CHECK (char_length(instance) <= 200),
  db_size_bytes       BIGINT NOT NULL,
  connections         INTEGER NOT NULL,
  max_connections     INTEGER NOT NULL,
  outbox_rows         BIGINT,
  activity_rows       BIGINT,
  security_event_rows BIGINT,
  media_bytes         JSONB NOT NULL DEFAULT '{}'::jsonb CHECK (jsonb_typeof(media_bytes) = 'object'),
  media_bytes_total   BIGINT NOT NULL DEFAULT 0,
  disk                JSONB NOT NULL DEFAULT '{}'::jsonb CHECK (jsonb_typeof(disk) = 'object'),
  tables              JSONB NOT NULL DEFAULT '[]'::jsonb CHECK (jsonb_typeof(tables) = 'array'),
  duration_ms         INTEGER NOT NULL DEFAULT 0
);

CREATE INDEX IF NOT EXISTS idx_capacity_snapshots_at ON platform.capacity_snapshots (at DESC);

-- ── Third-party usage ───────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS platform.third_party_usage_daily (
  day        DATE NOT NULL,
  provider   TEXT NOT NULL CHECK (char_length(provider) <= 64),
  operation  TEXT NOT NULL CHECK (char_length(operation) <= 64),
  calls      BIGINT NOT NULL DEFAULT 0 CHECK (calls >= 0),
  failures   BIGINT NOT NULL DEFAULT 0 CHECK (failures >= 0),
  units      DOUBLE PRECISION NOT NULL DEFAULT 0,
  unit_label TEXT NOT NULL DEFAULT 'calls' CHECK (char_length(unit_label) <= 32),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (day, provider, operation)
);

-- ── Element-wise array sum for the additive histogram upserts ───────────────
CREATE OR REPLACE FUNCTION platform.add_bigint_arrays(a BIGINT[], b BIGINT[])
RETURNS BIGINT[]
LANGUAGE sql IMMUTABLE PARALLEL SAFE AS $$
  SELECT COALESCE(array_agg(COALESCE(x, 0) + COALESCE(y, 0) ORDER BY n), '{}'::bigint[])
  FROM unnest(a, b) WITH ORDINALITY AS u(x, y, n)
$$;

-- Element-wise sum of histogram arrays across rows (the /admin/system/requests
-- percentiles are derived from the summed buckets).
CREATE OR REPLACE AGGREGATE platform.sum_bigint_arrays(BIGINT[]) (
  SFUNC = platform.add_bigint_arrays,
  STYPE = BIGINT[],
  INITCOND = '{}'
);

-- ── Retention ──────────────────────────────────────────────────────────────
INSERT INTO platform.retention_policies (policy_name, relation_name, retention_interval, batch_size) VALUES
  ('server_job_runs',          'platform.job_runs',                INTERVAL '90 days',  5000),
  ('server_job_rollups',       'platform.job_run_rollups_hourly',  INTERVAL '400 days', 5000),
  ('server_request_rollups',   'platform.request_rollups_hourly',  INTERVAL '400 days', 5000),
  ('server_events',            'platform.server_events',           INTERVAL '180 days', 5000),
  ('server_capacity_snapshots','platform.capacity_snapshots',      INTERVAL '400 days', 1000),
  ('server_third_party_usage', 'platform.third_party_usage_daily', INTERVAL '400 days', 5000)
ON CONFLICT (policy_name) DO NOTHING;

-- The output columns may change in a later migration, which CREATE OR
-- REPLACE cannot do; the BFF selects them by name.
DROP FUNCTION IF EXISTS platform.run_server_activity_retention(INTEGER);

CREATE FUNCTION platform.run_server_activity_retention(p_batch_size INTEGER DEFAULT 1000)
RETURNS TABLE(
  job_runs INTEGER,
  job_rollups INTEGER,
  request_rollups INTEGER,
  server_events INTEGER,
  capacity_snapshots INTEGER,
  third_party_usage INTEGER
)
LANGUAGE plpgsql
AS $function$
DECLARE
  batch INTEGER := LEAST(GREATEST(COALESCE(p_batch_size, 1000), 1), 10000);
  window_interval INTERVAL;
BEGIN
  job_runs := 0; job_rollups := 0; request_rollups := 0;
  server_events := 0; capacity_snapshots := 0; third_party_usage := 0;

  SELECT retention_interval INTO window_interval FROM platform.retention_policies
  WHERE policy_name = 'server_job_runs' AND enabled;
  IF window_interval IS NOT NULL THEN
    WITH c AS (SELECT id FROM platform.job_runs WHERE started_at < NOW() - window_interval ORDER BY started_at LIMIT batch)
    DELETE FROM platform.job_runs t USING c WHERE t.id = c.id;
    GET DIAGNOSTICS job_runs = ROW_COUNT;
  END IF;

  SELECT retention_interval INTO window_interval FROM platform.retention_policies
  WHERE policy_name = 'server_job_rollups' AND enabled;
  IF window_interval IS NOT NULL THEN
    WITH c AS (SELECT worker, hour FROM platform.job_run_rollups_hourly WHERE hour < NOW() - window_interval ORDER BY hour LIMIT batch)
    DELETE FROM platform.job_run_rollups_hourly t USING c WHERE t.worker = c.worker AND t.hour = c.hour;
    GET DIAGNOSTICS job_rollups = ROW_COUNT;
  END IF;

  SELECT retention_interval INTO window_interval FROM platform.retention_policies
  WHERE policy_name = 'server_request_rollups' AND enabled;
  IF window_interval IS NOT NULL THEN
    WITH c AS (SELECT ctid AS row_ctid FROM platform.request_rollups_hourly WHERE hour < NOW() - window_interval ORDER BY hour LIMIT batch)
    DELETE FROM platform.request_rollups_hourly t USING c WHERE t.ctid = c.row_ctid;
    GET DIAGNOSTICS request_rollups = ROW_COUNT;
  END IF;

  SELECT retention_interval INTO window_interval FROM platform.retention_policies
  WHERE policy_name = 'server_events' AND enabled;
  IF window_interval IS NOT NULL THEN
    WITH c AS (SELECT id FROM platform.server_events WHERE at < NOW() - window_interval ORDER BY at LIMIT batch)
    DELETE FROM platform.server_events t USING c WHERE t.id = c.id;
    GET DIAGNOSTICS server_events = ROW_COUNT;
  END IF;

  SELECT retention_interval INTO window_interval FROM platform.retention_policies
  WHERE policy_name = 'server_capacity_snapshots' AND enabled;
  IF window_interval IS NOT NULL THEN
    WITH c AS (SELECT id FROM platform.capacity_snapshots WHERE at < NOW() - window_interval ORDER BY at LIMIT batch)
    DELETE FROM platform.capacity_snapshots t USING c WHERE t.id = c.id;
    GET DIAGNOSTICS capacity_snapshots = ROW_COUNT;
  END IF;

  SELECT retention_interval INTO window_interval FROM platform.retention_policies
  WHERE policy_name = 'server_third_party_usage' AND enabled;
  IF window_interval IS NOT NULL THEN
    WITH c AS (SELECT day, provider, operation FROM platform.third_party_usage_daily
               WHERE day < ((NOW() - window_interval) AT TIME ZONE 'UTC')::date ORDER BY day LIMIT batch)
    DELETE FROM platform.third_party_usage_daily t USING c
    WHERE t.day = c.day AND t.provider = c.provider AND t.operation = c.operation;
    GET DIAGNOSTICS third_party_usage = ROW_COUNT;
  END IF;

  RETURN NEXT;
END;
$function$;

COMMIT;
