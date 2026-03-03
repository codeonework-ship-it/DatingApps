-- Persist user agreement acceptance state for Terms & Privacy.

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.tables
    WHERE table_schema = 'user_management' AND table_name = 'users'
  ) THEN
    ALTER TABLE user_management.users
      ADD COLUMN IF NOT EXISTS terms_accepted BOOLEAN NOT NULL DEFAULT FALSE,
      ADD COLUMN IF NOT EXISTS terms_accepted_at TIMESTAMPTZ,
      ADD COLUMN IF NOT EXISTS terms_version TEXT;
  END IF;
END $$;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'users'
  ) THEN
    ALTER TABLE public.users
      ADD COLUMN IF NOT EXISTS terms_accepted BOOLEAN NOT NULL DEFAULT FALSE,
      ADD COLUMN IF NOT EXISTS terms_accepted_at TIMESTAMPTZ,
      ADD COLUMN IF NOT EXISTS terms_version TEXT;
  END IF;
END $$;