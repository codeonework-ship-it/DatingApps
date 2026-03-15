-- Activity notification persistence for Discovery notifications stack.
-- Captures "who replied me" and "who has liked me" events.
-- Safe to run repeatedly on Supabase/Postgres.

CREATE TABLE IF NOT EXISTS matching.user_activity_notifications (
  id UUID PRIMARY KEY,
  recipient_user_id UUID NOT NULL,
  actor_user_id UUID,
  notification_type TEXT NOT NULL CHECK (
    notification_type IN ('who_replied_me', 'who_liked_me')
  ),
  reference_id UUID,
  summary_text TEXT NOT NULL,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  is_read BOOLEAN NOT NULL DEFAULT FALSE,
  read_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_user_activity_notifications_recipient_created
  ON matching.user_activity_notifications(recipient_user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_user_activity_notifications_unread
  ON matching.user_activity_notifications(recipient_user_id, is_read, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_user_activity_notifications_type
  ON matching.user_activity_notifications(notification_type, created_at DESC);

CREATE OR REPLACE VIEW matching.user_activity_notifications_latest_unread AS
SELECT
  ranked.id,
  ranked.recipient_user_id,
  ranked.actor_user_id,
  ranked.notification_type,
  ranked.reference_id,
  ranked.summary_text,
  ranked.metadata,
  ranked.is_read,
  ranked.read_at,
  ranked.created_at,
  ranked.updated_at,
  ranked.unread_rank
FROM (
  SELECT
    n.*,
    ROW_NUMBER() OVER (
      PARTITION BY n.recipient_user_id
      ORDER BY n.created_at DESC
    ) AS unread_rank
  FROM matching.user_activity_notifications n
  WHERE n.is_read = FALSE
) ranked
WHERE ranked.unread_rank <= 20;
