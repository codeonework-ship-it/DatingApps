-- ─────────────────────────────────────────────────────────────────────────────
-- 132: Member action log (2026-10-02)
--
-- The BFF's activity middleware now records every mutating request a
-- signed-in member makes (POST/PUT/PATCH/DELETE outside /admin) as
-- event_domain 'member_action' in matching.activity_events, written
-- synchronously with the action catalog key/label/category, the verified actor,
-- session, request/correlation ids, client IP, device, platform, app version
-- and user agent (backend/internal/bff/mobile/activity_repository.go,
-- member_action_catalog.go). Reads stay 'api_request' telemetry without an IP.
-- Operators read the merged log at /v1/admin/activity,
-- /v1/admin/members/{userID}/activity and /v1/admin/activity/stream
-- (admin_member_activity.go).
--
-- 1. Retention: a 'member_action_history' class of 400 days, run by
--    platform.run_client_telemetry_retention (migration 122) next to the
--    90-day 'api_request_telemetry' class, skipping members on legal hold.
--    The function gains a fourth output column, member_action_events; the BFF
--    selects its columns by name and still works against the 122 version.
--
-- 2. Indexes for the per-member log:
--    * matching.activity_events(user_id, created_at DESC)       WHERE member_action
--    * matching.activity_events(actor_user_id, created_at DESC) WHERE member_action
--    * matching.activity_events((payload #>> '{details,action_key}'), created_at DESC)
--      and ((payload #>> '{details,action_category}'), created_at DESC)
--      WHERE member_action: the action and category filters
--    * matching.activity_events(created_at DESC) WHERE neither api_request nor
--      member_action: the 'event' source of the log
--    * platform.domain_event_outbox(subject_user_id, occurred_at DESC) and
--      (actor_user_id, occurred_at DESC), partial on NOT NULL: the 'domain'
--      source of the log filters a member on either column, and the outbox
--      had no actor index at all (an OR over it was a sequential scan).
--    (event_domain, created_at DESC) already exists (036, repeated in 131).
--
-- 3. Domain event coverage: register the product tables that had no
--    platform.register_event_source (the coverage query of
--    /v1/admin/events/metrics listed 11), so their changes reach the outbox.
--
-- Safe to run repeatedly. Additive only.
--
-- PRODUCTION: run each CREATE INDEX as CREATE INDEX CONCURRENTLY IF NOT
-- EXISTS, one at a time and outside a transaction block (CONCURRENTLY cannot
-- run in one), so activity_events and domain_event_outbox are not locked
-- against writes while the index builds. Plain CREATE INDEX is used here for
-- the local database. This file has no BEGIN/COMMIT so it converts directly.
-- ─────────────────────────────────────────────────────────────────────────────

-- ── Indexes ─────────────────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_activity_events_member_action_user_time
  ON matching.activity_events (user_id, created_at DESC)
  WHERE event_domain = 'member_action';

CREATE INDEX IF NOT EXISTS idx_activity_events_member_action_actor_time
  ON matching.activity_events (actor_user_id, created_at DESC)
  WHERE event_domain = 'member_action';

-- Filters on the catalog key and category of a member action.
CREATE INDEX IF NOT EXISTS idx_activity_events_member_action_key_time
  ON matching.activity_events ((payload #>> '{details,action_key}'), created_at DESC)
  WHERE event_domain = 'member_action';

CREATE INDEX IF NOT EXISTS idx_activity_events_member_action_category_time
  ON matching.activity_events ((payload #>> '{details,action_category}'), created_at DESC)
  WHERE event_domain = 'member_action';

-- The 'event' source (every other domain) is ~1% of the table; without its
-- own index a newest-first page walks the request telemetry to find it.
CREATE INDEX IF NOT EXISTS idx_activity_events_named_time
  ON matching.activity_events (created_at DESC)
  WHERE event_domain NOT IN ('api_request', 'member_action');

CREATE INDEX IF NOT EXISTS idx_domain_event_subject_occurred
  ON platform.domain_event_outbox (subject_user_id, occurred_at DESC)
  WHERE subject_user_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_domain_event_actor_occurred
  ON platform.domain_event_outbox (actor_user_id, occurred_at DESC)
  WHERE actor_user_id IS NOT NULL;

-- ── Retention ──────────────────────────────────────────────────────────────
INSERT INTO platform.retention_policies (policy_name, relation_name, retention_interval, batch_size)
VALUES ('member_action_history', 'matching.activity_events', INTERVAL '400 days', 5000)
ON CONFLICT (policy_name) DO NOTHING;

-- The output columns change, which CREATE OR REPLACE cannot do.
DROP FUNCTION IF EXISTS platform.run_client_telemetry_retention(INTEGER);

CREATE FUNCTION platform.run_client_telemetry_retention(p_batch_size INTEGER DEFAULT 1000)
RETURNS TABLE(
  api_request_events INTEGER,
  client_error_occurrences INTEGER,
  client_error_issues INTEGER,
  member_action_events INTEGER
)
LANGUAGE plpgsql
AS $function$
DECLARE
  batch INTEGER := LEAST(GREATEST(COALESCE(p_batch_size, 1000), 1), 10000);
  window_interval INTERVAL;
BEGIN
  api_request_events := 0; client_error_occurrences := 0; client_error_issues := 0;
  member_action_events := 0;

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

  -- Member actions (migration 132): 400 days, legal holds respected.
  SELECT retention_interval INTO window_interval FROM platform.retention_policies
  WHERE policy_name = 'member_action_history' AND enabled;
  IF window_interval IS NOT NULL THEN
    WITH c AS (
      SELECT id FROM matching.activity_events
      WHERE event_domain = 'member_action'
        AND created_at < NOW() - window_interval
        AND NOT platform.member_on_legal_hold(user_id)
        AND NOT platform.member_on_legal_hold(actor_user_id)
      ORDER BY created_at LIMIT batch
    )
    DELETE FROM matching.activity_events e USING c WHERE e.id = c.id;
    GET DIAGNOSTICS member_action_events = ROW_COUNT;
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

-- ── Domain event coverage ──────────────────────────────────────────────────
-- Tables are registered only where they exist and are not registered yet, so
-- an environment that lacks one of the later feature migrations still applies
-- this file, and an existing registration (with its aggregate name) is kept.
DO $$
DECLARE source RECORD;
BEGIN
  FOR source IN
    SELECT * FROM (VALUES
      ('progression',     'xp_award_repair_queue'),
      ('progression',     'rollout_stage_history'),
      ('progression',     'fraud_rule_policies'),
      ('user_management', 'account_recovery_requests'),
      ('user_management', 'profile_stories'),
      ('matching',        'date_plan_sharing'),
      ('matching',        'friend_request_declines'),
      ('matching',        'friend_request_sends'),
      ('matching',        'conversation_room_blocks'),
      ('matching',        'group_categories'),
      ('matching',        'community_group_covers'),
      ('matching',        'blog_media_deletions')
    ) AS t(schema_name, table_name)
  LOOP
    IF to_regclass(format('%I.%I', source.schema_name, source.table_name)) IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM platform.event_source_registry r
                       WHERE r.source_schema = source.schema_name AND r.source_table = source.table_name AND r.enabled) THEN
      PERFORM platform.register_event_source(source.schema_name, source.table_name);
    END IF;
  END LOOP;
END;
$$;
