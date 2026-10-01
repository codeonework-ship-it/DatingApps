-- Least-privilege PostgreSQL role for postgres_exporter.
--
-- Run as a superuser (or the database owner with CREATEROLE), once per cluster:
--   sudo -u postgres psql -v ON_ERROR_STOP=1 \
--        -v monitor_password="$(openssl rand -base64 30)" \
--        -v app_db=dating_app \
--        -f deploy/monitoring/postgres/create_monitoring_role.sql
-- then put the same password into /etc/connect-monitoring/postgres_exporter.env.
--
-- The role gets pg_monitor (read access to pg_stat_* / pg_settings and the
-- size functions) and nothing else: no table privileges, read-only sessions,
-- short statement timeouts and at most three connections. This is a deploy
-- step, not a schema migration: it touches only the role catalogue.

SELECT 'CREATE ROLE connect_monitor LOGIN'
WHERE NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'connect_monitor') \gexec

ALTER ROLE connect_monitor WITH LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS
  INHERIT CONNECTION LIMIT 3 PASSWORD :'monitor_password';
GRANT pg_monitor TO connect_monitor;

ALTER ROLE connect_monitor SET default_transaction_read_only = on;
ALTER ROLE connect_monitor SET statement_timeout = '5s';
ALTER ROLE connect_monitor SET lock_timeout = '1s';
ALTER ROLE connect_monitor SET idle_in_transaction_session_timeout = '10s';
ALTER ROLE connect_monitor SET application_name = 'postgres_exporter';

GRANT CONNECT ON DATABASE :"app_db" TO connect_monitor;
