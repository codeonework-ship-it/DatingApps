-- ─────────────────────────────────────────────────────────────────────────────
-- 087: Durable DAU / MAU source (PEN-34 / ADMIN-002)
--
-- Contract (product_screen_acceptance.v1.json, product_rules.kpis):
--   DAU = unique authenticated members with qualifying activity in the
--         trailing 24 hours; MAU = the same over the trailing 30 days.
-- Qualifying activity is an authenticated request by a member: every request
-- already touches user_management.auth_sessions.last_used_at, and a session
-- is created at sign-in. A trigger keeps one row per member with their latest
-- activity, written at most every five minutes per member, so the per-request
-- cost is a no-op most of the time. Operator accounts (any role other than
-- `user`) are excluded from the counts.
-- Safe to run repeatedly.
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS platform.member_last_activity (
  user_id         UUID PRIMARY KEY REFERENCES user_management.users(id) ON DELETE CASCADE,
  first_active_at TIMESTAMPTZ NOT NULL,
  last_active_at  TIMESTAMPTZ NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_member_last_activity_recent
  ON platform.member_last_activity(last_active_at DESC);

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
      WHERE platform.member_last_activity.last_active_at < EXCLUDED.last_active_at - INTERVAL '5 minutes';
  EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'member activity not recorded: %', SQLERRM;
  END;
  RETURN NEW;
END;
$function$;

DROP TRIGGER IF EXISTS trg_auth_sessions_member_activity ON user_management.auth_sessions;
CREATE TRIGGER trg_auth_sessions_member_activity
  AFTER INSERT OR UPDATE OF last_used_at ON user_management.auth_sessions
  FOR EACH ROW EXECUTE FUNCTION platform.record_member_activity();

-- Seed from existing sessions so the first reading is not artificially low.
INSERT INTO platform.member_last_activity(user_id, first_active_at, last_active_at)
SELECT s.user_id, MIN(s.created_at), MAX(COALESCE(s.last_used_at, s.created_at))
FROM user_management.auth_sessions s
JOIN user_management.users u ON u.id = s.user_id
GROUP BY s.user_id
ON CONFLICT (user_id) DO UPDATE
  SET last_active_at = GREATEST(platform.member_last_activity.last_active_at, EXCLUDED.last_active_at);

CREATE OR REPLACE VIEW platform.member_activity_kpis AS
SELECT
  COUNT(*) FILTER (WHERE a.last_active_at >= NOW() - INTERVAL '24 hours') AS dau,
  COUNT(*) FILTER (WHERE a.last_active_at >= NOW() - INTERVAL '30 days')  AS mau,
  NOW() AS computed_at
FROM platform.member_last_activity a
WHERE NOT EXISTS (
  SELECT 1 FROM user_management.auth_account_roles r
  WHERE r.user_id = a.user_id AND r.role <> 'user'
);
