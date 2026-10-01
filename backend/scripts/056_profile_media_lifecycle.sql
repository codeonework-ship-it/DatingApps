-- 056_profile_media_lifecycle.sql
-- Durable local-PostgreSQL lifecycle metadata for profile photos and drafts.

BEGIN;

ALTER TABLE user_management.photos
  ADD COLUMN IF NOT EXISTS original_filename TEXT,
  ADD COLUMN IF NOT EXISTS mime_type TEXT,
  ADD COLUMN IF NOT EXISTS width_px INTEGER,
  ADD COLUMN IF NOT EXISTS height_px INTEGER,
  ADD COLUMN IF NOT EXISTS size_bytes BIGINT,
  ADD COLUMN IF NOT EXISTS content_sha256 TEXT,
  ADD COLUMN IF NOT EXISTS lifecycle_status TEXT NOT NULL DEFAULT 'active',
  ADD COLUMN IF NOT EXISTS retained_until TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS moderation_status TEXT NOT NULL DEFAULT 'pending',
  ADD COLUMN IF NOT EXISTS moderation_reason TEXT;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'photos_dimensions_check'
      AND conrelid = 'user_management.photos'::regclass
  ) THEN
    ALTER TABLE user_management.photos
      ADD CONSTRAINT photos_dimensions_check
      CHECK (
        (width_px IS NULL AND height_px IS NULL)
        OR (width_px BETWEEN 300 AND 4096 AND height_px BETWEEN 300 AND 4096)
      );
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'photos_size_bytes_check'
      AND conrelid = 'user_management.photos'::regclass
  ) THEN
    ALTER TABLE user_management.photos
      ADD CONSTRAINT photos_size_bytes_check
      CHECK (size_bytes IS NULL OR size_bytes BETWEEN 1 AND 10485760);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'photos_mime_type_check'
      AND conrelid = 'user_management.photos'::regclass
  ) THEN
    ALTER TABLE user_management.photos
      ADD CONSTRAINT photos_mime_type_check
      CHECK (
        mime_type IS NULL OR mime_type IN (
          'image/jpeg', 'image/png', 'image/webp', 'image/heic'
        )
      );
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'photos_lifecycle_status_check'
      AND conrelid = 'user_management.photos'::regclass
  ) THEN
    ALTER TABLE user_management.photos
      ADD CONSTRAINT photos_lifecycle_status_check
      CHECK (lifecycle_status IN (
        'staged', 'active', 'delete_pending', 'deleted', 'quarantined'
      ));
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'photos_moderation_status_check'
      AND conrelid = 'user_management.photos'::regclass
  ) THEN
    ALTER TABLE user_management.photos
      ADD CONSTRAINT photos_moderation_status_check
      CHECK (moderation_status IN ('pending', 'approved', 'rejected'));
  END IF;
END;
$$;

ALTER TABLE user_management.photos
  DROP CONSTRAINT IF EXISTS photos_user_id_ordering_key;

DROP INDEX IF EXISTS user_management.idx_photos_user_order;

CREATE UNIQUE INDEX IF NOT EXISTS uq_photos_active_user_order
  ON user_management.photos (user_id, ordering)
  WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_photos_user_lifecycle
  ON user_management.photos (user_id, lifecycle_status, ordering)
  WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_photos_cleanup_due
  ON user_management.photos (retained_until, uploaded_at, id)
  WHERE lifecycle_status IN ('staged', 'delete_pending', 'quarantined');

ALTER TABLE user_management.profile_drafts
  ADD COLUMN IF NOT EXISTS retained_until TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS purged_at TIMESTAMPTZ;

CREATE INDEX IF NOT EXISTS idx_profile_drafts_retention_due
  ON user_management.profile_drafts (retained_until, user_id)
  WHERE completed_at IS NOT NULL AND purged_at IS NULL;

CREATE TABLE IF NOT EXISTS user_management.profile_snapshots (
  user_id UUID PRIMARY KEY REFERENCES user_management.users(id) ON DELETE CASCADE,
  profile_payload JSONB NOT NULL DEFAULT '{}'::JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO user_management.profile_snapshots (user_id, profile_payload, updated_at)
SELECT user_id, draft_payload, updated_at
FROM user_management.profile_drafts
WHERE completed_at IS NOT NULL
ON CONFLICT (user_id) DO UPDATE SET
  profile_payload=EXCLUDED.profile_payload,
  updated_at=GREATEST(user_management.profile_snapshots.updated_at,EXCLUDED.updated_at);

COMMENT ON COLUMN user_management.profile_drafts.retained_until IS
  'Completed setup draft safety snapshot expires 30 days after completion.';
COMMENT ON COLUMN user_management.photos.retained_until IS
  'Staged upload expiry; NULL for active profile media.';

COMMIT;
