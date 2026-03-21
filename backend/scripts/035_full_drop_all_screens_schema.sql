-- 035_full_drop_all_screens_schema.sql
-- WARNING: Destructive script. Drops all app schemas and data for full rebuild.

BEGIN;

DROP SCHEMA IF EXISTS audit CASCADE;
DROP SCHEMA IF EXISTS matching CASCADE;
DROP SCHEMA IF EXISTS user_management CASCADE;

COMMIT;
