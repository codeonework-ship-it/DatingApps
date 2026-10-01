BEGIN;

-- Cover the columns returned by the active match-list query so PostgreSQL can
-- avoid heap visits after visibility-map warm-up. These indexes intentionally
-- retain the predicates and ordering introduced by migration 054.
CREATE INDEX IF NOT EXISTS idx_matches_user_1_active_cover
  ON matching.matches(user_id_1, COALESCE(last_message_at, created_at) DESC)
  INCLUDE (id, user_id_2, chat_count, last_message_at, lock_version)
  WHERE user_1_status = 'active' AND user_2_status = 'active';

CREATE INDEX IF NOT EXISTS idx_matches_user_2_active_cover
  ON matching.matches(user_id_2, COALESCE(last_message_at, created_at) DESC)
  INCLUDE (id, user_id_1, chat_count, last_message_at, lock_version)
  WHERE user_1_status = 'active' AND user_2_status = 'active';

-- Chat resume and reconnect read this exact timeline, while unread state uses
-- the smaller partial index from migration 054.
CREATE INDEX IF NOT EXISTS idx_messages_match_timeline_cover
  ON matching.messages(match_id, created_at DESC, id)
  INCLUDE (sender_id, text, delivered_at, read_at)
  WHERE is_deleted = FALSE;

-- The discovery repository filters out inactive and enforced accounts before
-- applying demographic/location filters. Keep the partial index compact and
-- include only the card fields used by discovery responses.
CREATE INDEX IF NOT EXISTS idx_users_discovery_active_cover
  ON user_management.users(gender, date_of_birth, country, state, city, id)
  INCLUDE (username, name, bio, profile_completion, is_verified)
  WHERE is_active = TRUE AND is_banned = FALSE AND suspended_at IS NULL;

-- Operator queue reads are status ordered; include the fields needed to render
-- a queue row without expanding the index with free-form descriptions.
CREATE INDEX IF NOT EXISTS idx_moderation_reports_status_cover
  ON matching.moderation_reports(status, created_at DESC, id)
  INCLUDE (reporter_user_id, reported_user_id, reason, review_deadline_at);

-- SKIP LOCKED claims also filter availability and expiry. Keeping those in the
-- key prevents large pending queues from repeatedly visiting expired rows.
CREATE INDEX IF NOT EXISTS idx_notification_outbox_claim_cover
  ON matching.notification_outbox(priority DESC, available_at, expires_at, sequence_id)
  INCLUDE (id, recipient_user_id, event_type, category, attempt_count, max_attempts)
  WHERE status IN ('pending', 'retry');

COMMIT;

-- Rollback (run deliberately during a maintenance window):
-- DROP INDEX CONCURRENTLY IF EXISTS matching.idx_matches_user_1_active_cover;
-- DROP INDEX CONCURRENTLY IF EXISTS matching.idx_matches_user_2_active_cover;
-- DROP INDEX CONCURRENTLY IF EXISTS matching.idx_messages_match_timeline_cover;
-- DROP INDEX CONCURRENTLY IF EXISTS user_management.idx_users_discovery_active_cover;
-- DROP INDEX CONCURRENTLY IF EXISTS matching.idx_moderation_reports_status_cover;
-- DROP INDEX CONCURRENTLY IF EXISTS matching.idx_notification_outbox_claim_cover;
