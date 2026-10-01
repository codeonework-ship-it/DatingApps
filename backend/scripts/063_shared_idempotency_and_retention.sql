BEGIN;

CREATE SCHEMA IF NOT EXISTS platform;

-- The active table is intentionally unpartitioned: PostgreSQL cannot enforce a
-- global idempotency-key uniqueness constraint across time-range partitions.
-- Expired rows are moved in bounded batches to the partitioned archive below.
CREATE TABLE IF NOT EXISTS platform.idempotency_records (
  cache_key TEXT PRIMARY KEY CHECK (cache_key ~ '^[0-9a-f]{64}$'),
  method TEXT NOT NULL CHECK (method IN ('POST','PUT','PATCH','DELETE')),
  request_path TEXT NOT NULL,
  actor_id TEXT NOT NULL,
  idempotency_key TEXT NOT NULL CHECK (length(idempotency_key) BETWEEN 1 AND 255),
  request_hash TEXT NOT NULL CHECK (request_hash ~ '^[0-9a-f]{64}$'),
  state TEXT NOT NULL DEFAULT 'processing' CHECK (state IN ('processing','completed')),
  owner_token UUID NOT NULL,
  response_status INTEGER CHECK (response_status BETWEEN 100 AND 599),
  response_content_type TEXT,
  response_body BYTEA,
  lease_expires_at TIMESTAMPTZ NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  completed_at TIMESTAMPTZ,
  CHECK (
    (state = 'processing' AND completed_at IS NULL) OR
    (state = 'completed' AND completed_at IS NOT NULL AND response_status IS NOT NULL)
  )
);

CREATE INDEX IF NOT EXISTS idx_idempotency_processing_lease
  ON platform.idempotency_records(lease_expires_at, cache_key)
  WHERE state = 'processing';
CREATE INDEX IF NOT EXISTS idx_idempotency_completed_expiry
  ON platform.idempotency_records(expires_at, cache_key)
  INCLUDE (response_status, response_content_type)
  WHERE state = 'completed';
CREATE INDEX IF NOT EXISTS idx_idempotency_actor_recent
  ON platform.idempotency_records(actor_id, created_at DESC);

CREATE TABLE IF NOT EXISTS platform.idempotency_archive (
  cache_key TEXT NOT NULL,
  method TEXT NOT NULL,
  request_path TEXT NOT NULL,
  actor_id TEXT NOT NULL,
  idempotency_key TEXT NOT NULL,
  request_hash TEXT NOT NULL,
  response_status INTEGER NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  completed_at TIMESTAMPTZ NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  archived_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (cache_key, archived_at)
) PARTITION BY RANGE (archived_at);

CREATE OR REPLACE FUNCTION platform.ensure_idempotency_archive_partition(p_month DATE)
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
  start_date DATE := date_trunc('month', p_month)::DATE;
  end_date DATE := (date_trunc('month', p_month) + INTERVAL '1 month')::DATE;
  partition_name TEXT := 'idempotency_archive_' || to_char(start_date, 'YYYY_MM');
BEGIN
  EXECUTE format(
    'CREATE TABLE IF NOT EXISTS platform.%I PARTITION OF platform.idempotency_archive FOR VALUES FROM (%L) TO (%L)',
    partition_name, start_date, end_date
  );
END;
$$;

SELECT platform.ensure_idempotency_archive_partition(CURRENT_DATE);
SELECT platform.ensure_idempotency_archive_partition((CURRENT_DATE + INTERVAL '1 month')::DATE);

CREATE TABLE IF NOT EXISTS platform.retention_policies (
  policy_name TEXT PRIMARY KEY,
  relation_name TEXT NOT NULL,
  retention_interval INTERVAL NOT NULL CHECK (retention_interval > INTERVAL '0'),
  batch_size INTEGER NOT NULL DEFAULT 1000 CHECK (batch_size BETWEEN 1 AND 10000),
  enabled BOOLEAN NOT NULL DEFAULT TRUE,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO platform.retention_policies(policy_name, relation_name, retention_interval, batch_size)
VALUES
  ('idempotency_archive', 'platform.idempotency_archive', INTERVAL '30 days', 2000),
  ('notification_delivery_history', 'matching.notification_outbox', INTERVAL '90 days', 1000),
  ('realtime_delivery_history', 'matching.realtime_outbox', INTERVAL '30 days', 1000)
ON CONFLICT (policy_name) DO UPDATE SET
  relation_name = EXCLUDED.relation_name,
  retention_interval = EXCLUDED.retention_interval,
  batch_size = EXCLUDED.batch_size,
  updated_at = NOW();

-- Multiple cleanup workers may call this concurrently. SKIP LOCKED keeps each
-- batch independent and prevents retention work from blocking request traffic.
CREATE OR REPLACE FUNCTION platform.archive_expired_idempotency(p_batch_size INTEGER DEFAULT 1000)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
  moved INTEGER := 0;
BEGIN
  PERFORM platform.ensure_idempotency_archive_partition(CURRENT_DATE);
  PERFORM platform.ensure_idempotency_archive_partition((CURRENT_DATE + INTERVAL '1 month')::DATE);

  WITH candidates AS (
    SELECT cache_key
    FROM platform.idempotency_records
    WHERE state = 'completed' AND expires_at < NOW()
    ORDER BY expires_at, cache_key
    LIMIT LEAST(GREATEST(p_batch_size, 1), 10000)
    FOR UPDATE SKIP LOCKED
  ), archived AS (
    INSERT INTO platform.idempotency_archive (
      cache_key, method, request_path, actor_id, idempotency_key,
      request_hash, response_status, created_at, completed_at, expires_at
    )
    SELECT r.cache_key, r.method, r.request_path, r.actor_id, r.idempotency_key,
           r.request_hash, r.response_status, r.created_at, r.completed_at, r.expires_at
    FROM platform.idempotency_records r
    JOIN candidates c USING (cache_key)
    RETURNING cache_key
  )
  DELETE FROM platform.idempotency_records r
  USING archived a
  WHERE r.cache_key = a.cache_key;
  GET DIAGNOSTICS moved = ROW_COUNT;

  -- A request whose owner died before finishing is safe to forget after both
  -- its lease and replay window have elapsed.
  WITH stale AS (
    SELECT cache_key
    FROM platform.idempotency_records
    WHERE state = 'processing' AND lease_expires_at < NOW() AND expires_at < NOW()
    ORDER BY expires_at, cache_key
    LIMIT LEAST(GREATEST(p_batch_size, 1), 10000)
    FOR UPDATE SKIP LOCKED
  )
  DELETE FROM platform.idempotency_records r
  USING stale s
  WHERE r.cache_key = s.cache_key;

  RETURN moved;
END;
$$;

CREATE OR REPLACE FUNCTION platform.run_runtime_retention(p_batch_size INTEGER DEFAULT 1000)
RETURNS TABLE(notification_rows INTEGER, realtime_rows INTEGER)
LANGUAGE plpgsql
AS $$
DECLARE
  notification_retention INTERVAL;
  realtime_retention INTERVAL;
BEGIN
  SELECT retention_interval INTO notification_retention
  FROM platform.retention_policies
  WHERE policy_name='notification_delivery_history' AND enabled;
  SELECT retention_interval INTO realtime_retention
  FROM platform.retention_policies
  WHERE policy_name='realtime_delivery_history' AND enabled;

  notification_rows := 0;
  realtime_rows := 0;
  IF notification_retention IS NOT NULL THEN
    WITH candidates AS (
      SELECT id
      FROM matching.notification_outbox
      WHERE status IN ('delivered','suppressed','dead_letter')
        AND updated_at < NOW() - notification_retention
      ORDER BY updated_at,id
      LIMIT LEAST(GREATEST(p_batch_size,1),10000)
      FOR UPDATE SKIP LOCKED
    )
    DELETE FROM matching.notification_outbox o
    USING candidates c
    WHERE o.id=c.id;
    GET DIAGNOSTICS notification_rows = ROW_COUNT;
  END IF;

  IF realtime_retention IS NOT NULL THEN
    WITH candidates AS (
      SELECT sequence_id
      FROM matching.realtime_outbox
      WHERE expires_at < NOW() - realtime_retention
      ORDER BY expires_at,sequence_id
      LIMIT LEAST(GREATEST(p_batch_size,1),10000)
      FOR UPDATE SKIP LOCKED
    )
    DELETE FROM matching.realtime_outbox o
    USING candidates c
    WHERE o.sequence_id=c.sequence_id;
    GET DIAGNOSTICS realtime_rows = ROW_COUNT;
  END IF;
  RETURN NEXT;
END;
$$;

CREATE OR REPLACE VIEW platform.idempotency_health AS
SELECT
  COUNT(*) FILTER (WHERE state = 'processing') AS processing,
  COUNT(*) FILTER (WHERE state = 'processing' AND lease_expires_at < NOW()) AS expired_leases,
  COUNT(*) FILTER (WHERE state = 'completed') AS replayable,
  COUNT(*) FILTER (WHERE expires_at < NOW()) AS retention_backlog,
  COALESCE(EXTRACT(EPOCH FROM NOW() - MIN(created_at) FILTER (WHERE state = 'processing')), 0)::BIGINT
    AS oldest_processing_age_seconds
FROM platform.idempotency_records;

COMMIT;

-- Rollback (maintenance window):
-- DROP VIEW IF EXISTS platform.idempotency_health;
-- DROP FUNCTION IF EXISTS platform.archive_expired_idempotency(INTEGER);
-- DROP FUNCTION IF EXISTS platform.run_runtime_retention(INTEGER);
-- DROP FUNCTION IF EXISTS platform.ensure_idempotency_archive_partition(DATE);
-- DROP TABLE IF EXISTS platform.idempotency_archive CASCADE;
-- DROP TABLE IF EXISTS platform.idempotency_records;
