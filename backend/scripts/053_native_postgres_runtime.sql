BEGIN;

ALTER TABLE matching.community_groups
  ADD COLUMN IF NOT EXISTS visibility TEXT NOT NULL DEFAULT 'private';

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'community_groups_visibility_check'
      AND conrelid = 'matching.community_groups'::regclass
  ) THEN
    ALTER TABLE matching.community_groups
      ADD CONSTRAINT community_groups_visibility_check
      CHECK (visibility IN ('private', 'public'));
  END IF;
END $$;

ALTER TABLE matching.community_group_members
  ADD COLUMN IF NOT EXISTS invited_by_user_id UUID,
  ADD COLUMN IF NOT EXISTS left_at TIMESTAMPTZ;

CREATE INDEX IF NOT EXISTS idx_community_groups_city_topic
  ON matching.community_groups(city, topic, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_community_groups_creator
  ON matching.community_groups(created_by_user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_community_group_members_user
  ON matching.community_group_members(user_id, status, joined_at DESC);

CREATE INDEX IF NOT EXISTS idx_community_group_invites_invitee
  ON matching.community_group_invites(invitee_user_id, status, invited_at DESC);

CREATE INDEX IF NOT EXISTS idx_community_group_invites_group
  ON matching.community_group_invites(group_id, status, invited_at DESC);

CREATE TABLE IF NOT EXISTS public.schema_migrations (
  version TEXT PRIMARY KEY,
  applied_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO public.schema_migrations(version)
VALUES ('053_native_postgres_runtime')
ON CONFLICT (version) DO UPDATE SET applied_at = EXCLUDED.applied_at;

COMMIT;
