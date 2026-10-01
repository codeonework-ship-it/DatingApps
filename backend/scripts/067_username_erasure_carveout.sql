-- 067_username_erasure_carveout.sql
--
-- Permits the username rewrite that erasure requires, and nothing else.
--
-- AUTH-001 makes the username immutable once a profile exists, and
-- `prevent_username_change` enforced that against every update without
-- exception. Erasure then could not proceed: the username is the member's most
-- recognisable identifier, so leaving it in place would retain the very data
-- the member asked to have removed, while rewriting it hit the trigger and
-- aborted the whole erasure transaction.
--
-- Immutability exists so live accounts cannot swap identities and impersonate
-- one another. An account being erased is terminating, not changing hands, so
-- the carve-out is scoped to exactly that transition:
--
--   * the row must be moving from not-erased to erased in this same statement,
--   * and the new username must be the derived tombstone.
--
-- The tombstone is 'erased_' plus 23 hex characters of a sha256 digest of
-- the id. Two constraints force that shape: `users_username_check` caps a
-- username at 30, and username is unique. Truncating the uuid itself
-- failed both ways — the full 32-character form is too long, and keeping
-- only its leading characters collides between ids that share a prefix,
-- which would abort the second member's erasure. A digest distributes
-- uniformly and does not carry a recoverable fragment of the original id.
--
-- Any other rename, including on an already-erased row, still raises.

BEGIN;

CREATE OR REPLACE FUNCTION user_management.prevent_username_change()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF OLD.username IS DISTINCT FROM NEW.username THEN
    IF OLD.erased_at IS NULL
       AND NEW.erased_at IS NOT NULL
       AND NEW.username = 'erased_' ||
           substr(encode(sha256(NEW.id::text::bytea), 'hex'), 1, 23)
    THEN
      RETURN NEW;
    END IF;
    RAISE EXCEPTION 'username is immutable';
  END IF;
  RETURN NEW;
END;
$$;

COMMIT;
