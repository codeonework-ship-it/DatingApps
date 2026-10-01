-- ─────────────────────────────────────────────────────────────────────────────
-- 122: Self-hosted client crash/error reporting + request telemetry privacy
--
-- 1. Client error reporting (POST /v1/client/errors, admin /v1/admin/client-errors).
--    Reports are grouped into issues by a server-computed fingerprint. They are
--    anonymous: no account id is stored, only a random per-install id and a
--    signed_in flag. Occurrences are capped per issue by the BFF and kept 90
--    days; issues not seen for 90 days are removed with their history.
--
-- 2. Request telemetry minimisation (matching.activity_events). The BFF's
--    request middleware stored every API call with the raw client IP
--    (payload.details.remote_addr), the full query string and the concrete
--    path (member ids inside it), forever. From now on it stores the route
--    template only, no IP and no query string, under event_domain
--    'api_request'. This migration reclassifies and minimises existing rows and
--    adds a 90-day retention class for request telemetry. Domain events
--    (wallet purchases, gestures, quests …) are not request telemetry and keep
--    their existing lifetime.
--
-- 3. platform.run_client_telemetry_retention(batch) — called hourly by the
--    BFF's trust retention worker next to platform.run_trust_retention.
--
-- Deliberately NOT changed here (needs an owner decision, see the privacy
-- document): migration 036 attached the generic row-change audit trigger to
-- matching.activity_events, so audit.change_log holds a full copy of every
-- request row (including the old remote_addr/query) under its 24-month
-- retention, and the minimising UPDATE below is itself recorded there.
--
-- See documents/CLIENT_ERROR_REPORTING_AND_PRIVACY_2026-10-01.md.
-- Safe to run repeatedly.
-- ─────────────────────────────────────────────────────────────────────────────

CREATE SCHEMA IF NOT EXISTS platform;

CREATE TABLE IF NOT EXISTS platform.client_error_issues (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  fingerprint         TEXT NOT NULL UNIQUE CHECK (char_length(fingerprint) BETWEEN 8 AND 128),
  error_type          TEXT NOT NULL CHECK (char_length(error_type) BETWEEN 1 AND 120),
  title               TEXT NOT NULL CHECK (char_length(title) <= 300),
  culprit             TEXT NOT NULL DEFAULT '' CHECK (char_length(culprit) <= 300),
  status              TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open','resolved','ignored')),
  fatal               BOOLEAN NOT NULL DEFAULT FALSE,
  regressed           BOOLEAN NOT NULL DEFAULT FALSE,
  regression_count    INTEGER NOT NULL DEFAULT 0 CHECK (regression_count >= 0),
  occurrence_count    BIGINT NOT NULL DEFAULT 0 CHECK (occurrence_count >= 0),
  affected_users      BIGINT NOT NULL DEFAULT 0 CHECK (affected_users >= 0),
  platforms           TEXT[] NOT NULL DEFAULT '{}',
  first_seen_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  last_seen_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  resolved_at         TIMESTAMPTZ,
  resolved_in_version TEXT CHECK (resolved_in_version IS NULL OR char_length(resolved_in_version) <= 32),
  status_changed_at   TIMESTAMPTZ,
  status_changed_by   UUID,
  status_note         TEXT CHECK (status_note IS NULL OR char_length(status_note) <= 500),
  reopened_at         TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_client_error_issues_status_last_seen
  ON platform.client_error_issues(status, last_seen_at DESC);
CREATE INDEX IF NOT EXISTS idx_client_error_issues_last_seen
  ON platform.client_error_issues(last_seen_at);

-- One row per (issue, app version, platform): drives the version/platform
-- filters, the versions table on the issue page and regression detection.
CREATE TABLE IF NOT EXISTS platform.client_error_issue_versions (
  issue_id      UUID NOT NULL REFERENCES platform.client_error_issues(id) ON DELETE CASCADE,
  app_version   TEXT NOT NULL CHECK (char_length(app_version) BETWEEN 1 AND 32),
  platform      TEXT NOT NULL CHECK (platform IN ('android','ios','web','macos','windows','linux')),
  occurrences   BIGINT NOT NULL DEFAULT 0 CHECK (occurrences >= 0),
  first_seen_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  last_seen_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (issue_id, app_version, platform)
);

CREATE INDEX IF NOT EXISTS idx_client_error_versions_filter
  ON platform.client_error_issue_versions(app_version, platform);

-- Distinct reporters per issue, for the affected-users count. The key is a
-- sha256 of the random install id, never an account id.
CREATE TABLE IF NOT EXISTS platform.client_error_issue_reporters (
  issue_id      UUID NOT NULL REFERENCES platform.client_error_issues(id) ON DELETE CASCADE,
  reporter_key  TEXT NOT NULL CHECK (char_length(reporter_key) = 64),
  first_seen_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  last_seen_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (issue_id, reporter_key)
);

CREATE INDEX IF NOT EXISTS idx_client_error_reporters_last_seen
  ON platform.client_error_issue_reporters(last_seen_at);

CREATE TABLE IF NOT EXISTS platform.client_error_occurrences (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  issue_id      UUID NOT NULL REFERENCES platform.client_error_issues(id) ON DELETE CASCADE,
  occurred_at   TIMESTAMPTZ NOT NULL,
  received_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  app_version   TEXT NOT NULL CHECK (char_length(app_version) BETWEEN 1 AND 32),
  build_number  TEXT NOT NULL DEFAULT '' CHECK (char_length(build_number) <= 16),
  platform      TEXT NOT NULL CHECK (platform IN ('android','ios','web','macos','windows','linux')),
  os_version    TEXT NOT NULL DEFAULT '' CHECK (char_length(os_version) <= 64),
  device_class  TEXT NOT NULL DEFAULT 'unknown' CHECK (device_class IN ('phone','tablet','desktop','web','unknown')),
  locale        TEXT NOT NULL DEFAULT '' CHECK (char_length(locale) <= 16),
  screen        TEXT NOT NULL DEFAULT '' CHECK (char_length(screen) <= 120),
  source        TEXT NOT NULL DEFAULT 'unknown' CHECK (source IN ('flutter','platform','zone','logger','unknown')),
  message       TEXT NOT NULL DEFAULT '' CHECK (char_length(message) <= 1000),
  stack         TEXT NOT NULL DEFAULT '' CHECK (char_length(stack) <= 8000),
  breadcrumbs   JSONB NOT NULL DEFAULT '[]'::jsonb CHECK (jsonb_typeof(breadcrumbs) = 'array'),
  fatal         BOOLEAN NOT NULL DEFAULT FALSE,
  handled       BOOLEAN NOT NULL DEFAULT FALSE,
  signed_in     BOOLEAN NOT NULL DEFAULT FALSE,
  -- sha256 of the install id: lets the BFF skip storing a crash loop's
  -- repeats without keeping the install id itself.
  reporter_key  TEXT NOT NULL CHECK (char_length(reporter_key) = 64)
);

CREATE INDEX IF NOT EXISTS idx_client_error_occurrences_issue_received
  ON platform.client_error_occurrences(issue_id, received_at DESC);
CREATE INDEX IF NOT EXISTS idx_client_error_occurrences_received
  ON platform.client_error_occurrences(received_at);

INSERT INTO platform.retention_policies (policy_name, relation_name, retention_interval, batch_size)
VALUES
  ('api_request_telemetry', 'matching.activity_events',          INTERVAL '90 days', 5000),
  ('client_error_reports',  'platform.client_error_occurrences', INTERVAL '90 days', 2000)
ON CONFLICT (policy_name) DO NOTHING;

-- ── Minimise existing request telemetry ─────────────────────────────────────
-- Rows written by the request middleware are recognisable by their event
-- name ("GET /v1/…"). Reclassify them as 'api_request', drop the stored client
-- IP and query string, and replace member/match ids in the stored path with
-- "{id}". A single statement so each row is rewritten once.
UPDATE matching.activity_events
SET event_domain = 'api_request',
    event_name = regexp_replace(event_name, '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}', '{id}', 'g'),
    payload = CASE WHEN payload->'details' IS NULL OR jsonb_typeof(payload->'details') <> 'object'
                   THEN payload
                   ELSE jsonb_set(payload #- '{details,remote_addr}' #- '{details,query}', '{details,path}',
                          to_jsonb(regexp_replace(COALESCE(payload->'details'->>'path', ''), '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}', '{id}', 'g')))
              END
              || CASE WHEN payload ? 'resource'
                      THEN jsonb_build_object('resource', regexp_replace(payload->>'resource', '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}', '{id}', 'g'))
                      ELSE '{}'::jsonb END,
    ip_address = NULL
WHERE event_domain IN ('mobile_bff', 'api_request')
  AND event_name ~ '^(GET|POST|PUT|PATCH|DELETE|HEAD|OPTIONS) /'
  AND (payload->'details' ? 'remote_addr'
       OR payload->'details' ? 'query'
       OR ip_address IS NOT NULL
       OR event_domain <> 'api_request'
       OR event_name ~ '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}'
       OR payload->>'resource' ~ '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}');

-- Any other event that copied network context loses it too.
UPDATE matching.activity_events
SET payload = payload #- '{details,remote_addr}' #- '{details,query}',
    ip_address = NULL
WHERE event_domain <> 'api_request'
  AND (payload->'details' ? 'remote_addr' OR payload->'details' ? 'query' OR ip_address IS NOT NULL);

-- ── Retention ──────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION platform.run_client_telemetry_retention(p_batch_size INTEGER DEFAULT 1000)
RETURNS TABLE(
  api_request_events INTEGER,
  client_error_occurrences INTEGER,
  client_error_issues INTEGER
)
LANGUAGE plpgsql
AS $function$
DECLARE
  batch INTEGER := LEAST(GREATEST(COALESCE(p_batch_size, 1000), 1), 10000);
  window_interval INTERVAL;
BEGIN
  api_request_events := 0; client_error_occurrences := 0; client_error_issues := 0;

  -- Request telemetry: 90 days. Members on legal hold keep theirs, as with
  -- the 24-month activity history class of migration 081.
  SELECT retention_interval INTO window_interval FROM platform.retention_policies
  WHERE policy_name = 'api_request_telemetry' AND enabled;
  IF window_interval IS NOT NULL THEN
    WITH c AS (
      SELECT id FROM matching.activity_events
      WHERE event_domain = 'api_request'
        AND created_at < NOW() - window_interval
        AND NOT platform.member_on_legal_hold(user_id)
        AND NOT platform.member_on_legal_hold(actor_user_id)
      ORDER BY created_at LIMIT batch
    )
    DELETE FROM matching.activity_events e USING c WHERE e.id = c.id;
    GET DIAGNOSTICS api_request_events = ROW_COUNT;
  END IF;

  -- Client error reports: occurrences and reporter keys age out after the
  -- window; an issue nobody has reported within the window goes with its
  -- version history.
  SELECT retention_interval INTO window_interval FROM platform.retention_policies
  WHERE policy_name = 'client_error_reports' AND enabled;
  IF window_interval IS NOT NULL THEN
    WITH c AS (
      SELECT id FROM platform.client_error_occurrences
      WHERE received_at < NOW() - window_interval
      ORDER BY received_at LIMIT batch
    )
    DELETE FROM platform.client_error_occurrences o USING c WHERE o.id = c.id;
    GET DIAGNOSTICS client_error_occurrences = ROW_COUNT;

    DELETE FROM platform.client_error_issue_reporters
    WHERE (issue_id, reporter_key) IN (
      SELECT issue_id, reporter_key FROM platform.client_error_issue_reporters
      WHERE last_seen_at < NOW() - window_interval LIMIT batch);

    WITH c AS (
      SELECT id FROM platform.client_error_issues
      WHERE last_seen_at < NOW() - window_interval
      ORDER BY last_seen_at LIMIT batch
    )
    DELETE FROM platform.client_error_issues i USING c WHERE i.id = c.id;
    GET DIAGNOSTICS client_error_issues = ROW_COUNT;
  END IF;

  RETURN NEXT;
END;
$function$;
