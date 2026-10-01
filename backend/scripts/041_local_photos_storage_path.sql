-- Native PostgreSQL/local-filesystem replacement for the Supabase-specific
-- storage bucket section in 041_photos_storage_path_and_bucket.sql.
BEGIN;
ALTER TABLE user_management.photos
  ADD COLUMN IF NOT EXISTS storage_path TEXT;
COMMENT ON COLUMN user_management.photos.storage_path IS
  'Relative path managed by the mobile BFF local filesystem media store.';
COMMIT;
