-- Minimise the audit copies of request telemetry (owner-approved, 2026-10-01).
--
-- Migration 036 attached the generic row-change audit trigger to
-- matching.activity_events, so audit.change_log kept a full copy of every API
-- request row for 24 months, including the caller's IP address, raw query
-- string and concrete paths with member ids. Migration 122 stopped storing
-- those fields in activity_events itself; this migration closes the copy.
--
-- Approach (recommended, approved by the owner after a pre-check):
--  1. Stop copying request telemetry into audit.change_log. Request rows are
--     operational telemetry with their own 90-day retention, not member data
--     changes, so they don't belong in the 24-month change audit.
--  2. Minimise, don't delete: existing copies keep their id, time, method,
--     status, duration and content type, so the audit trail of "a request
--     happened" survives. IP address, query string, device and geo fields are
--     removed, and member ids in paths are replaced by {id}.
--  3. Members on an active legal hold are skipped entirely.
--
-- Pre-check on the local database before applying: 390,502 copies (~552 MB),
-- 388,597 with an IP and query string, 413 members, 0 active legal holds.
BEGIN;

DROP TRIGGER IF EXISTS trg_audit_row_change ON matching.activity_events;

-- The audit table emits a domain event for each row change (field names only).
-- Minimising ~400k rows would flood the outbox with maintenance noise, so the
-- trigger is paused for this transaction only and restored below.
ALTER TABLE audit.change_log DISABLE TRIGGER trg_domain_event_audit_change_log;

CREATE OR REPLACE FUNCTION pg_temp.minimise_request_copy(data JSONB) RETURNS JSONB
LANGUAGE sql IMMUTABLE AS $$
  SELECT CASE WHEN data IS NULL THEN NULL ELSE
    (data - 'ip_address' - 'source_device_id' - 'geo_country' - 'geo_state'
          - 'geo_city' - 'geo_latitude' - 'geo_longitude')
    || jsonb_build_object(
      'event_name', regexp_replace(COALESCE(data->>'event_name',''),
        '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}', '{id}', 'g'),
      'payload', CASE WHEN jsonb_typeof(data->'payload') <> 'object' THEN data->'payload' ELSE
        (data->'payload')
        || jsonb_build_object('resource', regexp_replace(COALESCE(data#>>'{payload,resource}',''),
             '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}', '{id}', 'g'))
        || CASE WHEN jsonb_typeof(data#>'{payload,details}') = 'object' THEN
             jsonb_build_object('details',
               ((data#>'{payload,details}') - 'remote_addr' - 'query' - 'user_agent')
               || jsonb_build_object('path', regexp_replace(COALESCE(data#>>'{payload,details,path}',''),
                    '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}', '{id}', 'g'),
                  'minimised', 'request_audit_copy'))
           ELSE '{}'::jsonb END
      END)
  END
$$;

UPDATE audit.change_log c
SET old_data = pg_temp.minimise_request_copy(c.old_data),
    new_data = pg_temp.minimise_request_copy(c.new_data),
    ip_address = NULL, source_device_id = NULL,
    geo_country = NULL, geo_state = NULL, geo_city = NULL,
    geo_latitude = NULL, geo_longitude = NULL
WHERE c.table_schema = 'matching' AND c.table_name = 'activity_events'
  AND COALESCE(c.new_data#>>'{payload,details,minimised}', c.old_data#>>'{payload,details,minimised}', '') <> 'request_audit_copy'
  AND NOT platform.member_on_legal_hold(
    CASE WHEN COALESCE(c.new_data->>'user_id', c.old_data->>'user_id', '') ~*
              '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
         THEN COALESCE(c.new_data->>'user_id', c.old_data->>'user_id')::UUID END);

ALTER TABLE audit.change_log ENABLE TRIGGER trg_domain_event_audit_change_log;

INSERT INTO public.schema_migrations(version) VALUES('125_minimise_request_audit_copies') ON CONFLICT DO NOTHING;
COMMIT;
