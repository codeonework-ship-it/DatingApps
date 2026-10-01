-- 066_account_erasure.sql
--
-- Completes the deletion journey opened by 065.
--
-- Erasure here means irreversible anonymisation, not row deletion, and that is
-- forced by the schema rather than chosen for convenience:
-- `progression.xp_ledger.user_id` references users ON DELETE RESTRICT, and the
-- ledger carries an append-only trigger, so the ledger rows can be neither
-- cascaded away nor deleted first. A member who has ever earned XP cannot have
-- their `users` row removed. Verified against this database: the delete fails
-- with `violates foreign key constraint "xp_ledger_user_id_fkey"`.
--
-- The retained rows are non-identifying once the identity columns are scrubbed:
-- an XP ledger entry against an anonymised subject records that activity
-- happened, not who did it.

BEGIN;

ALTER TABLE user_management.users
  ADD COLUMN IF NOT EXISTS erased_at TIMESTAMPTZ;

-- Erased accounts must never be resurrected, matched, or authenticated. Every
-- read path that already excludes deactivated members can extend to this.
CREATE INDEX IF NOT EXISTS idx_users_erased
  ON user_management.users (erased_at)
  WHERE erased_at IS NOT NULL;

ALTER TABLE user_management.account_lifecycle_requests
  ADD COLUMN IF NOT EXISTS erasure_summary JSONB;

COMMIT;
