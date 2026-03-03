-- Remove temporary SMTP sender settings persistence introduced for local testing.
-- Supabase OTP sender configuration should be managed in Supabase Auth settings.

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.tables
    WHERE table_schema = 'user_management'
      AND table_name = 'system_settings'
  ) THEN
    DELETE FROM user_management.system_settings
    WHERE setting_key = 'smtp_sender_email';

    IF NOT EXISTS (
      SELECT 1 FROM user_management.system_settings LIMIT 1
    ) THEN
      DROP TABLE user_management.system_settings;
    END IF;
  END IF;
END $$;
