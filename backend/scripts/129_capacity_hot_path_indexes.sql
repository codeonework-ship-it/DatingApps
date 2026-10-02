-- ─────────────────────────────────────────────────────────────────────────────
-- 129: Capacity hot-path indexes (1M DAU capacity review, 2026-10-02)
--
-- Measurements and production-cardinality plans:
--   documents/qa/CAPACITY_1M_DAU_2026-10-02.md
--
-- Additive only, built CONCURRENTLY (no long table locks):
--
--  * matching.messages(sender_id, created_at DESC)
--    The daily message quota (billing_entitlements.go countMessagesSince)
--    counts a sender's messages since the start of the UTC day on every chat
--    send. There was no sender index, so the count walked every message sent
--    that day through the created_at BRIN index (~20M rows/day at 1M DAU).
--
--  * matching.notification_outbox(updated_at, id) for terminal rows
--    platform.run_runtime_retention() runs every 5 minutes on every BFF
--    instance and orders terminal rows by updated_at; without an index it
--    sorts the whole outbox (90-day retention, billions of rows at scale).
--
-- Safe to run repeatedly. CREATE INDEX CONCURRENTLY cannot run inside a
-- transaction block, so this file has no BEGIN/COMMIT.
-- ─────────────────────────────────────────────────────────────────────────────

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_messages_sender_created
  ON matching.messages(sender_id, created_at DESC);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_notification_outbox_retention
  ON matching.notification_outbox(updated_at, id)
  WHERE status IN ('delivered','suppressed','dead_letter');

INSERT INTO public.schema_migrations(version)
VALUES ('129_capacity_hot_path_indexes')
ON CONFLICT (version) DO NOTHING;

-- Rollback (deliberately, in a maintenance window):
--   DROP INDEX CONCURRENTLY IF EXISTS matching.idx_messages_sender_created;
--   DROP INDEX CONCURRENTLY IF EXISTS matching.idx_notification_outbox_retention;
