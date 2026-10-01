-- ─────────────────────────────────────────────────────────────────────────────
-- 093: Member locale preference
--
-- The app and the website ship in en-US (default), en-GB, de, fr, ru, es, it,
-- pt, nl and pl. A member's chosen language is part of their account so it
-- follows them onto a second device, exactly like `theme`. NULL means "follow
-- the device language"; the mobile client sends an empty string for that and
-- the BFF stores NULL.
--
-- The value is a BCP 47 language tag limited to the shapes the product ships:
-- a two-letter language, optionally followed by a two-letter region
-- ('de', 'en-GB'). Anything else is rejected at the column so a stray value
-- can never reach the client's locale resolver.
--
-- Safe to run repeatedly.
-- ─────────────────────────────────────────────────────────────────────────────

BEGIN;

ALTER TABLE user_management.user_settings
  ADD COLUMN IF NOT EXISTS locale TEXT;

ALTER TABLE user_management.user_settings
  DROP CONSTRAINT IF EXISTS user_settings_locale_check;
ALTER TABLE user_management.user_settings
  ADD CONSTRAINT user_settings_locale_check
  CHECK (locale IS NULL OR locale ~ '^[a-z]{2}(-[A-Z]{2})?$');

COMMENT ON COLUMN user_management.user_settings.locale IS
  'Member-chosen UI language as a BCP 47 tag (language[-REGION]); NULL follows the device.';

COMMIT;
