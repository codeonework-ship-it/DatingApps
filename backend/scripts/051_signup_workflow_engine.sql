-- 051_signup_workflow_engine.sql
-- Native PostgreSQL identity and durable, resumable signup workflow.

BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Photos are stored by the BFF on the local filesystem; only the relative
-- object path is persisted in PostgreSQL.
ALTER TABLE user_management.photos
  ADD COLUMN IF NOT EXISTS storage_path TEXT;

CREATE TABLE IF NOT EXISTS user_management.auth_credentials (
  user_id UUID NOT NULL UNIQUE DEFAULT gen_random_uuid(),
  username TEXT PRIMARY KEY,
  password_hash TEXT NOT NULL,
  is_disabled BOOLEAN NOT NULL DEFAULT FALSE,
  failed_login_count INTEGER NOT NULL DEFAULT 0 CHECK (failed_login_count >= 0),
  last_login_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT auth_credentials_username_format_check
    CHECK (username ~ '^[a-z0-9]([a-z0-9._]{1,28}[a-z0-9])?$')
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_auth_credentials_username_normalized
  ON user_management.auth_credentials (LOWER(username));

CREATE TABLE IF NOT EXISTS user_management.auth_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES user_management.auth_credentials(user_id) ON DELETE CASCADE,
  access_token_hash BYTEA NOT NULL UNIQUE,
  refresh_token_hash BYTEA NOT NULL UNIQUE,
  access_expires_at TIMESTAMPTZ NOT NULL,
  refresh_expires_at TIMESTAMPTZ NOT NULL,
  revoked_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (refresh_expires_at > access_expires_at)
);

CREATE INDEX IF NOT EXISTS idx_auth_sessions_active_user
  ON user_management.auth_sessions (user_id, access_expires_at DESC)
  WHERE revoked_at IS NULL;

CREATE TABLE IF NOT EXISTS user_management.signup_workflows (
  user_id UUID PRIMARY KEY REFERENCES user_management.auth_credentials(user_id) ON DELETE CASCADE,
  username TEXT NOT NULL,
  workflow_version INTEGER NOT NULL DEFAULT 1,
  state TEXT NOT NULL DEFAULT 'credentials_created'
    CHECK (state IN (
      'credentials_created', 'basics_captured', 'terms_accepted',
      'profile_in_progress', 'completed'
    )),
  current_activity TEXT NOT NULL DEFAULT 'bootstrap_profile'
    CHECK (current_activity IN (
      'bootstrap_profile', 'accept_terms', 'build_profile', 'complete_profile', 'done'
    )),
  lock_version INTEGER NOT NULL DEFAULT 0,
  credentials_created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  basics_captured_at TIMESTAMPTZ,
  terms_accepted_at TIMESTAMPTZ,
  profile_started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  last_error TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT signup_workflows_username_fk
    FOREIGN KEY (user_id) REFERENCES user_management.auth_credentials(user_id),
  CONSTRAINT signup_workflows_completion_check
    CHECK ((state = 'completed') = (completed_at IS NOT NULL))
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_signup_workflows_username_normalized
  ON user_management.signup_workflows (LOWER(username));
CREATE INDEX IF NOT EXISTS idx_signup_workflows_resume
  ON user_management.signup_workflows (state, updated_at)
  WHERE state <> 'completed';

CREATE TABLE IF NOT EXISTS user_management.signup_workflow_activities (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES user_management.signup_workflows(user_id) ON DELETE CASCADE,
  activity TEXT NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('started', 'completed', 'failed')),
  idempotency_key TEXT,
  payload JSONB NOT NULL DEFAULT '{}'::JSONB,
  error_message TEXT,
  occurred_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_signup_activity_idempotency
  ON user_management.signup_workflow_activities (user_id, idempotency_key)
  WHERE idempotency_key IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_signup_activities_timeline
  ON user_management.signup_workflow_activities (user_id, occurred_at, id);

COMMIT;
