-- 065_account_lifecycle.sql
--
-- Member-initiated deactivation, deletion and data export.
--
-- FRD gaps AUTH-009 and SAFE-008: the product had suspension and ban (operator
-- actions) but no member-initiated lifecycle at all. A member could neither
-- step away reversibly, nor ask to be erased, nor obtain a copy of their data.
--
-- Deletion is deferred rather than immediate. An account erased on the instant
-- of a tap cannot be recovered from a misclick or a coerced request, so a
-- request records an `effective_at` and stays cancellable until then. The wait
-- is the product decision this table encodes; the cleanup worker is what
-- enforces it.

BEGIN;

ALTER TABLE user_management.users
  ADD COLUMN IF NOT EXISTS deactivated_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS deletion_requested_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS deletion_effective_at TIMESTAMPTZ;

-- Discovery already excludes is_active=false; deactivation flips that flag and
-- this index keeps the reactivation and due-deletion sweeps cheap.
CREATE INDEX IF NOT EXISTS idx_users_deactivated
  ON user_management.users (deactivated_at)
  WHERE deactivated_at IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_users_deletion_due
  ON user_management.users (deletion_effective_at)
  WHERE deletion_effective_at IS NOT NULL;

CREATE TABLE IF NOT EXISTS user_management.account_lifecycle_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  request_type TEXT NOT NULL
    CHECK (request_type IN ('deactivate', 'reactivate', 'delete', 'export')),
  status TEXT NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'completed', 'cancelled', 'failed')),
  requested_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  -- When a deferred request becomes actionable. NULL for requests that take
  -- effect immediately.
  effective_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  cancelled_at TIMESTAMPTZ,
  reason TEXT,
  -- The member themselves, or an operator acting on their behalf. Recorded so
  -- a deletion can always be attributed.
  actor_user_id UUID REFERENCES user_management.users(id) ON DELETE SET NULL,
  actor_role TEXT NOT NULL DEFAULT 'member',
  -- Export payloads are held here rather than on disk: they are small, they
  -- must expire with the request, and a file would outlive the row that
  -- governs its retention.
  export_payload JSONB,
  export_expires_at TIMESTAMPTZ,
  correlation_id TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- At most one open deletion or export per member. Without this a member could
-- stack deletion requests with different effective dates and the sweep would
-- have no single answer for when they should be erased.
CREATE UNIQUE INDEX IF NOT EXISTS uq_account_lifecycle_open_request
  ON user_management.account_lifecycle_requests (user_id, request_type)
  WHERE status = 'pending';

CREATE INDEX IF NOT EXISTS idx_account_lifecycle_user
  ON user_management.account_lifecycle_requests (user_id, requested_at DESC);

CREATE INDEX IF NOT EXISTS idx_account_lifecycle_due
  ON user_management.account_lifecycle_requests (request_type, status, effective_at)
  WHERE status = 'pending';

-- Expired export payloads are dropped on a schedule; the row survives as
-- evidence that an export was requested and served.
CREATE INDEX IF NOT EXISTS idx_account_lifecycle_export_expiry
  ON user_management.account_lifecycle_requests (export_expires_at)
  WHERE export_payload IS NOT NULL;

COMMIT;
