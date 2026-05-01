-- 043_profile_setup_completion_tracking.sql
-- Adds durable completion tracking for the profile setup wizard.
--
-- Changes:
--  1. Add completed_at and completion_source columns to profile_drafts.
--  2. Create profile_setup_completions audit table for reporting/analytics.
--     Analytics must be generated from durable tables, never from process memory.
--  3. Add supporting indexes.

BEGIN;

-- ── 1. Extend profile_drafts with completion metadata ────────────────────────
ALTER TABLE user_management.profile_drafts
  ADD COLUMN IF NOT EXISTS completed_at       TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS completion_source  TEXT;

COMMENT ON COLUMN user_management.profile_drafts.completed_at IS
  'Timestamp when the user clicked "Complete Profile" and the draft was promoted. '
  'NULL means still in draft.';

COMMENT ON COLUMN user_management.profile_drafts.completion_source IS
  'Surface that triggered completion, e.g. "mobile_setup_wizard", "admin_promote". '
  'Used for funnel analytics.';

-- ── 2. Profile setup completions audit table ──────────────────────────────────
-- One row per completion event (idempotent: unique on user_id + completed_at).
-- This is the authoritative source for completion-funnel reporting.
CREATE TABLE IF NOT EXISTS user_management.profile_setup_completions (
  id                UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id           UUID        NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  completed_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  completion_source TEXT        NOT NULL DEFAULT 'mobile_setup_wizard',
  photos_count      INTEGER     NOT NULL DEFAULT 0,
  bio_length        INTEGER     NOT NULL DEFAULT 0,
  has_height        BOOLEAN     NOT NULL DEFAULT FALSE,
  has_education     BOOLEAN     NOT NULL DEFAULT FALSE,
  has_profession    BOOLEAN     NOT NULL DEFAULT FALSE,
  has_lifestyle     BOOLEAN     NOT NULL DEFAULT FALSE,
  profile_completion_pct SMALLINT NOT NULL DEFAULT 0,
  idempotency_key   TEXT        UNIQUE,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE user_management.profile_setup_completions IS
  'Audit/event log of profile setup completions. '
  'Do not read from process memory for analytics — query this table.';

COMMENT ON COLUMN user_management.profile_setup_completions.idempotency_key IS
  'Client-generated idempotency key (UUID). Duplicate submissions with the same '
  'key are safely ignored via ON CONFLICT DO NOTHING.';

-- ── 3. Indexes ────────────────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_profile_drafts_completed_at
  ON user_management.profile_drafts (completed_at)
  WHERE completed_at IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_profile_setup_completions_user_id
  ON user_management.profile_setup_completions (user_id);

CREATE INDEX IF NOT EXISTS idx_profile_setup_completions_completed_at
  ON user_management.profile_setup_completions (completed_at DESC);

COMMIT;
