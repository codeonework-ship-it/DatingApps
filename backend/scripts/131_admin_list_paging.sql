-- ─────────────────────────────────────────────────────────────────────────────
-- 131: Indexes for paged admin lists (2026-10-02)
--
-- The admin list endpoints now share one contract (limit, offset, q, sort,
-- order, from/to and a real total; see
-- backend/internal/bff/mobile/admin_list_query.go). Each page runs a COUNT
-- and an ORDER BY <timestamp> LIMIT/OFFSET under the same WHERE, so the
-- unfiltered and the per-actor lists need a timestamp-leading index:
--
--  * matching.activity_events(created_at DESC)
--      /admin/activities, unfiltered or with from/to.
--  * matching.activity_events(actor_user_id, created_at DESC)
--      /admin/activities?actor_user_id= and ?member= (the user_id side is
--      served by idx_activity_events_user_time from 036).
--  * matching.activity_events(event_domain, created_at DESC)
--      Already created by 036 under this name; repeated here only so an
--      environment missing it gets it. IF NOT EXISTS makes it a no-op.
--  * matching.sos_alerts(created_at DESC)
--      /admin/safety/sos-alerts without a status filter.
--  * audit.security_events(actor_user_id, occurred_at DESC) and
--    audit.security_events(occurred_at DESC)
--      /admin/audit-events (audit.operator_action_log is a view over this
--      table) by actor and by date range.
--  * matching.verification_states(submitted_at DESC)
--      /admin/verifications sorted by submission time.
--  * matching.billing_subscriptions_runtime(created_at DESC)
--      /admin/billing/subscriptions. billing_payments_runtime already has
--      idx_billing_payments_created (created_at) from 124, which a backward
--      scan uses for created_at DESC, so no payments index is added.
--
-- Additive only and safe to run repeatedly (IF NOT EXISTS).
--
-- PRODUCTION: run each statement as CREATE INDEX CONCURRENTLY IF NOT EXISTS,
-- one at a time and outside a transaction block (CONCURRENTLY cannot run in
-- one), so the hot tables (activity_events, security_events) are not locked
-- against writes while the index builds. Plain CREATE INDEX is used here for
-- the local database. This file has no BEGIN/COMMIT so it converts directly.
-- ─────────────────────────────────────────────────────────────────────────────

CREATE INDEX IF NOT EXISTS idx_activity_events_created
  ON matching.activity_events (created_at DESC);

CREATE INDEX IF NOT EXISTS idx_activity_events_actor_time
  ON matching.activity_events (actor_user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_activity_events_domain_time
  ON matching.activity_events (event_domain, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_sos_alerts_created
  ON matching.sos_alerts (created_at DESC);

CREATE INDEX IF NOT EXISTS idx_security_events_actor_time
  ON audit.security_events (actor_user_id, occurred_at DESC);

CREATE INDEX IF NOT EXISTS idx_security_events_occurred
  ON audit.security_events (occurred_at DESC);

CREATE INDEX IF NOT EXISTS idx_verification_states_submitted
  ON matching.verification_states (submitted_at DESC);

CREATE INDEX IF NOT EXISTS idx_billing_subscriptions_created
  ON matching.billing_subscriptions_runtime (created_at DESC);
