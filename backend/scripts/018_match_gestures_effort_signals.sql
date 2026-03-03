CREATE TABLE IF NOT EXISTS matching.match_gestures (
  id TEXT PRIMARY KEY,
  match_id TEXT NOT NULL,
  sender_user_id TEXT NOT NULL,
  receiver_user_id TEXT NOT NULL,
  gesture_type TEXT NOT NULL CHECK (
    gesture_type IN ('thoughtful_opener', 'micro_card', 'challenge_token')
  ),
  content_text TEXT NOT NULL,
  tone TEXT NOT NULL DEFAULT 'neutral',
  status TEXT NOT NULL DEFAULT 'sent' CHECK (
    status IN ('sent', 'appreciated', 'declined', 'improve_requested')
  ),
  effort_score INTEGER NOT NULL DEFAULT 0,
  minimum_quality_pass BOOLEAN NOT NULL DEFAULT false,
  originality_pass BOOLEAN NOT NULL DEFAULT false,
  profanity_flagged BOOLEAN NOT NULL DEFAULT false,
  safety_flagged BOOLEAN NOT NULL DEFAULT false,
  decision_by_user_id TEXT,
  decision_reason TEXT,
  decision_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_match_gestures_match_id
  ON matching.match_gestures(match_id);

CREATE INDEX IF NOT EXISTS idx_match_gestures_match_created_at
  ON matching.match_gestures(match_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_match_gestures_receiver_status
  ON matching.match_gestures(receiver_user_id, status);
