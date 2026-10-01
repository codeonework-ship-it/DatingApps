BEGIN;

CREATE SCHEMA IF NOT EXISTS platform;

-- Canonical, append-only event envelope shared by every product domain. Rows
-- are inserted in the same transaction as the state change that produced them,
-- so a committed command cannot lose its event during a process crash.
CREATE TABLE IF NOT EXISTS platform.domain_event_outbox (
  sequence_id BIGINT GENERATED ALWAYS AS IDENTITY UNIQUE,
  event_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_name TEXT NOT NULL,
  event_version SMALLINT NOT NULL DEFAULT 1 CHECK (event_version > 0),
  aggregate_type TEXT NOT NULL,
  aggregate_id TEXT NOT NULL,
  producer TEXT NOT NULL,
  subject_user_id UUID,
  actor_user_id UUID,
  correlation_id TEXT,
  causation_id UUID,
  idempotency_key TEXT,
  payload JSONB NOT NULL DEFAULT '{}'::JSONB CHECK (jsonb_typeof(payload) = 'object'),
  metadata JSONB NOT NULL DEFAULT '{}'::JSONB CHECK (jsonb_typeof(metadata) = 'object'),
  occurred_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
  CHECK (event_name ~ '^[a-z0-9]+([._-][a-z0-9]+)+$'),
  CHECK (octet_length(payload::TEXT) <= 65536),
  CHECK (octet_length(metadata::TEXT) <= 16384)
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_domain_event_idempotency
  ON platform.domain_event_outbox(producer,event_name,idempotency_key)
  WHERE idempotency_key IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_domain_event_sequence
  ON platform.domain_event_outbox(sequence_id);
CREATE INDEX IF NOT EXISTS idx_domain_event_name_sequence
  ON platform.domain_event_outbox(event_name,sequence_id DESC);
CREATE INDEX IF NOT EXISTS idx_domain_event_aggregate_sequence
  ON platform.domain_event_outbox(aggregate_type,aggregate_id,sequence_id DESC);
CREATE INDEX IF NOT EXISTS idx_domain_event_subject_sequence
  ON platform.domain_event_outbox(subject_user_id,sequence_id DESC)
  WHERE subject_user_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_domain_event_occurred
  ON platform.domain_event_outbox(occurred_at DESC);

CREATE OR REPLACE FUNCTION platform.reject_domain_event_mutation() RETURNS TRIGGER
LANGUAGE plpgsql AS $$
BEGIN
  RAISE EXCEPTION 'domain_event_outbox is append-only; publish a compensating event';
END;
$$;
DROP TRIGGER IF EXISTS trg_domain_event_append_only ON platform.domain_event_outbox;
CREATE TRIGGER trg_domain_event_append_only
BEFORE UPDATE OR DELETE ON platform.domain_event_outbox
FOR EACH ROW EXECUTE FUNCTION platform.reject_domain_event_mutation();

DROP FUNCTION IF EXISTS platform.publish_domain_event(
  TEXT,SMALLINT,TEXT,TEXT,TEXT,UUID,UUID,TEXT,UUID,TEXT,JSONB,JSONB,TIMESTAMPTZ
);
CREATE OR REPLACE FUNCTION platform.publish_domain_event(
  p_event_name TEXT,
  p_event_version INTEGER,
  p_aggregate_type TEXT,
  p_aggregate_id TEXT,
  p_producer TEXT,
  p_subject_user_id UUID DEFAULT NULL,
  p_actor_user_id UUID DEFAULT NULL,
  p_correlation_id TEXT DEFAULT NULL,
  p_causation_id UUID DEFAULT NULL,
  p_idempotency_key TEXT DEFAULT NULL,
  p_payload JSONB DEFAULT '{}'::JSONB,
  p_metadata JSONB DEFAULT '{}'::JSONB,
  p_occurred_at TIMESTAMPTZ DEFAULT clock_timestamp()
) RETURNS UUID
LANGUAGE plpgsql
AS $$
DECLARE
  published_id UUID;
  published_sequence BIGINT;
  stored_version SMALLINT;
  stored_aggregate_type TEXT;
  stored_aggregate_id TEXT;
  stored_subject_user_id UUID;
  stored_actor_user_id UUID;
  stored_correlation_id TEXT;
  stored_causation_id UUID;
  stored_payload JSONB;
  stored_metadata JSONB;
BEGIN
  IF COALESCE(BTRIM(p_event_name),'') !~ '^[a-z0-9]+([._-][a-z0-9]+)+$' THEN
    RAISE EXCEPTION 'invalid domain event name: %', p_event_name;
  END IF;
  IF p_event_version IS NULL OR p_event_version < 1 THEN
    RAISE EXCEPTION 'event version must be positive';
  END IF;
  IF COALESCE(BTRIM(p_aggregate_type),'') = '' OR COALESCE(BTRIM(p_aggregate_id),'') = '' THEN
    RAISE EXCEPTION 'aggregate type and id are required';
  END IF;
  IF COALESCE(BTRIM(p_producer),'') = '' THEN
    RAISE EXCEPTION 'event producer is required';
  END IF;

  INSERT INTO platform.domain_event_outbox(
    event_name,event_version,aggregate_type,aggregate_id,producer,
    subject_user_id,actor_user_id,correlation_id,causation_id,idempotency_key,
    payload,metadata,occurred_at
  ) VALUES (
    p_event_name,p_event_version,p_aggregate_type,p_aggregate_id,p_producer,
    p_subject_user_id,p_actor_user_id,NULLIF(BTRIM(p_correlation_id),''),p_causation_id,
    NULLIF(BTRIM(p_idempotency_key),''),COALESCE(p_payload,'{}'::JSONB),
    COALESCE(p_metadata,'{}'::JSONB),COALESCE(p_occurred_at,clock_timestamp())
  )
  ON CONFLICT (producer,event_name,idempotency_key)
    WHERE idempotency_key IS NOT NULL
  DO NOTHING
  RETURNING event_id,sequence_id INTO published_id,published_sequence;

  IF published_id IS NULL AND NULLIF(BTRIM(p_idempotency_key),'') IS NOT NULL THEN
    SELECT event_id,sequence_id,event_version,aggregate_type,aggregate_id,
           subject_user_id,actor_user_id,correlation_id,causation_id,payload,metadata
      INTO published_id,published_sequence,stored_version,stored_aggregate_type,
           stored_aggregate_id,stored_subject_user_id,stored_actor_user_id,
           stored_correlation_id,stored_causation_id,stored_payload,stored_metadata
    FROM platform.domain_event_outbox
    WHERE producer=p_producer AND event_name=p_event_name
      AND idempotency_key=NULLIF(BTRIM(p_idempotency_key),'');
    IF stored_version IS DISTINCT FROM p_event_version
       OR stored_aggregate_type IS DISTINCT FROM p_aggregate_type
       OR stored_aggregate_id IS DISTINCT FROM p_aggregate_id
       OR stored_subject_user_id IS DISTINCT FROM p_subject_user_id
       OR stored_actor_user_id IS DISTINCT FROM p_actor_user_id
       OR stored_correlation_id IS DISTINCT FROM NULLIF(BTRIM(p_correlation_id),'')
       OR stored_causation_id IS DISTINCT FROM p_causation_id
       OR stored_payload IS DISTINCT FROM COALESCE(p_payload,'{}'::JSONB)
       OR stored_metadata IS DISTINCT FROM COALESCE(p_metadata,'{}'::JSONB) THEN
      RAISE EXCEPTION 'domain event idempotency key reused with different content';
    END IF;
  END IF;

  -- NOTIFY is a low-latency hint only. Durable consumers always read the
  -- outbox by sequence and therefore recover events missed while offline.
  PERFORM pg_notify('domain_events',json_build_object(
    'event_id',published_id,'sequence_id',published_sequence,'event_name',p_event_name
  )::TEXT);
  RETURN published_id;
END;
$$;

CREATE TABLE IF NOT EXISTS platform.event_source_registry (
  source_schema TEXT NOT NULL,
  source_table TEXT NOT NULL,
  aggregate_type TEXT NOT NULL,
  enabled BOOLEAN NOT NULL DEFAULT TRUE,
  payload_policy TEXT NOT NULL DEFAULT 'field_names_only'
    CHECK (payload_policy = 'field_names_only'),
  registered_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY(source_schema,source_table)
);

-- Generic capture is a privacy-safe safety net. It records the operation and
-- changed field names, never row values. Features may additionally publish a
-- richer semantic event through publish_domain_event in the same transaction.
CREATE OR REPLACE FUNCTION platform.capture_row_change() RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  new_doc JSONB := CASE WHEN TG_OP = 'DELETE' THEN '{}'::JSONB ELSE to_jsonb(NEW) END;
  old_doc JSONB := CASE WHEN TG_OP = 'INSERT' THEN '{}'::JSONB ELSE to_jsonb(OLD) END;
  source_doc JSONB;
  changed_fields JSONB;
  aggregate_id TEXT;
  subject_text TEXT;
  actor_text TEXT;
  actor_id UUID;
  subject_id UUID;
  correlation TEXT;
  event_suffix TEXT;
BEGIN
  source_doc := CASE WHEN TG_OP = 'DELETE' THEN old_doc ELSE new_doc END;
  aggregate_id := COALESCE(
    source_doc->>'id',source_doc->>'user_id',source_doc->>'match_id',
    source_doc->>'key',source_doc->>'source',source_doc->>'sequence_id',
    'tx-' || txid_current()::TEXT
  );
  subject_text := COALESCE(
    source_doc->>'user_id',source_doc->>'recipient_user_id',
    source_doc->>'target_user_id',source_doc->>'subject_user_id',
    CASE WHEN TG_TABLE_SCHEMA='user_management' AND TG_TABLE_NAME='users' THEN source_doc->>'id' END
  );
  IF COALESCE(subject_text,'') ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' THEN
    subject_id := subject_text::UUID;
  END IF;
  actor_text := NULLIF(current_setting('app.actor_user_id',TRUE),'');
  IF COALESCE(actor_text,'') ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' THEN
    actor_id := actor_text::UUID;
  END IF;
  correlation := NULLIF(current_setting('app.correlation_id',TRUE),'');

  SELECT COALESCE(jsonb_agg(field_name ORDER BY field_name),'[]'::JSONB)
    INTO changed_fields
  FROM (
    SELECT key AS field_name
    FROM jsonb_object_keys(new_doc || old_doc) AS fields(key)
    WHERE new_doc->key IS DISTINCT FROM old_doc->key
  ) changed;

  event_suffix := CASE TG_OP WHEN 'INSERT' THEN 'created' WHEN 'UPDATE' THEN 'updated' ELSE 'deleted' END;
  PERFORM platform.publish_domain_event(
    LOWER(TG_TABLE_SCHEMA || '.' || TG_TABLE_NAME || '.' || event_suffix),
    1,
    COALESCE(NULLIF(TG_ARGV[0],''),LOWER(TG_TABLE_SCHEMA || '.' || TG_TABLE_NAME)),
    aggregate_id,
    LOWER(TG_TABLE_SCHEMA),
    subject_id,
    actor_id,
    correlation,
    NULL,
    NULL,
    jsonb_build_object(
      'operation',LOWER(TG_OP),
      'changed_fields',changed_fields,
      'transaction_id',txid_current()
    ),
    jsonb_build_object('source','database_trigger','table',TG_TABLE_SCHEMA || '.' || TG_TABLE_NAME)
  );
  RETURN CASE WHEN TG_OP = 'DELETE' THEN OLD ELSE NEW END;
END;
$$;

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
  aggregate_name := COALESCE(NULLIF(BTRIM(p_aggregate_type),''),LOWER(p_schema || '.' || p_table));
  INSERT INTO platform.event_source_registry(source_schema,source_table,aggregate_type,enabled)
  VALUES (p_schema,p_table,aggregate_name,TRUE)
  ON CONFLICT (source_schema,source_table) DO UPDATE
    SET aggregate_type=EXCLUDED.aggregate_type,enabled=TRUE;
  trigger_name := LEFT('trg_domain_event_' || p_schema || '_' || p_table,63);
  EXECUTE format('DROP TRIGGER IF EXISTS %I ON %I.%I',trigger_name,p_schema,p_table);
  EXECUTE format(
    'CREATE TRIGGER %I AFTER INSERT OR UPDATE OR DELETE ON %I.%I FOR EACH ROW EXECUTE FUNCTION platform.capture_row_change(%L)',
    trigger_name,p_schema,p_table,aggregate_name
  );
END;
$$;

-- Register every mutable product table that exists at this migration boundary.
-- Event-infrastructure tables live in platform and cannot recurse into the log.
DO $$
DECLARE source RECORD;
BEGIN
  FOR source IN
    SELECT n.nspname AS schema_name,c.relname AS table_name
    FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
    WHERE n.nspname IN ('user_management','matching','progression','audit')
      AND c.relkind IN ('r','p')
      AND NOT c.relispartition
    ORDER BY n.nspname,c.relname
  LOOP
    PERFORM platform.register_event_source(source.schema_name,source.table_name);
  END LOOP;
END;
$$;

CREATE TABLE IF NOT EXISTS platform.event_subscriptions (
  consumer_name TEXT NOT NULL,
  event_pattern TEXT NOT NULL,
  enabled BOOLEAN NOT NULL DEFAULT TRUE,
  max_attempts SMALLINT NOT NULL DEFAULT 8 CHECK (max_attempts BETWEEN 1 AND 25),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY(consumer_name,event_pattern),
  CHECK (consumer_name ~ '^[a-z0-9][a-z0-9._-]+$'),
  CHECK (event_pattern ~ '^[a-z0-9*]+([._-][a-z0-9*]+)+$')
);

CREATE TABLE IF NOT EXISTS platform.event_deliveries (
  consumer_name TEXT NOT NULL,
  event_id UUID NOT NULL REFERENCES platform.domain_event_outbox(event_id) ON DELETE RESTRICT,
  sequence_id BIGINT NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending','processing','retry','completed','dead_letter')),
  attempt_count INTEGER NOT NULL DEFAULT 0 CHECK (attempt_count >= 0),
  max_attempts SMALLINT NOT NULL CHECK (max_attempts BETWEEN 1 AND 25),
  available_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  locked_at TIMESTAMPTZ,
  worker_id TEXT,
  last_error TEXT,
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY(consumer_name,event_id)
);
CREATE INDEX IF NOT EXISTS idx_event_delivery_claim
  ON platform.event_deliveries(consumer_name,available_at,sequence_id)
  WHERE status IN ('pending','retry','processing');
CREATE INDEX IF NOT EXISTS idx_event_delivery_dead_letter
  ON platform.event_deliveries(consumer_name,sequence_id DESC)
  WHERE status='dead_letter';

CREATE OR REPLACE FUNCTION platform.claim_domain_events(
  p_consumer TEXT,
  p_worker TEXT,
  p_limit INTEGER DEFAULT 50,
  p_lease_seconds INTEGER DEFAULT 30
) RETURNS SETOF platform.domain_event_outbox
LANGUAGE plpgsql
AS $$
BEGIN
  IF COALESCE(BTRIM(p_consumer),'')='' OR COALESCE(BTRIM(p_worker),'')='' THEN
    RAISE EXCEPTION 'consumer and worker are required';
  END IF;

  INSERT INTO platform.event_deliveries(consumer_name,event_id,sequence_id,max_attempts)
  SELECT p_consumer,e.event_id,e.sequence_id,s.max_attempts
  FROM platform.domain_event_outbox e
  JOIN platform.event_subscriptions s
    ON s.consumer_name=p_consumer AND s.enabled
   AND e.event_name LIKE REPLACE(s.event_pattern,'*','%')
  WHERE NOT EXISTS (
    SELECT 1 FROM platform.event_deliveries d
    WHERE d.consumer_name=p_consumer AND d.event_id=e.event_id
  )
  ORDER BY e.sequence_id
  LIMIT GREATEST(1,LEAST(p_limit,500))
  ON CONFLICT DO NOTHING;

  RETURN QUERY
  WITH candidates AS (
    SELECT d.consumer_name,d.event_id
    FROM platform.event_deliveries d
    WHERE d.consumer_name=p_consumer
      AND (
        d.status IN ('pending','retry') AND d.available_at<=NOW()
        OR d.status='processing' AND d.locked_at<NOW()-make_interval(secs=>GREATEST(5,p_lease_seconds))
      )
    ORDER BY d.sequence_id
    LIMIT GREATEST(1,LEAST(p_limit,500))
    FOR UPDATE SKIP LOCKED
  ), claimed AS (
    UPDATE platform.event_deliveries d
       SET status='processing',attempt_count=d.attempt_count+1,locked_at=NOW(),
           worker_id=p_worker,updated_at=NOW()
    FROM candidates c
    WHERE d.consumer_name=c.consumer_name AND d.event_id=c.event_id
    RETURNING d.event_id
  )
  SELECT e.* FROM platform.domain_event_outbox e
  JOIN claimed c ON c.event_id=e.event_id
  ORDER BY e.sequence_id;
END;
$$;

CREATE OR REPLACE FUNCTION platform.ack_domain_event(
  p_consumer TEXT,p_event_id UUID,p_worker TEXT
) RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE affected INTEGER;
BEGIN
  UPDATE platform.event_deliveries
     SET status='completed',completed_at=NOW(),locked_at=NULL,worker_id=NULL,
         last_error=NULL,updated_at=NOW()
   WHERE consumer_name=p_consumer AND event_id=p_event_id
     AND status='processing' AND worker_id=p_worker;
  GET DIAGNOSTICS affected=ROW_COUNT;
  RETURN affected=1;
END;
$$;

CREATE OR REPLACE FUNCTION platform.nack_domain_event(
  p_consumer TEXT,p_event_id UUID,p_worker TEXT,p_error TEXT
) RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE final_status TEXT;
BEGIN
  UPDATE platform.event_deliveries
     SET status=CASE WHEN attempt_count>=max_attempts THEN 'dead_letter' ELSE 'retry' END,
         available_at=CASE WHEN attempt_count>=max_attempts THEN available_at
           ELSE NOW()+make_interval(secs=>LEAST(900,(POWER(2,LEAST(attempt_count,9)))::INTEGER)) END,
         locked_at=NULL,worker_id=NULL,last_error=LEFT(COALESCE(p_error,'consumer failure'),2000),
         updated_at=NOW()
   WHERE consumer_name=p_consumer AND event_id=p_event_id
     AND status='processing' AND worker_id=p_worker
  RETURNING status INTO final_status;
  RETURN final_status;
END;
$$;

CREATE OR REPLACE VIEW platform.domain_event_pipeline_metrics AS
SELECT
  (SELECT COUNT(*) FROM platform.domain_event_outbox) AS total_events,
  (SELECT COUNT(*) FROM platform.domain_event_outbox WHERE occurred_at>=NOW()-INTERVAL '15 minutes') AS events_15m,
  COUNT(*) FILTER (WHERE status IN ('pending','retry')) AS pending_deliveries,
  COUNT(*) FILTER (WHERE status='processing') AS processing_deliveries,
  COUNT(*) FILTER (WHERE status='dead_letter') AS dead_letters,
  COALESCE(EXTRACT(EPOCH FROM NOW()-MIN(created_at) FILTER (WHERE status IN ('pending','retry'))),0)::BIGINT
    AS oldest_pending_age_seconds
FROM platform.event_deliveries;

INSERT INTO public.schema_migrations(version)
VALUES ('075_domain_event_backbone')
ON CONFLICT (version) DO UPDATE SET applied_at=EXCLUDED.applied_at;

COMMIT;
