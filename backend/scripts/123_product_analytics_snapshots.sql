-- ─────────────────────────────────────────────────────────────────────────────
-- 123: Durable product analytics snapshots
--
-- Reporting used to read either the latest-activity row per member
-- (platform.member_last_activity, migration 087: no history) or the BFF's
-- in-memory activity list (empty when Postgres is configured, per instance,
-- reset on restart). This migration adds a history that survives restarts and
-- is identical on every instance:
--
--   analytics.member_active_days   one row per member per UTC day with
--                                  qualifying activity (DAU/WAU/MAU, retention)
--   analytics.member_surface_days  one row per member per UTC day per product
--                                  surface used, with an action count
--                                  (feature engagement, repeat use, good days)
--   analytics.daily_metrics        additive daily counts by segment cell
--                                  (gender × city × age band × account age band
--                                  × level band), plus dau/wau/mau per cell
--   analytics.member_milestones    first time each member reached each
--                                  activation step (funnel)
--
-- Sources are durable domain tables only. matching.activity_events is NOT read:
-- it is being reduced for privacy and has a 90-day retention.
--
-- Who counts: analytics.reportable_members. Operators (any role other than
-- `user`), introducer accounts, erased accounts and test accounts (an explicit
-- flag in analytics.excluded_accounts, or a username/e-mail matching the
-- patterns in analytics.report_settings) are excluded everywhere.
--
-- Member-level tables (active days, surface days, milestones) keep raw rows for
-- every non-erased member and apply the exclusions when read, so flagging a
-- test account fixes those reports immediately. daily_metrics applies the
-- exclusions when a day is built; rebuild the affected days after flagging.
--
-- The job (BFF analyticsSnapshotWorker) builds each completed UTC day after
-- midnight, rebuilds it once more after the following midnight to pick up late
-- rows, and then treats it as final. Operators can rebuild a range on demand.
-- Every function here is idempotent: rebuilding a day replaces that day.
--
-- Small counts are suppressed (1–4 → "<5") by the API, not here.
-- Safe to run repeatedly.
-- ─────────────────────────────────────────────────────────────────────────────

BEGIN;

CREATE SCHEMA IF NOT EXISTS analytics;

-- Day-range scans on the busiest append-only sources. BRIN indexes are tiny and
-- cheap to maintain on insert-ordered tables. Created first, before this
-- migration locks any analytics table, so a live writer that touches both
-- cannot deadlock with it.
CREATE INDEX IF NOT EXISTS brin_messages_created_at ON matching.messages USING brin (created_at);
CREATE INDEX IF NOT EXISTS brin_swipes_created_at ON matching.swipes USING brin (created_at);
CREATE INDEX IF NOT EXISTS brin_social_messages_created_at ON matching.social_messages USING brin (created_at);
CREATE INDEX IF NOT EXISTS brin_xp_ledger_occurred_at ON progression.xp_ledger USING brin (occurred_at);

-- ── Settings and exclusions ─────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS analytics.report_settings (
  key         TEXT PRIMARY KEY,
  value       TEXT NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_by  TEXT NOT NULL DEFAULT 'migration_123'
);

INSERT INTO analytics.report_settings(key, value, description) VALUES
  ('test_username_pattern', '^(appium|e2e|smoke|loadtest|test|qa)[._0-9]|qa[._]',
   'Case-insensitive POSIX regex. Usernames that match are test accounts and are excluded from every analytics report. Empty disables the rule.'),
  ('test_email_pattern', '@(example\.(com|net|org|test)|[^@]*\.(test|invalid|example|localhost))$',
   'Case-insensitive POSIX regex on e-mail. The default matches the domains reserved for testing by RFC 2606/6761, which no real member can own. Empty disables the rule.')
ON CONFLICT (key) DO NOTHING;

CREATE TABLE IF NOT EXISTS analytics.excluded_accounts (
  user_id    UUID PRIMARY KEY REFERENCES user_management.users(id) ON DELETE CASCADE,
  reason     TEXT NOT NULL CHECK (char_length(reason) BETWEEN 3 AND 200),
  created_by TEXT NOT NULL DEFAULT 'operator',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- One row per excluded account with the first rule that excluded it.
CREATE OR REPLACE VIEW analytics.member_exclusions AS
WITH settings AS (
  SELECT
    COALESCE((SELECT value FROM analytics.report_settings WHERE key = 'test_username_pattern'), '') AS user_pattern,
    COALESCE((SELECT value FROM analytics.report_settings WHERE key = 'test_email_pattern'), '')    AS email_pattern
), classified AS (
  SELECT u.id AS user_id,
    CASE
      WHEN u.erased_at IS NOT NULL THEN 'erased_account'
      WHEN COALESCE(u.account_kind, 'dating') <> 'dating' THEN 'introducer_account'
      WHEN EXISTS (SELECT 1 FROM user_management.auth_account_roles r
                   WHERE r.user_id = u.id AND r.role <> 'user') THEN 'operator_account'
      WHEN EXISTS (SELECT 1 FROM analytics.excluded_accounts x WHERE x.user_id = u.id) THEN 'flagged_test_account'
      WHEN s.user_pattern <> '' AND u.username ~* s.user_pattern THEN 'test_username'
      WHEN s.email_pattern <> '' AND COALESCE(u.email, '') ~* s.email_pattern THEN 'test_email_domain'
    END AS reason
  FROM user_management.users u CROSS JOIN settings s
)
SELECT user_id, reason FROM classified WHERE reason IS NOT NULL;

-- The population every report counts, with the stable segment attributes.
-- gender/city are the member's current values; bands that depend on a date are
-- computed by the functions below for the day being reported.
CREATE OR REPLACE VIEW analytics.reportable_members AS
SELECT u.id AS user_id,
       u.created_at,
       CASE WHEN u.gender IN ('female', 'male', 'other') THEN u.gender ELSE 'unknown' END AS gender,
       COALESCE(NULLIF(initcap(lower(btrim(u.city))), ''), 'unknown') AS city,
       u.date_of_birth
FROM user_management.users u
WHERE NOT EXISTS (SELECT 1 FROM analytics.member_exclusions e WHERE e.user_id = u.id);

CREATE OR REPLACE FUNCTION analytics.normalize_city(p_city TEXT)
RETURNS TEXT LANGUAGE sql IMMUTABLE AS $$
  SELECT COALESCE(NULLIF(initcap(lower(btrim(p_city))), ''), 'unknown')
$$;

CREATE OR REPLACE FUNCTION analytics.age_band(p_dob DATE, p_on DATE)
RETURNS TEXT LANGUAGE sql IMMUTABLE AS $$
  SELECT CASE
    WHEN p_dob IS NULL OR p_on IS NULL THEN 'unknown'
    WHEN a < 18 THEN 'unknown'
    WHEN a <= 24 THEN '18-24'
    WHEN a <= 29 THEN '25-29'
    WHEN a <= 34 THEN '30-34'
    WHEN a <= 44 THEN '35-44'
    ELSE '45+'
  END
  FROM (SELECT date_part('year', age(p_on::timestamp, p_dob::timestamp))::int AS a) x
$$;

CREATE OR REPLACE FUNCTION analytics.account_age_band(p_created DATE, p_on DATE)
RETURNS TEXT LANGUAGE sql IMMUTABLE AS $$
  SELECT CASE
    WHEN p_created IS NULL OR p_on IS NULL OR p_on < p_created THEN 'unknown'
    WHEN p_on - p_created = 0 THEN 'day_0'
    WHEN p_on - p_created <= 6 THEN 'days_1_6'
    WHEN p_on - p_created <= 29 THEN 'days_7_29'
    WHEN p_on - p_created <= 89 THEN 'days_30_89'
    ELSE 'days_90_plus'
  END
$$;

-- Bands from documents/07_USER_ENGAGEMENT_ACTIVITY_BLUEPRINT.md.
CREATE OR REPLACE FUNCTION analytics.level_band(p_level INTEGER)
RETURNS TEXT LANGUAGE sql IMMUTABLE AS $$
  SELECT CASE
    WHEN p_level IS NULL OR p_level <= 3 THEN 'L1-L3'
    WHEN p_level <= 7 THEN 'L4-L7'
    ELSE 'L8-L10'
  END
$$;

-- ── Snapshot tables ─────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS analytics.member_active_days (
  day         DATE NOT NULL,
  user_id     UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  source      TEXT NOT NULL CHECK (source IN ('session', 'action')),
  recorded_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (day, user_id)
);
CREATE INDEX IF NOT EXISTS idx_member_active_days_user ON analytics.member_active_days(user_id, day);

CREATE TABLE IF NOT EXISTS analytics.member_surface_days (
  day     DATE NOT NULL,
  user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  surface TEXT NOT NULL CHECK (surface IN (
            'onboarding', 'discovery', 'chat', 'date_plans', 'chapters', 'blog', 'themes',
            'clubs', 'rooms', 'groups', 'friends', 'gifts', 'rewards', 'safety')),
  actions INTEGER NOT NULL CHECK (actions > 0),
  PRIMARY KEY (day, surface, user_id)
);
CREATE INDEX IF NOT EXISTS idx_member_surface_days_user ON analytics.member_surface_days(user_id, day);

CREATE TABLE IF NOT EXISTS analytics.daily_metrics (
  day              DATE NOT NULL,
  metric           TEXT NOT NULL,
  gender           TEXT NOT NULL,
  city             TEXT NOT NULL,
  age_band         TEXT NOT NULL,
  account_age_band TEXT NOT NULL,
  level_band       TEXT NOT NULL,
  value            BIGINT NOT NULL,
  PRIMARY KEY (day, metric, gender, city, age_band, account_age_band, level_band)
);
CREATE INDEX IF NOT EXISTS idx_daily_metrics_metric_day ON analytics.daily_metrics(metric, day);

CREATE TABLE IF NOT EXISTS analytics.member_milestones (
  user_id             UUID PRIMARY KEY REFERENCES user_management.users(id) ON DELETE CASCADE,
  signup_at           TIMESTAMPTZ NOT NULL,
  terms_at            TIMESTAMPTZ,
  profile_complete_at TIMESTAMPTZ,
  verified_at         TIMESTAMPTZ,
  first_like_at       TIMESTAMPTZ,
  first_match_at      TIMESTAMPTZ,
  first_message_at    TIMESTAMPTZ,
  two_way_at          TIMESTAMPTZ,
  plan_accepted_at    TIMESTAMPTZ,
  date_kept_at        TIMESTAMPTZ,
  refreshed_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_member_milestones_signup ON analytics.member_milestones(signup_at);

-- Which days have had their activity derived and their rollups built.
CREATE TABLE IF NOT EXISTS analytics.snapshot_days (
  day            DATE PRIMARY KEY,
  derived_at     TIMESTAMPTZ,
  built_at       TIMESTAMPTZ,
  final          BOOLEAN NOT NULL DEFAULT FALSE,
  metric_rows    INTEGER NOT NULL DEFAULT 0,
  active_members INTEGER NOT NULL DEFAULT 0,
  surface_rows   INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS analytics.snapshot_runs (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  kind         TEXT NOT NULL CHECK (kind IN ('scheduled', 'rebuild')),
  from_day     DATE NOT NULL,
  to_day       DATE NOT NULL,
  status       TEXT NOT NULL DEFAULT 'running' CHECK (status IN ('running', 'succeeded', 'failed')),
  requested_by TEXT NOT NULL DEFAULT 'scheduler',
  days_built   INTEGER NOT NULL DEFAULT 0,
  error        TEXT,
  started_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  finished_at  TIMESTAMPTZ,
  CHECK (to_day >= from_day)
);
CREATE INDEX IF NOT EXISTS idx_snapshot_runs_recent ON analytics.snapshot_runs(started_at DESC);

-- ── Live capture of session activity ────────────────────────────────────────
-- Every authenticated request touches auth_sessions.last_used_at; migration
-- 087's trigger folds that into member_last_activity at most every five
-- minutes. The throttle now also lets the first request of a new UTC day
-- through, so a member active just after midnight is never lost, and every
-- write to member_last_activity records that UTC day here.

CREATE OR REPLACE FUNCTION platform.record_member_activity()
RETURNS trigger
LANGUAGE plpgsql
AS $function$
DECLARE
  seen_at TIMESTAMPTZ := COALESCE(NEW.last_used_at, NEW.created_at, NOW());
BEGIN
  IF NEW.revoked_at IS NOT NULL THEN
    RETURN NEW;
  END IF;
  -- Activity tracking must never break authentication: unknown members are
  -- skipped and any failure here is swallowed.
  BEGIN
    INSERT INTO platform.member_last_activity(user_id, first_active_at, last_active_at)
    SELECT NEW.user_id, seen_at, seen_at
    WHERE EXISTS (SELECT 1 FROM user_management.users u WHERE u.id = NEW.user_id)
    ON CONFLICT (user_id) DO UPDATE
      SET last_active_at = EXCLUDED.last_active_at
      WHERE platform.member_last_activity.last_active_at < EXCLUDED.last_active_at - INTERVAL '5 minutes'
         OR (platform.member_last_activity.last_active_at AT TIME ZONE 'UTC')::date
            < (EXCLUDED.last_active_at AT TIME ZONE 'UTC')::date;
  EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'member activity not recorded: %', SQLERRM;
  END;
  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION analytics.record_active_day()
RETURNS trigger
LANGUAGE plpgsql
AS $function$
BEGIN
  BEGIN
    INSERT INTO analytics.member_active_days(day, user_id, source)
    VALUES ((NEW.last_active_at AT TIME ZONE 'UTC')::date, NEW.user_id, 'session')
    ON CONFLICT (day, user_id) DO NOTHING;
  EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'analytics active day not recorded: %', SQLERRM;
  END;
  RETURN NEW;
END;
$function$;

DROP TRIGGER IF EXISTS trg_member_last_activity_active_day ON platform.member_last_activity;
CREATE TRIGGER trg_member_last_activity_active_day
  AFTER INSERT OR UPDATE OF last_active_at ON platform.member_last_activity
  FOR EACH ROW EXECUTE FUNCTION analytics.record_active_day();

-- ── Day events ──────────────────────────────────────────────────────────────
-- Collects every countable event of one UTC day into a transaction-local temp
-- table: (user_id, metric, surface, is_action, n). `user_id` is the member the
-- event is attributed to (the actor where there is one). `is_action` marks
-- something the member did in the product, which makes the day an active day
-- and counts toward the surface; passive outcomes (a match being created,
-- verification approved, XP granted) do not.

CREATE OR REPLACE FUNCTION analytics.collect_day_events(p_day DATE)
RETURNS INTEGER
LANGUAGE plpgsql
AS $function$
DECLARE
  d0 TIMESTAMPTZ := (p_day::timestamp AT TIME ZONE 'UTC');
  d1 TIMESTAMPTZ := ((p_day + 1)::timestamp AT TIME ZONE 'UTC');
  n  INTEGER;
BEGIN
  DROP TABLE IF EXISTS pg_temp.analytics_day_events;
  CREATE TEMP TABLE analytics_day_events (
    user_id   UUID NOT NULL,
    metric    TEXT NOT NULL,
    surface   TEXT,
    is_action BOOLEAN NOT NULL,
    n         BIGINT NOT NULL
  ) ON COMMIT DROP;

  INSERT INTO analytics_day_events(user_id, metric, surface, is_action, n)
  -- Onboarding
  SELECT u.id, 'signups', 'onboarding', TRUE, 1
    FROM user_management.users u WHERE u.created_at >= d0 AND u.created_at < d1
  UNION ALL
  SELECT c.user_id, 'profile_completions', 'onboarding', TRUE, 1
    FROM user_management.profile_setup_completions c
   WHERE c.completed_at >= d0 AND c.completed_at < d1
     AND NOT EXISTS (SELECT 1 FROM user_management.profile_setup_completions e
                      WHERE e.user_id = c.user_id
                        AND (e.completed_at, e.id) < (c.completed_at, c.id))
  UNION ALL
  SELECT v.user_id, 'verifications', NULL, FALSE, 1
    FROM matching.verification_states v
   WHERE v.status = 'verified' AND v.reviewed_at >= d0 AND v.reviewed_at < d1
  UNION ALL
  SELECT s.user_id, 'sessions_started', NULL, FALSE, COUNT(*)
    FROM user_management.auth_sessions s
   WHERE s.created_at >= d0 AND s.created_at < d1
   GROUP BY s.user_id
  -- Discovery
  UNION ALL
  SELECT s.user_id, CASE WHEN s.is_like THEN 'likes' ELSE 'passes' END, 'discovery', TRUE, COUNT(*)
    FROM matching.swipes s WHERE s.created_at >= d0 AND s.created_at < d1
   GROUP BY s.user_id, s.is_like
  UNION ALL
  SELECT x.uid, 'matches', NULL, FALSE, 1
    FROM matching.matches m CROSS JOIN LATERAL (VALUES (m.user_id_1), (m.user_id_2)) x(uid)
   WHERE m.created_at >= d0 AND m.created_at < d1
  -- Match chat (gift system messages are counted as gifts, not messages)
  UNION ALL
  SELECT m.sender_id, 'messages_sent', 'chat', TRUE, COUNT(*)
    FROM matching.messages m
   WHERE m.created_at >= d0 AND m.created_at < d1 AND m.gift_send_id IS NULL
   GROUP BY m.sender_id
  UNION ALL
  SELECT m.sender_id, 'first_messages', 'chat', FALSE, 1
    FROM matching.messages m
   WHERE m.created_at >= d0 AND m.created_at < d1 AND m.gift_send_id IS NULL
     AND NOT EXISTS (SELECT 1 FROM matching.messages e
                      WHERE e.match_id = m.match_id AND e.gift_send_id IS NULL
                        AND (e.created_at, e.id) < (m.created_at, m.id))
  UNION ALL
  SELECT m.sender_id, 'conversations_replied', 'chat', FALSE, 1
    FROM matching.messages m
   WHERE m.created_at >= d0 AND m.created_at < d1 AND m.gift_send_id IS NULL
     AND NOT EXISTS (SELECT 1 FROM matching.messages e
                      WHERE e.match_id = m.match_id AND e.sender_id = m.sender_id AND e.gift_send_id IS NULL
                        AND (e.created_at, e.id) < (m.created_at, m.id))
     AND EXISTS (SELECT 1 FROM matching.messages o
                  WHERE o.match_id = m.match_id AND o.sender_id <> m.sender_id AND o.gift_send_id IS NULL
                    AND (o.created_at, o.id) < (m.created_at, m.id))
  -- Date plans
  UNION ALL
  SELECT p.proposer_user_id, 'date_plans_proposed', 'date_plans', TRUE, 1
    FROM matching.match_date_plans p WHERE p.created_at >= d0 AND p.created_at < d1
  UNION ALL
  SELECT COALESCE(e.actor_user_id, p.invitee_user_id), 'date_plans_accepted', 'date_plans', TRUE, 1
    FROM matching.match_date_plan_events e JOIN matching.match_date_plans p ON p.id = e.plan_id
   WHERE e.to_status = 'accepted' AND e.created_at >= d0 AND e.created_at < d1
     AND NOT EXISTS (SELECT 1 FROM matching.match_date_plan_events o
                      WHERE o.plan_id = e.plan_id AND o.to_status = 'accepted'
                        AND (o.created_at, o.id) < (e.created_at, e.id))
  UNION ALL
  SELECT b.user_id, 'debriefs_submitted', 'date_plans', TRUE, 1
    FROM matching.match_date_plan_debriefs b WHERE b.created_at >= d0 AND b.created_at < d1
  UNION ALL
  SELECT b.user_id, 'dates_kept', NULL, FALSE, 1
    FROM matching.match_date_plan_debriefs b
   WHERE b.happened IS TRUE AND b.created_at >= d0 AND b.created_at < d1
     AND NOT EXISTS (SELECT 1 FROM matching.match_date_plan_debriefs o
                      WHERE o.plan_id = b.plan_id AND o.happened IS TRUE
                        AND (o.created_at, o.user_id) < (b.created_at, b.user_id))
     AND NOT EXISTS (SELECT 1 FROM matching.match_date_plan_debriefs n
                      WHERE n.plan_id = b.plan_id AND n.happened IS FALSE)
  UNION ALL
  SELECT g.proposer_user_id, 'graduations', NULL, FALSE, 1
    FROM matching.match_graduations g
   WHERE g.status = 'confirmed' AND g.decided_at >= d0 AND g.decided_at < d1
  -- Stories and community content
  UNION ALL
  SELECT c.owner_id, 'chapters_published', 'chapters', TRUE, 1
    FROM matching.chapter_publications c
   WHERE c.created_at >= d0 AND c.created_at < d1 AND NOT c.revoked
     AND (c.partner_id IS NULL OR c.partner_approved)
  UNION ALL
  SELECT b.author_id, 'blog_posts_published', 'blog', TRUE, 1
    FROM matching.blog_posts b
   WHERE b.published_at >= d0 AND b.published_at < d1 AND b.deleted_at IS NULL
  UNION ALL
  SELECT l.user_id, 'blog_reactions', 'blog', TRUE, COUNT(*)
    FROM matching.blog_likes l WHERE l.created_at >= d0 AND l.created_at < d1 GROUP BY l.user_id
  UNION ALL
  SELECT c.author_id, 'blog_comments', 'blog', TRUE, COUNT(*)
    FROM matching.blog_comments c WHERE c.created_at >= d0 AND c.created_at < d1 GROUP BY c.author_id
  UNION ALL
  SELECT t.author_id, 'photos_shared', 'themes', TRUE, COUNT(*)
    FROM matching.photo_theme_entries t
   WHERE t.created_at >= d0 AND t.created_at < d1 AND t.moderation_status IS DISTINCT FROM 'rejected'
   GROUP BY t.author_id
  UNION ALL
  SELECT l.user_id, 'photo_reactions', 'themes', TRUE, COUNT(*)
    FROM matching.photo_entry_likes l WHERE l.created_at >= d0 AND l.created_at < d1 GROUP BY l.user_id
  UNION ALL
  SELECT p.author_id, 'club_posts', 'clubs', TRUE, COUNT(*)
    FROM matching.club_posts p WHERE p.created_at >= d0 AND p.created_at < d1 GROUP BY p.author_id
  UNION ALL
  SELECT m.user_id, 'club_joins', 'clubs', TRUE, COUNT(*)
    FROM matching.club_members m
   WHERE m.joined_at >= d0 AND m.joined_at < d1 AND m.role <> 'owner' GROUP BY m.user_id
  -- Conversation rooms, groups and friends (shared chat engine, migration 115)
  UNION ALL
  SELECT sm.sender_id,
         CASE c.kind WHEN 'room' THEN 'room_messages' WHEN 'group' THEN 'group_messages' ELSE 'friend_messages' END,
         CASE c.kind WHEN 'room' THEN 'rooms' WHEN 'group' THEN 'groups' ELSE 'friends' END,
         TRUE, COUNT(*)
    FROM matching.social_messages sm JOIN matching.social_channels c ON c.id = sm.channel_id
   WHERE sm.created_at >= d0 AND sm.created_at < d1
   GROUP BY sm.sender_id, c.kind
  UNION ALL
  SELECT p.user_id, 'room_joins', 'rooms', TRUE, COUNT(*)
    FROM matching.conversation_room_participants p
   WHERE p.joined_at >= d0 AND p.joined_at < d1 GROUP BY p.user_id
  UNION ALL
  SELECT g.created_by_user_id, 'groups_created', 'groups', TRUE, COUNT(*)
    FROM matching.community_groups g
   WHERE g.created_at >= d0 AND g.created_at < d1 AND g.created_by_user_id IS NOT NULL
   GROUP BY g.created_by_user_id
  UNION ALL
  SELECT m.user_id, 'group_joins', 'groups', TRUE, COUNT(*)
    FROM matching.community_group_members m
   WHERE m.joined_at >= d0 AND m.joined_at < d1 AND m.role <> 'owner' GROUP BY m.user_id
  UNION ALL
  SELECT f.requester_id, 'friend_requests_sent', 'friends', TRUE, COUNT(*)
    FROM matching.friend_request_sends f WHERE f.created_at >= d0 AND f.created_at < d1 GROUP BY f.requester_id
  UNION ALL
  -- An accepted friendship is two accepted rows; the later-created row belongs
  -- to the member who accepted.
  SELECT f.user_id, 'friend_requests_accepted', 'friends', TRUE, COUNT(*)
    FROM matching.friend_connections f
    JOIN matching.friend_connections r ON r.user_id = f.friend_user_id AND r.friend_user_id = f.user_id
   WHERE f.status = 'accepted' AND r.status = 'accepted'
     AND f.created_at >= d0 AND f.created_at < d1
     AND (f.created_at, f.id) > (r.created_at, r.id)
   GROUP BY f.user_id
  -- Gifts, rewards
  UNION ALL
  SELECT g.sender_user_id, 'gifts_sent', 'gifts', TRUE, COUNT(*)
    FROM matching.match_gift_sends g
   WHERE g.created_at >= d0 AND g.created_at < d1 AND NOT COALESCE(g.is_system, FALSE) AND g.status <> 'cancelled'
   GROUP BY g.sender_user_id
  UNION ALL
  SELECT x.user_id, 'xp_awarded', NULL, FALSE, SUM(x.awarded_xp)
    FROM progression.xp_ledger x
   WHERE x.occurred_at >= d0 AND x.occurred_at < d1 AND x.awarded_xp > 0
   GROUP BY x.user_id
  UNION ALL
  SELECT c.user_id, 'rewards_claimed', 'rewards', TRUE, COUNT(*)
    FROM progression.reward_claims c WHERE c.claimed_at >= d0 AND c.claimed_at < d1 GROUP BY c.user_id
  -- Safety
  UNION ALL
  SELECT r.reporter_user_id, 'reports_filed', 'safety', TRUE, COUNT(*)
    FROM matching.moderation_reports r WHERE r.created_at >= d0 AND r.created_at < d1 GROUP BY r.reporter_user_id
  UNION ALL
  SELECT c.reporter_id, 'reports_filed', 'safety', TRUE, COUNT(*)
    FROM matching.blog_cases c
   WHERE c.created_at >= d0 AND c.created_at < d1 AND c.reporter_id IS NOT NULL GROUP BY c.reporter_id
  UNION ALL
  SELECT b.user_id, 'blocks', 'safety', TRUE, COUNT(*)
    FROM user_management.blocked_users b WHERE b.created_at >= d0 AND b.created_at < d1 GROUP BY b.user_id;

  DELETE FROM analytics_day_events e WHERE e.user_id IS NULL OR e.n <= 0;
  SELECT COUNT(*) INTO n FROM analytics_day_events;
  RETURN n;
END;
$function$;

-- Adds the members active on a day: anyone who did something (is_action), who
-- signed in or used a session, or whose recorded last/first activity falls on
-- that day. Insert-only, so live session capture is never overwritten.
-- p_collected: the caller already ran collect_day_events(p_day) in this
-- transaction (rebuild_day does); otherwise the events are collected here.
CREATE OR REPLACE FUNCTION analytics.derive_active_days(p_day DATE, p_collected BOOLEAN DEFAULT FALSE)
RETURNS INTEGER
LANGUAGE plpgsql
AS $function$
DECLARE
  d0 TIMESTAMPTZ := (p_day::timestamp AT TIME ZONE 'UTC');
  d1 TIMESTAMPTZ := ((p_day + 1)::timestamp AT TIME ZONE 'UTC');
  added INTEGER;
BEGIN
  IF NOT p_collected THEN
    PERFORM analytics.collect_day_events(p_day);
  END IF;
  INSERT INTO analytics.member_active_days(day, user_id, source)
  SELECT p_day, x.user_id, MIN(x.source)
  FROM (
    SELECT e.user_id, 'action' AS source FROM analytics_day_events e WHERE e.is_action
    UNION ALL
    SELECT s.user_id, 'session' FROM user_management.auth_sessions s
     WHERE (s.created_at >= d0 AND s.created_at < d1) OR (s.last_used_at >= d0 AND s.last_used_at < d1)
    UNION ALL
    SELECT a.user_id, 'session' FROM platform.member_last_activity a
     WHERE (a.first_active_at >= d0 AND a.first_active_at < d1) OR (a.last_active_at >= d0 AND a.last_active_at < d1)
  ) x
  JOIN user_management.users u ON u.id = x.user_id AND u.erased_at IS NULL
  GROUP BY x.user_id
  ON CONFLICT (day, user_id) DO NOTHING;
  GET DIAGNOSTICS added = ROW_COUNT;

  INSERT INTO analytics.snapshot_days(day, derived_at) VALUES (p_day, NOW())
  ON CONFLICT (day) DO UPDATE SET derived_at = EXCLUDED.derived_at;
  RETURN added;
END;
$function$;

-- Rebuilds one completed UTC day: derives its active members, replaces its
-- surface rows and its rollups. WAU/MAU read the 7/30 days ending on the day,
-- so derive those days first when backfilling (the worker does).
CREATE OR REPLACE FUNCTION analytics.rebuild_day(p_day DATE, p_final BOOLEAN DEFAULT FALSE)
RETURNS TABLE(metric_rows INTEGER, active_members INTEGER, surface_rows INTEGER)
LANGUAGE plpgsql
AS $function$
#variable_conflict use_column
DECLARE
  d1 TIMESTAMPTZ := ((p_day + 1)::timestamp AT TIME ZONE 'UTC');
  v_metric_rows INTEGER;
  v_active INTEGER;
  v_surface INTEGER;
BEGIN
  IF p_day IS NULL OR p_day >= (NOW() AT TIME ZONE 'UTC')::date THEN
    RAISE EXCEPTION 'analytics day % is not complete yet', p_day USING ERRCODE = '22023';
  END IF;

  PERFORM analytics.collect_day_events(p_day);
  PERFORM analytics.derive_active_days(p_day, TRUE);

  DELETE FROM analytics.member_surface_days WHERE day = p_day;
  INSERT INTO analytics.member_surface_days(day, user_id, surface, actions)
  SELECT p_day, e.user_id, e.surface, LEAST(SUM(e.n), 2147483647)::int
    FROM analytics_day_events e
    JOIN user_management.users u ON u.id = e.user_id AND u.erased_at IS NULL
   WHERE e.is_action AND e.surface IS NOT NULL
   GROUP BY e.user_id, e.surface;
  GET DIAGNOSTICS v_surface = ROW_COUNT;

  -- Good-day inputs (ENTERTAINMENT_RETENTION_STRATEGY section 7): an active day
  -- with no new match, and such a day that included an entertainment action.
  INSERT INTO analytics_day_events(user_id, metric, surface, is_action, n)
  SELECT a.user_id, 'active_days_without_match', NULL::text, FALSE, 1::bigint
    FROM analytics.member_active_days a
   WHERE a.day = p_day
     AND NOT EXISTS (SELECT 1 FROM analytics_day_events e WHERE e.user_id = a.user_id AND e.metric = 'matches');
  INSERT INTO analytics_day_events(user_id, metric, surface, is_action, n)
  SELECT DISTINCT e.user_id, 'good_days', NULL::text, FALSE, 1::bigint
    FROM analytics_day_events e
   WHERE e.is_action
     AND e.surface IN ('chapters', 'blog', 'themes', 'clubs', 'rooms', 'groups', 'friends', 'rewards')
     AND NOT EXISTS (SELECT 1 FROM analytics_day_events m WHERE m.user_id = e.user_id AND m.metric = 'matches');

  DROP TABLE IF EXISTS pg_temp.analytics_day_segments;
  CREATE TEMP TABLE analytics_day_segments ON COMMIT DROP AS
  SELECT m.user_id, m.gender, m.city,
         analytics.age_band(m.date_of_birth, p_day) AS age_band,
         analytics.account_age_band((m.created_at AT TIME ZONE 'UTC')::date, p_day) AS account_age_band,
         analytics.level_band(COALESCE((
           SELECT t.to_level FROM progression.level_transitions t
            WHERE t.user_id = m.user_id AND t.created_at < d1
            ORDER BY t.created_at DESC LIMIT 1), 1)) AS level_band
    FROM analytics.reportable_members m
   WHERE m.user_id IN (
           SELECT e.user_id FROM analytics_day_events e
           UNION
           SELECT a.user_id FROM analytics.member_active_days a WHERE a.day BETWEEN p_day - 29 AND p_day);

  DELETE FROM analytics.daily_metrics WHERE day = p_day;
  INSERT INTO analytics.daily_metrics(day, metric, gender, city, age_band, account_age_band, level_band, value)
  SELECT p_day, e.metric, s.gender, s.city, s.age_band, s.account_age_band, s.level_band, SUM(e.n)
    FROM analytics_day_events e JOIN analytics_day_segments s ON s.user_id = e.user_id
   GROUP BY e.metric, s.gender, s.city, s.age_band, s.account_age_band, s.level_band
  UNION ALL
  SELECT p_day, w.metric, s.gender, s.city, s.age_band, s.account_age_band, s.level_band, COUNT(DISTINCT a.user_id)
    FROM (VALUES ('dau', 0), ('wau', 6), ('mau', 29)) w(metric, span)
    JOIN analytics.member_active_days a ON a.day BETWEEN p_day - w.span AND p_day
    JOIN analytics_day_segments s ON s.user_id = a.user_id
   GROUP BY w.metric, s.gender, s.city, s.age_band, s.account_age_band, s.level_band;
  GET DIAGNOSTICS v_metric_rows = ROW_COUNT;

  SELECT COUNT(*) INTO v_active
    FROM analytics.member_active_days a JOIN analytics_day_segments s ON s.user_id = a.user_id
   WHERE a.day = p_day;

  INSERT INTO analytics.snapshot_days(day, derived_at, built_at, final, metric_rows, active_members, surface_rows)
  VALUES (p_day, NOW(), NOW(), p_final, v_metric_rows, v_active, v_surface)
  ON CONFLICT (day) DO UPDATE SET
    derived_at = EXCLUDED.derived_at, built_at = EXCLUDED.built_at, final = EXCLUDED.final,
    metric_rows = EXCLUDED.metric_rows, active_members = EXCLUDED.active_members,
    surface_rows = EXCLUDED.surface_rows;

  RETURN QUERY SELECT v_metric_rows, v_active, v_surface;
END;
$function$;

-- Recomputes every member's activation milestones from the domain tables.
CREATE OR REPLACE FUNCTION analytics.refresh_member_milestones()
RETURNS INTEGER
LANGUAGE plpgsql
AS $function$
DECLARE
  n INTEGER;
BEGIN
  WITH first_like AS (
    SELECT user_id, MIN(created_at) AS at FROM matching.swipes WHERE is_like GROUP BY user_id
  ), first_match AS (
    SELECT x.uid AS user_id, MIN(m.created_at) AS at
      FROM matching.matches m CROSS JOIN LATERAL (VALUES (m.user_id_1), (m.user_id_2)) x(uid)
     GROUP BY x.uid
  ), first_message AS (
    SELECT sender_id AS user_id, MIN(created_at) AS at
      FROM matching.messages WHERE gift_send_id IS NULL GROUP BY sender_id
  ), third_message AS (
    -- Two-way conversation: both members have sent at least three messages
    -- (the City Pilot proxy, without its 7-day window).
    SELECT match_id, sender_id, created_at AS at
      FROM (SELECT match_id, sender_id, created_at,
                   ROW_NUMBER() OVER (PARTITION BY match_id, sender_id ORDER BY created_at, id) AS rn
              FROM matching.messages WHERE gift_send_id IS NULL) r
     WHERE rn = 3
  ), two_way AS (
    SELECT x.uid AS user_id, MIN(GREATEST(a.at, b.at)) AS at
      FROM matching.matches m
      JOIN third_message a ON a.match_id = m.id AND a.sender_id = m.user_id_1
      JOIN third_message b ON b.match_id = m.id AND b.sender_id = m.user_id_2
      CROSS JOIN LATERAL (VALUES (m.user_id_1), (m.user_id_2)) x(uid)
     GROUP BY x.uid
  ), plan_accepted AS (
    SELECT x.uid AS user_id, MIN(e.created_at) AS at
      FROM matching.match_date_plans p
      JOIN matching.match_date_plan_events e ON e.plan_id = p.id AND e.to_status = 'accepted'
      CROSS JOIN LATERAL (VALUES (p.proposer_user_id), (p.invitee_user_id)) x(uid)
     GROUP BY x.uid
  ), date_kept AS (
    SELECT x.uid AS user_id, MIN(b.created_at) AS at
      FROM matching.match_date_plans p
      JOIN matching.match_date_plan_debriefs b ON b.plan_id = p.id AND b.happened IS TRUE
      CROSS JOIN LATERAL (VALUES (p.proposer_user_id), (p.invitee_user_id)) x(uid)
     WHERE NOT EXISTS (SELECT 1 FROM matching.match_date_plan_debriefs n
                        WHERE n.plan_id = p.id AND n.happened IS FALSE)
     GROUP BY x.uid
  ), profile AS (
    SELECT user_id, MIN(completed_at) AS at FROM user_management.profile_setup_completions GROUP BY user_id
  )
  INSERT INTO analytics.member_milestones(
    user_id, signup_at, terms_at, profile_complete_at, verified_at, first_like_at, first_match_at,
    first_message_at, two_way_at, plan_accepted_at, date_kept_at, refreshed_at)
  SELECT u.id, u.created_at,
         LEAST(w.terms_accepted_at, CASE WHEN u.terms_accepted THEN u.terms_accepted_at END),
         pc.at,
         (SELECT v.reviewed_at FROM matching.verification_states v WHERE v.user_id = u.id AND v.status = 'verified'),
         fl.at, fm.at, fmsg.at, tw.at, pa.at, dk.at, NOW()
    FROM user_management.users u
    LEFT JOIN user_management.signup_workflows w ON w.user_id = u.id
    LEFT JOIN profile pc ON pc.user_id = u.id
    LEFT JOIN first_like fl ON fl.user_id = u.id
    LEFT JOIN first_match fm ON fm.user_id = u.id
    LEFT JOIN first_message fmsg ON fmsg.user_id = u.id
    LEFT JOIN two_way tw ON tw.user_id = u.id
    LEFT JOIN plan_accepted pa ON pa.user_id = u.id
    LEFT JOIN date_kept dk ON dk.user_id = u.id
   WHERE u.erased_at IS NULL AND u.created_at IS NOT NULL
  ON CONFLICT (user_id) DO UPDATE SET
    signup_at = EXCLUDED.signup_at, terms_at = EXCLUDED.terms_at,
    profile_complete_at = EXCLUDED.profile_complete_at, verified_at = EXCLUDED.verified_at,
    first_like_at = EXCLUDED.first_like_at, first_match_at = EXCLUDED.first_match_at,
    first_message_at = EXCLUDED.first_message_at, two_way_at = EXCLUDED.two_way_at,
    plan_accepted_at = EXCLUDED.plan_accepted_at, date_kept_at = EXCLUDED.date_kept_at,
    refreshed_at = EXCLUDED.refreshed_at;
  GET DIAGNOSTICS n = ROW_COUNT;

  DELETE FROM analytics.member_milestones mm
   WHERE NOT EXISTS (SELECT 1 FROM user_management.users u WHERE u.id = mm.user_id AND u.erased_at IS NULL);
  RETURN n;
END;
$function$;

-- Seed today's live capture from what migration 087 already recorded.
INSERT INTO analytics.member_active_days(day, user_id, source)
SELECT (a.last_active_at AT TIME ZONE 'UTC')::date, a.user_id, 'session'
  FROM platform.member_last_activity a
  JOIN user_management.users u ON u.id = a.user_id AND u.erased_at IS NULL
ON CONFLICT (day, user_id) DO NOTHING;

INSERT INTO public.schema_migrations(version) VALUES ('123_product_analytics_snapshots') ON CONFLICT DO NOTHING;

COMMIT;
