-- 038_voice_and_group_coffee_persistence_alignment.sql
-- Durable alignment for voice icebreakers and group coffee poll participants/options.

ALTER TABLE IF EXISTS matching.voice_icebreakers
  ADD COLUMN IF NOT EXISTS prompt_text TEXT,
  ADD COLUMN IF NOT EXISTS moderation_status TEXT NOT NULL DEFAULT 'pending',
  ADD COLUMN IF NOT EXISTS play_count INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS last_played_at TIMESTAMPTZ;

ALTER TABLE IF EXISTS matching.group_coffee_poll_options
  ADD COLUMN IF NOT EXISTS day TEXT,
  ADD COLUMN IF NOT EXISTS time_window TEXT,
  ADD COLUMN IF NOT EXISTS neighborhood TEXT;

CREATE TABLE IF NOT EXISTS matching.group_coffee_poll_participants (
  poll_id UUID NOT NULL REFERENCES matching.group_coffee_polls(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (poll_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_group_coffee_poll_participants_user
  ON matching.group_coffee_poll_participants(user_id, created_at DESC);
