-- Story 2.1/2.2/2.3 durable persistence bootstrap
-- Applies to Supabase Postgres (matching schema by default).

CREATE TABLE IF NOT EXISTS matching.match_unlock_states (
  match_id UUID PRIMARY KEY REFERENCES matching.matches(id) ON DELETE CASCADE,
  unlock_state TEXT NOT NULL DEFAULT 'matched' CHECK (
    unlock_state IN ('matched', 'quest_pending', 'quest_under_review', 'conversation_unlocked', 'restricted')
  ),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_match_unlock_states_updated_at
  ON matching.match_unlock_states(updated_at DESC);

CREATE TABLE IF NOT EXISTS matching.match_quest_templates (
  match_id UUID PRIMARY KEY REFERENCES matching.matches(id) ON DELETE CASCADE,
  template_id TEXT NOT NULL,
  creator_user_id UUID NOT NULL,
  prompt_template TEXT NOT NULL,
  min_chars INTEGER NOT NULL,
  max_chars INTEGER NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (min_chars >= 20),
  CHECK (max_chars <= 500),
  CHECK (min_chars < max_chars)
);

CREATE INDEX IF NOT EXISTS idx_match_quest_templates_creator
  ON matching.match_quest_templates(creator_user_id);

CREATE TABLE IF NOT EXISTS matching.match_quest_workflows (
  match_id UUID PRIMARY KEY REFERENCES matching.matches(id) ON DELETE CASCADE,
  template_id TEXT,
  unlock_state TEXT NOT NULL DEFAULT 'matched' CHECK (
    unlock_state IN ('matched', 'quest_pending', 'quest_under_review', 'conversation_unlocked', 'restricted')
  ),
  status TEXT NOT NULL DEFAULT 'pending' CHECK (
    status IN ('pending', 'approved', 'rejected', 'cooldown')
  ),
  submitter_user_id UUID,
  reviewer_user_id UUID,
  response_text TEXT,
  review_reason TEXT,
  submitted_at TIMESTAMPTZ,
  reviewed_at TIMESTAMPTZ,
  cooldown_until TIMESTAMPTZ,
  attempt_count INTEGER NOT NULL DEFAULT 0,
  window_started_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_match_quest_workflows_status
  ON matching.match_quest_workflows(status);

CREATE INDEX IF NOT EXISTS idx_match_quest_workflows_cooldown
  ON matching.match_quest_workflows(cooldown_until);
