-- Stop domain-event and audit write amplification; give the outbox a retention
-- policy (owner-approved, 2026-10-03).
--
-- Found on the local database (read-only checks before this migration):
--  * platform.domain_event_outbox: 5,094,386 rows (~4.9 GB) in six days, no
--    retention, and no consumer has ever claimed an event
--    (platform.event_deliveries is empty).
--  * Every request row written to matching.activity_events emitted a
--    row-change domain event; the audit trigger on that table (removed by 125,
--    re-attached when 036 re-ran audit.attach_audit_triggers('matching')) also
--    copied it into audit.change_log and audit.activity_log, and both audit
--    tables are themselves event sources. One request became ~3-4 outbox rows
--    plus 2 audit rows (2026-10-02: 523,454 requests -> 2.16M outbox rows).
--
-- This migration:
--  1. Adds an explicit "excluded on purpose" state to the event source
--     registry. Excluded sources emit nothing, register_event_source() cannot
--     re-enable them (so re-running 075 is safe), and the coverage check
--     counts them as covered rather than "unregistered".
--  2. Excludes matching.activity_events (request telemetry with its own
--     90/400-day retention; the member activity log reads it directly) and
--     audit.change_log / audit.activity_log (events about audit rows only
--     duplicate every audited change).
--  3. Re-applies 125 durably: audit.attach_audit_triggers() honours a new
--     audit.trigger_exclusions list, so re-running 036 cannot re-attach the
--     audit trigger to matching.activity_events.
--  4. Outbox retention: policy 'domain_event_outbox' (90 days) applied by
--     platform.run_domain_event_retention(), which deletes in batches only
--     events that no consumer still has pending, retrying or in flight
--     (completed deliveries go first, as the FK is RESTRICT). The append-only
--     trigger still rejects every UPDATE and every other DELETE.
--
-- It does NOT delete the existing backlog beyond the 90-day window; removing
-- the noise rows already written is a separate, owner-approved step.
BEGIN;

-- 1. Exclusion state ---------------------------------------------------------

ALTER TABLE platform.event_source_registry
  ADD COLUMN IF NOT EXISTS excluded_reason TEXT;

COMMENT ON COLUMN platform.event_source_registry.excluded_reason IS
  'Set when a table is deliberately not an event source (no trigger, counted as covered). register_event_source() never re-enables it.';

CREATE OR REPLACE FUNCTION platform.register_event_source(
  p_schema TEXT,
  p_table TEXT,
  p_aggregate_type TEXT DEFAULT NULL
) RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
  relation_kind "char";
  trigger_name TEXT;
  aggregate_name TEXT;
BEGIN
  SELECT c.relkind INTO relation_kind
  FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
  WHERE n.nspname=p_schema AND c.relname=p_table;
  IF relation_kind IS NULL OR relation_kind NOT IN ('r','p') THEN
    RAISE EXCEPTION 'event source %.% is not a table',p_schema,p_table;
  END IF;
  trigger_name := LEFT('trg_domain_event_' || p_schema || '_' || p_table,63);
  -- Excluded on purpose: keep it that way (no trigger, stays disabled).
  IF EXISTS (
    SELECT 1 FROM platform.event_source_registry
    WHERE source_schema=p_schema AND source_table=p_table AND excluded_reason IS NOT NULL
  ) THEN
    EXECUTE format('DROP TRIGGER IF EXISTS %I ON %I.%I',trigger_name,p_schema,p_table);
    RETURN;
  END IF;
  aggregate_name := COALESCE(NULLIF(BTRIM(p_aggregate_type),''),LOWER(p_schema || '.' || p_table));
  INSERT INTO platform.event_source_registry(source_schema,source_table,aggregate_type,enabled)
  VALUES (p_schema,p_table,aggregate_name,TRUE)
  ON CONFLICT (source_schema,source_table) DO UPDATE
    SET aggregate_type=EXCLUDED.aggregate_type,enabled=TRUE;
  EXECUTE format('DROP TRIGGER IF EXISTS %I ON %I.%I',trigger_name,p_schema,p_table);
  EXECUTE format(
    'CREATE TRIGGER %I AFTER INSERT OR UPDATE OR DELETE ON %I.%I FOR EACH ROW EXECUTE FUNCTION platform.capture_row_change(%L)',
    trigger_name,p_schema,p_table,aggregate_name
  );
END;
$$;

CREATE OR REPLACE FUNCTION platform.exclude_event_source(
  p_schema TEXT,
  p_table TEXT,
  p_reason TEXT
) RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
  trigger_name TEXT := LEFT('trg_domain_event_' || p_schema || '_' || p_table,63);
BEGIN
  IF NULLIF(BTRIM(p_reason),'') IS NULL THEN
    RAISE EXCEPTION 'excluding %.% needs a reason',p_schema,p_table;
  END IF;
  INSERT INTO platform.event_source_registry(source_schema,source_table,aggregate_type,enabled,excluded_reason)
  VALUES (p_schema,p_table,LOWER(p_schema || '.' || p_table),FALSE,p_reason)
  ON CONFLICT (source_schema,source_table) DO UPDATE
    SET enabled=FALSE, excluded_reason=EXCLUDED.excluded_reason;
  IF to_regclass(format('%I.%I',p_schema,p_table)) IS NOT NULL THEN
    EXECUTE format('DROP TRIGGER IF EXISTS %I ON %I.%I',trigger_name,p_schema,p_table);
  END IF;
END;
$$;

-- 2. Exclude the amplifying sources -----------------------------------------

SELECT platform.exclude_event_source('matching','activity_events',
  'Request telemetry with its own 90/400-day retention; the member activity log reads it directly. Emitting a row-change event per request flooded the outbox.');
SELECT platform.exclude_event_source('audit','change_log',
  'Audit copy of row changes: an event per audit row duplicates every audited change.');
SELECT platform.exclude_event_source('audit','activity_log',
  'Audit copy of row changes: an event per audit row duplicates every audited change.');

-- 3. Re-apply 125 durably -----------------------------------------------------

CREATE TABLE IF NOT EXISTS audit.trigger_exclusions (
  table_schema TEXT NOT NULL,
  table_name TEXT NOT NULL,
  reason TEXT NOT NULL CHECK (BTRIM(reason) <> ''),
  excluded_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (table_schema, table_name)
);

INSERT INTO audit.trigger_exclusions(table_schema, table_name, reason) VALUES
  ('matching','activity_events',
   'Migration 125 (owner-approved 2026-10-01): request telemetry is not member data change; copies kept IP addresses and paths for 24 months.')
ON CONFLICT (table_schema, table_name) DO NOTHING;

CREATE OR REPLACE FUNCTION audit.attach_audit_triggers(p_schema TEXT)
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
  rec RECORD;
BEGIN
  FOR rec IN
    SELECT t.table_schema, t.table_name,
           EXISTS (SELECT 1 FROM audit.trigger_exclusions x
                   WHERE x.table_schema=t.table_schema AND x.table_name=t.table_name) AS excluded
    FROM information_schema.tables t
    WHERE t.table_type = 'BASE TABLE'
      AND t.table_schema = p_schema
  LOOP
    EXECUTE format('DROP TRIGGER IF EXISTS trg_audit_row_change ON %I.%I', rec.table_schema, rec.table_name);
    IF NOT rec.excluded THEN
      EXECUTE format(
        'CREATE TRIGGER trg_audit_row_change AFTER INSERT OR UPDATE OR DELETE ON %I.%I FOR EACH ROW EXECUTE FUNCTION audit.capture_row_change()',
        rec.table_schema, rec.table_name
      );
    END IF;
  END LOOP;
END;
$$;

DROP TRIGGER IF EXISTS trg_audit_row_change ON matching.activity_events;

-- Changes to the exclusion list are themselves domain events (low volume);
-- this also keeps the event-source coverage check complete.
SELECT platform.register_event_source('audit','trigger_exclusions');

-- 4. Outbox retention ----------------------------------------------------------

INSERT INTO platform.retention_policies(policy_name, relation_name, retention_interval, batch_size)
VALUES ('domain_event_outbox', 'platform.domain_event_outbox', INTERVAL '90 days', 5000)
ON CONFLICT (policy_name) DO NOTHING;

-- Append-only stays: UPDATE is always rejected; DELETE only from inside
-- platform.run_domain_event_retention(), which sets this transaction-local flag.
CREATE OR REPLACE FUNCTION platform.reject_domain_event_mutation() RETURNS TRIGGER
LANGUAGE plpgsql AS $$
BEGIN
  IF TG_OP = 'DELETE' AND current_setting('platform.domain_event_retention', TRUE) = 'on' THEN
    RETURN OLD;
  END IF;
  RAISE EXCEPTION 'domain_event_outbox is append-only; publish a compensating event';
END;
$$;

CREATE OR REPLACE FUNCTION platform.run_domain_event_retention(p_batch_size INTEGER DEFAULT NULL)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
  window_interval INTERVAL;
  policy_batch INTEGER;
  batch INTEGER;
  candidates UUID[];
  removed INTEGER := 0;
BEGIN
  SELECT retention_interval, batch_size INTO window_interval, policy_batch
  FROM platform.retention_policies
  WHERE policy_name = 'domain_event_outbox' AND enabled;
  IF window_interval IS NULL THEN
    RETURN 0;
  END IF;
  batch := LEAST(GREATEST(COALESCE(p_batch_size, policy_batch, 5000), 1), 20000);

  -- Old events no consumer still needs: no delivery pending, retrying,
  -- processing or dead-lettered (dead letters wait for an operator).
  SELECT array_agg(event_id) INTO candidates FROM (
    SELECT o.event_id
    FROM platform.domain_event_outbox o
    WHERE o.occurred_at < NOW() - window_interval
      AND NOT EXISTS (
        SELECT 1 FROM platform.event_deliveries d
        WHERE d.event_id = o.event_id AND d.status <> 'completed'
      )
    ORDER BY o.occurred_at
    LIMIT batch
  ) c;
  IF candidates IS NULL THEN
    RETURN 0;
  END IF;

  PERFORM set_config('platform.domain_event_retention', 'on', TRUE);
  DELETE FROM platform.event_deliveries WHERE event_id = ANY(candidates) AND status = 'completed';
  DELETE FROM platform.domain_event_outbox WHERE event_id = ANY(candidates);
  GET DIAGNOSTICS removed = ROW_COUNT;
  PERFORM set_config('platform.domain_event_retention', 'off', TRUE);
  RETURN removed;
END;
$$;

COMMENT ON FUNCTION platform.run_domain_event_retention(INTEGER) IS
  'Deletes one batch of outbox events older than the domain_event_outbox policy that no consumer still needs. Called hourly by the trust retention worker.';

COMMIT;
