-- 052_auth_security_foundation.sql
-- Platform-wide native PostgreSQL session security, RBAC, lockout, and
-- username-only recovery codes.

BEGIN;

ALTER TABLE user_management.auth_credentials
  ADD COLUMN IF NOT EXISTS failed_login_window_started_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS locked_until TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS password_changed_at TIMESTAMPTZ;

ALTER TABLE user_management.auth_sessions
  ADD COLUMN IF NOT EXISTS last_used_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS revoked_reason TEXT;

CREATE TABLE IF NOT EXISTS user_management.auth_account_roles (
  user_id UUID NOT NULL REFERENCES user_management.auth_credentials(user_id) ON DELETE CASCADE,
  role TEXT NOT NULL CHECK (role IN ('user', 'moderator', 'admin')),
  granted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  granted_by UUID REFERENCES user_management.auth_credentials(user_id),
  PRIMARY KEY (user_id, role)
);

INSERT INTO user_management.auth_account_roles (user_id, role)
SELECT user_id, 'user' FROM user_management.auth_credentials
ON CONFLICT (user_id, role) DO NOTHING;

CREATE TABLE IF NOT EXISTS user_management.auth_recovery_codes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES user_management.auth_credentials(user_id) ON DELETE CASCADE,
  code_hash BYTEA NOT NULL UNIQUE,
  expires_at TIMESTAMPTZ NOT NULL,
  used_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_auth_recovery_codes_active
  ON user_management.auth_recovery_codes (user_id, expires_at DESC)
  WHERE used_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_auth_sessions_refresh_active
  ON user_management.auth_sessions (refresh_token_hash, refresh_expires_at)
  WHERE revoked_at IS NULL;

COMMIT;
