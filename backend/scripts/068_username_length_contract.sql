-- Enforce the documented 3-30 character username contract without renaming
-- immutable existing identities. If legacy invalid rows exist, this transaction
-- fails and keeps the previous constraint; resolve those identities explicitly.
BEGIN;
SET LOCAL lock_timeout = '5s';
ALTER TABLE user_management.users
  DROP CONSTRAINT IF EXISTS users_username_format_check;
ALTER TABLE user_management.users
  ADD CONSTRAINT users_username_format_check
  CHECK (username ~ '^[a-z0-9][a-z0-9._]{1,28}[a-z0-9]$');
ALTER TABLE user_management.auth_credentials
  DROP CONSTRAINT IF EXISTS auth_credentials_username_format_check;
ALTER TABLE user_management.auth_credentials
  ADD CONSTRAINT auth_credentials_username_format_check
  CHECK (username ~ '^[a-z0-9][a-z0-9._]{1,28}[a-z0-9]$');
COMMIT;
