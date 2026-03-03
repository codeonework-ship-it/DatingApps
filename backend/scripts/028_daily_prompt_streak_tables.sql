-- Daily prompt + streak persistence tables for engagement Phase A.
-- Safe to run repeatedly on Supabase/Postgres.

CREATE TABLE IF NOT EXISTS matching.daily_prompts (
  id UUID PRIMARY KEY,
  prompt_date DATE NOT NULL,
  domain TEXT NOT NULL CHECK (domain IN ('values', 'lifestyle', 'relationship_style')),
  prompt_text TEXT NOT NULL,
  response_mode TEXT NOT NULL DEFAULT 'text' CHECK (response_mode IN ('text', 'voice')),
  min_chars INTEGER NOT NULL DEFAULT 1,
  max_chars INTEGER NOT NULL DEFAULT 240,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (prompt_date)
);

CREATE INDEX IF NOT EXISTS idx_daily_prompts_date_domain
  ON matching.daily_prompts(prompt_date DESC, domain);

CREATE TABLE IF NOT EXISTS matching.prompt_answers (
  id UUID PRIMARY KEY,
  prompt_id UUID NOT NULL REFERENCES matching.daily_prompts(id) ON DELETE CASCADE,
  user_id UUID NOT NULL,
  answer_text TEXT NOT NULL,
  normalized_answer TEXT NOT NULL,
  answer_date DATE NOT NULL,
  is_edited BOOLEAN NOT NULL DEFAULT FALSE,
  edit_window_until TIMESTAMPTZ NOT NULL,
  answered_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (char_length(answer_text) BETWEEN 1 AND 240),
  UNIQUE (user_id, answer_date)
);

CREATE INDEX IF NOT EXISTS idx_prompt_answers_prompt_date
  ON matching.prompt_answers(prompt_id, answer_date DESC);

CREATE INDEX IF NOT EXISTS idx_prompt_answers_user_date
  ON matching.prompt_answers(user_id, answer_date DESC);

CREATE TABLE IF NOT EXISTS matching.user_streaks (
  user_id UUID PRIMARY KEY,
  current_days INTEGER NOT NULL DEFAULT 0,
  longest_days INTEGER NOT NULL DEFAULT 0,
  last_answered_date DATE,
  next_milestone INTEGER NOT NULL DEFAULT 3,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (current_days >= 0),
  CHECK (longest_days >= 0)
);
