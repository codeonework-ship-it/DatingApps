-- ─────────────────────────────────────────────────────────────────────────────
-- 082: Account recovery assistance (PEN-06 / AUTH-009)
--
-- The journey for a member who lost their recovery code and cannot sign in:
--   1. The member submits a help request from the sign-in screen. The API
--      answers identically whether or not the username exists, and never
--      changes credentials by itself.
--   2. A trust & safety operator verifies identity out of band, records how,
--      and either declines or issues a short-lived, single-use recovery code
--      that is displayed once. Issuing revokes every session for the account,
--      so recovery can never revive a revoked session.
--   3. The member uses the code with the existing password-recovery flow.
-- Safe to run repeatedly.
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS user_management.account_recovery_requests (
  id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id            UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  member_message     TEXT CHECK (member_message IS NULL OR char_length(member_message) <= 500),
  status             TEXT NOT NULL DEFAULT 'open'
                       CHECK (status IN ('open','code_issued','declined','expired')),
  identity_check     TEXT CHECK (identity_check IS NULL OR identity_check IN
                       ('verified_identity_match','account_detail_match','other')),
  resolution_note    TEXT CHECK (resolution_note IS NULL OR char_length(resolution_note) BETWEEN 10 AND 1000),
  resolved_by        UUID,
  resolved_at        TIMESTAMPTZ,
  code_expires_at    TIMESTAMPTZ,
  created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK ((status = 'open') = (resolved_at IS NULL)),
  CHECK (status <> 'code_issued' OR (identity_check IS NOT NULL AND resolution_note IS NOT NULL
                                     AND resolved_by IS NOT NULL AND code_expires_at IS NOT NULL))
);

CREATE INDEX IF NOT EXISTS idx_account_recovery_open
  ON user_management.account_recovery_requests(created_at)
  WHERE status = 'open';
CREATE INDEX IF NOT EXISTS idx_account_recovery_user
  ON user_management.account_recovery_requests(user_id, created_at DESC);

-- Open requests expire after 30 days so a stale request cannot be acted on
-- long after the member asked.
INSERT INTO platform.retention_policies (policy_name, relation_name, retention_interval, batch_size)
VALUES ('open_recovery_requests', 'user_management.account_recovery_requests', INTERVAL '30 days', 1000)
ON CONFLICT (policy_name) DO NOTHING;
