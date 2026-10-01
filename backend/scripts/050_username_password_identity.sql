-- Migration 050: canonical username identity for signup/login.
-- UUID remains the relational primary key; username is the immutable,
-- case-normalized, globally unique account handle.

BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

ALTER TABLE user_management.users
  ADD COLUMN IF NOT EXISTS username TEXT;

UPDATE user_management.users
SET username = 'user_' || SUBSTRING(REPLACE(id::TEXT, '-', '') FROM 1 FOR 20)
WHERE username IS NULL OR BTRIM(username) = '';

UPDATE user_management.users
SET username = LOWER(BTRIM(username));

-- Replace legacy handles that cannot satisfy the canonical login contract.
UPDATE user_management.users
SET username = 'user_' || SUBSTRING(REPLACE(id::TEXT, '-', '') FROM 1 FOR 20)
WHERE username !~ '^[a-z0-9]([a-z0-9._]{1,28}[a-z0-9])?$';

-- Resolve any case-insensitive legacy collisions deterministically before the
-- unique index is introduced.
WITH ranked_usernames AS (
  SELECT
    id,
    ROW_NUMBER() OVER (PARTITION BY LOWER(username) ORDER BY id) AS duplicate_rank
  FROM user_management.users
)
UPDATE user_management.users AS users
SET username = 'user_' || SUBSTRING(REPLACE(users.id::TEXT, '-', '') FROM 1 FOR 20)
FROM ranked_usernames
WHERE users.id = ranked_usernames.id
  AND ranked_usernames.duplicate_rank > 1;

ALTER TABLE user_management.users
  ALTER COLUMN username SET NOT NULL,
  ALTER COLUMN username SET DEFAULT ('user_' || SUBSTRING(REPLACE(gen_random_uuid()::TEXT, '-', '') FROM 1 FOR 20)),
  ALTER COLUMN phone_number DROP NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS uq_users_username_normalized
  ON user_management.users (LOWER(username));

ALTER TABLE user_management.users
  DROP CONSTRAINT IF EXISTS users_username_format_check;
ALTER TABLE user_management.users
  ADD CONSTRAINT users_username_format_check
  CHECK (username ~ '^[a-z0-9]([a-z0-9._]{1,28}[a-z0-9])?$');

CREATE OR REPLACE FUNCTION user_management.prevent_username_change()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF OLD.username IS DISTINCT FROM NEW.username THEN
    RAISE EXCEPTION 'username is immutable';
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_users_username_immutable ON user_management.users;
CREATE TRIGGER trg_users_username_immutable
BEFORE UPDATE OF username ON user_management.users
FOR EACH ROW EXECUTE FUNCTION user_management.prevent_username_change();

-- Keep the optional public compatibility table aligned when it exists.
DO $$
BEGIN
  IF TO_REGCLASS('public.users') IS NOT NULL THEN
    ALTER TABLE public.users ADD COLUMN IF NOT EXISTS username TEXT;
    UPDATE public.users
    SET username = 'user_' || SUBSTRING(REPLACE(id::TEXT, '-', '') FROM 1 FOR 20)
    WHERE username IS NULL OR BTRIM(username) = '';
    ALTER TABLE public.users
      ALTER COLUMN username SET NOT NULL,
      ALTER COLUMN username SET DEFAULT ('user_' || SUBSTRING(REPLACE(gen_random_uuid()::TEXT, '-', '') FROM 1 FOR 20));
    CREATE UNIQUE INDEX IF NOT EXISTS uq_public_users_username_normalized
      ON public.users (LOWER(username));
    DROP TRIGGER IF EXISTS trg_users_username_immutable ON public.users;
    CREATE TRIGGER trg_users_username_immutable
    BEFORE UPDATE OF username ON public.users
    FOR EACH ROW EXECUTE FUNCTION user_management.prevent_username_change();
  END IF;
END;
$$;

COMMIT;
