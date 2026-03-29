-- 041_photos_storage_path_and_bucket.sql
-- Adds storage_path column to user_management.photos.
-- Creates the profile_photos Supabase storage bucket (public) with
-- permissive RLS policies so the Flutter anon-key client can upload directly.

BEGIN;

-- ── 1. Add storage_path to photos table ──────────────────────────────────────
ALTER TABLE user_management.photos
  ADD COLUMN IF NOT EXISTS storage_path TEXT;

COMMENT ON COLUMN user_management.photos.storage_path IS
  'Supabase Storage object path, e.g. user-photos/{userId}/{photoId}.jpg. '
  'Local device copy is saved at AppDocDir/profile_photos/{userId}/{photoId}.jpg.';

-- ── 2. Create profile_photos storage bucket (idempotent) ─────────────────────
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'profile_photos',
  'profile_photos',
  TRUE,                              -- public: URLs are readable without auth
  10485760,                          -- 10 MB per file
  ARRAY['image/jpeg','image/jpg','image/png','image/webp','image/heic']
)
ON CONFLICT (id) DO UPDATE
  SET public            = TRUE,
      file_size_limit   = EXCLUDED.file_size_limit,
      allowed_mime_types = EXCLUDED.allowed_mime_types;

-- ── 3. RLS policies on storage.objects for profile_photos ────────────────────
-- Allow anyone (anon/service_role) to INSERT objects in this bucket.
-- Flutter app uses the anon key with a custom-auth user ID, not Supabase Auth,
-- so we cannot check auth.uid(). Path validation is enforced at the app layer.

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'storage' AND tablename = 'objects'
      AND policyname = 'profile_photos_anon_insert'
  ) THEN
    EXECUTE $p$
      CREATE POLICY profile_photos_anon_insert
        ON storage.objects
        FOR INSERT
        TO anon, authenticated
        WITH CHECK (bucket_id = 'profile_photos')
    $p$;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'storage' AND tablename = 'objects'
      AND policyname = 'profile_photos_anon_update'
  ) THEN
    EXECUTE $p$
      CREATE POLICY profile_photos_anon_update
        ON storage.objects
        FOR UPDATE
        TO anon, authenticated
        USING (bucket_id = 'profile_photos')
    $p$;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'storage' AND tablename = 'objects'
      AND policyname = 'profile_photos_public_select'
  ) THEN
    EXECUTE $p$
      CREATE POLICY profile_photos_public_select
        ON storage.objects
        FOR SELECT
        TO anon, authenticated
        USING (bucket_id = 'profile_photos')
    $p$;
  END IF;
END;
$$;

-- ── 4. Disable RLS on storage.objects for profile_photos ─────────────────────
-- Note: Supabase manages RLS on storage.objects at the API level.
-- The policies above are sufficient. Make sure RLS is enabled on the table
-- via Supabase Dashboard → Storage → Policies → Enabled.

COMMIT;
