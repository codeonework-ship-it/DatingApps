-- Engagement persistence tables for activity sessions, trust badges, and conversation rooms
-- Safe to run repeatedly on Supabase/Postgres.

CREATE TABLE IF NOT EXISTS matching.activity_sessions (
  id UUID PRIMARY KEY,
  match_id UUID NOT NULL REFERENCES matching.matches(id) ON DELETE CASCADE,
  initiator_user_id UUID NOT NULL,
  partner_user_id UUID NOT NULL,
  status TEXT NOT NULL DEFAULT 'active' CHECK (
    status IN ('active', 'completed', 'timed_out', 'partial_timeout', 'cancelled')
  ),
  started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  score_initiator INTEGER,
  score_partner INTEGER,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_activity_sessions_match
  ON matching.activity_sessions(match_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_activity_sessions_status
  ON matching.activity_sessions(status, updated_at DESC);

CREATE TABLE IF NOT EXISTS matching.activity_session_responses (
  id UUID PRIMARY KEY,
  session_id UUID NOT NULL REFERENCES matching.activity_sessions(id) ON DELETE CASCADE,
  user_id UUID NOT NULL,
  question_id TEXT NOT NULL,
  answer_value TEXT NOT NULL,
  submitted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_activity_responses_unique
  ON matching.activity_session_responses(session_id, user_id, question_id);

CREATE INDEX IF NOT EXISTS idx_activity_responses_user
  ON matching.activity_session_responses(user_id, submitted_at DESC);

CREATE TABLE IF NOT EXISTS matching.user_trust_badges (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL,
  badge_code TEXT NOT NULL,
  badge_label TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'revoked')),
  awarded_at TIMESTAMPTZ,
  revoked_at TIMESTAMPTZ,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_user_trust_badges_user_code
  ON matching.user_trust_badges(user_id, badge_code);

CREATE INDEX IF NOT EXISTS idx_user_trust_badges_status
  ON matching.user_trust_badges(status, updated_at DESC);

CREATE TABLE IF NOT EXISTS matching.user_trust_badge_history (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL,
  badge_code TEXT NOT NULL,
  action TEXT NOT NULL,
  reason TEXT,
  happened_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  actor_user_id UUID,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_user_trust_badge_history_user
  ON matching.user_trust_badge_history(user_id, happened_at DESC);

CREATE TABLE IF NOT EXISTS matching.conversation_rooms (
  id UUID PRIMARY KEY,
  theme TEXT NOT NULL,
  description TEXT NOT NULL,
  lifecycle_state TEXT NOT NULL DEFAULT 'scheduled' CHECK (
    lifecycle_state IN ('scheduled', 'active', 'closed', 'cancelled')
  ),
  starts_at TIMESTAMPTZ,
  ends_at TIMESTAMPTZ,
  capacity INTEGER NOT NULL DEFAULT 20,
  created_by_user_id UUID,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (capacity > 0)
);

CREATE INDEX IF NOT EXISTS idx_conversation_rooms_state
  ON matching.conversation_rooms(lifecycle_state, starts_at DESC);

CREATE TABLE IF NOT EXISTS matching.conversation_room_participants (
  room_id UUID NOT NULL REFERENCES matching.conversation_rooms(id) ON DELETE CASCADE,
  user_id UUID NOT NULL,
  role TEXT NOT NULL DEFAULT 'participant' CHECK (role IN ('participant', 'moderator', 'host')),
  joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  left_at TIMESTAMPTZ,
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'left', 'removed', 'muted')),
  PRIMARY KEY (room_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_room_participants_status
  ON matching.conversation_room_participants(room_id, status, joined_at DESC);

CREATE TABLE IF NOT EXISTS matching.conversation_room_moderation_actions (
  id UUID PRIMARY KEY,
  room_id UUID NOT NULL REFERENCES matching.conversation_rooms(id) ON DELETE CASCADE,
  moderator_user_id UUID NOT NULL,
  target_user_id UUID NOT NULL,
  action TEXT NOT NULL CHECK (action IN ('warn', 'mute', 'remove')),
  reason TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_room_moderation_room_created
  ON matching.conversation_room_moderation_actions(room_id, created_at DESC);
