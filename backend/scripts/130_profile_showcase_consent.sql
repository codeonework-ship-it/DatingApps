-- Profile showcase consent (2026-10-02).
--
-- A member's public writing (community chapters) and wall-featured photos can
-- appear on their profile, but only after the member opts in. Default off:
-- publishing a chapter to the community or a photo to the wall is not consent
-- to pin it to the profile people see before saying hello.
BEGIN;

ALTER TABLE user_management.user_settings
 ADD COLUMN IF NOT EXISTS profile_showcase_visible BOOLEAN NOT NULL DEFAULT FALSE;

INSERT INTO public.schema_migrations(version) VALUES('130_profile_showcase_consent') ON CONFLICT DO NOTHING;
COMMIT;
