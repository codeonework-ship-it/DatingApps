BEGIN;

CREATE SCHEMA IF NOT EXISTS platform;
CREATE SCHEMA IF NOT EXISTS progression;

-- A replay cursor is only useful while the referenced history still exists.
-- Keep a durable high-water mark whenever retained rows are pruned so every
-- BFF instance makes the same expiry decision after a restart or failover.
CREATE TABLE IF NOT EXISTS platform.replay_cursor_checkpoints (
  stream_name TEXT NOT NULL CHECK (stream_name IN ('chat','notifications')),
  recipient_user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  pruned_through_sequence BIGINT NOT NULL CHECK (pruned_through_sequence >= 0),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (stream_name,recipient_user_id)
);

CREATE OR REPLACE FUNCTION platform.capture_pruned_replay_cursor()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE stream_key TEXT := TG_ARGV[0];
BEGIN
  INSERT INTO platform.replay_cursor_checkpoints(
    stream_name,recipient_user_id,pruned_through_sequence,updated_at
  ) VALUES (stream_key,OLD.recipient_user_id,OLD.sequence_id,NOW())
  ON CONFLICT (stream_name,recipient_user_id) DO UPDATE SET
    pruned_through_sequence=GREATEST(
      platform.replay_cursor_checkpoints.pruned_through_sequence,
      EXCLUDED.pruned_through_sequence
    ),
    updated_at=NOW();
  RETURN OLD;
END;
$$;

DROP TRIGGER IF EXISTS trg_realtime_cursor_checkpoint ON matching.realtime_outbox;
CREATE TRIGGER trg_realtime_cursor_checkpoint
BEFORE DELETE ON matching.realtime_outbox
FOR EACH ROW EXECUTE FUNCTION platform.capture_pruned_replay_cursor('chat');

DROP TRIGGER IF EXISTS trg_notification_cursor_checkpoint ON matching.notification_outbox;
CREATE TRIGGER trg_notification_cursor_checkpoint
BEFORE DELETE ON matching.notification_outbox
FOR EACH ROW EXECUTE FUNCTION platform.capture_pruned_replay_cursor('notifications');

-- Product actions and XP awards are deliberately decoupled. If the product
-- transaction commits while the XP write is temporarily unavailable, retain
-- the exact award command and let any projection worker repair it.
CREATE TABLE IF NOT EXISTS progression.xp_award_repair_queue (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  source TEXT NOT NULL REFERENCES progression.xp_source_policies(source),
  source_event_id TEXT,
  idempotency_key TEXT NOT NULL CHECK (length(idempotency_key) BETWEEN 1 AND 255),
  input JSONB NOT NULL CHECK (jsonb_typeof(input)='object'),
  status TEXT NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending','processing','retry','completed','suppressed','dead_letter')),
  attempt_count INTEGER NOT NULL DEFAULT 0 CHECK (attempt_count >= 0),
  available_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  locked_at TIMESTAMPTZ,
  worker_id TEXT,
  last_error TEXT,
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id,idempotency_key)
);
CREATE INDEX IF NOT EXISTS idx_xp_award_repair_claim
  ON progression.xp_award_repair_queue(available_at,id)
  INCLUDE (user_id,source,source_event_id,attempt_count)
  WHERE status IN ('pending','retry');

-- Aggregate ownership is an executable architecture contract. A table has one
-- write owner and one documented transaction boundary; reviews and release
-- gates can now detect accidental shared ownership instead of relying on prose.
CREATE TABLE IF NOT EXISTS platform.aggregate_ownership (
  aggregate_type TEXT PRIMARY KEY,
  owner_component TEXT NOT NULL,
  source_schema TEXT NOT NULL,
  source_table TEXT NOT NULL,
  transaction_boundary TEXT NOT NULL,
  recovery_strategy TEXT NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(source_schema,source_table)
);

INSERT INTO platform.aggregate_ownership(
  aggregate_type,owner_component,source_schema,source_table,transaction_boundary,recovery_strategy
) VALUES
  ('identity.user','auth/profile','user_management','users','single PostgreSQL transaction','idempotent command replay'),
  ('profile.photo','profile','user_management','photos','single PostgreSQL transaction','content digest plus moderation ledger'),
  ('matching.match','matching','matching','matches','single PostgreSQL transaction','domain event replay'),
  ('messaging.message','chat','matching','messages','single PostgreSQL transaction','realtime snapshot then cursor resume'),
  ('notifications.delivery','notifications','matching','notification_outbox','transactional outbox','lease recovery and dead letter'),
  ('progression.xp','progression','progression','xp_ledger','ledger plus projection outbox transaction','award repair queue and projection rebuild'),
  ('safety.sos','safety','matching','sos_alerts','single PostgreSQL transaction','delivery retry and escalation')
ON CONFLICT (aggregate_type) DO UPDATE SET
  owner_component=EXCLUDED.owner_component,
  source_schema=EXCLUDED.source_schema,
  source_table=EXCLUDED.source_table,
  transaction_boundary=EXCLUDED.transaction_boundary,
  recovery_strategy=EXCLUDED.recovery_strategy,
  updated_at=NOW();

CREATE OR REPLACE VIEW platform.aggregate_ownership_health AS
SELECT
  COUNT(*) AS declared_aggregates,
  COUNT(*) FILTER (WHERE c.oid IS NULL) AS missing_relations,
  COALESCE(array_agg(o.aggregate_type ORDER BY o.aggregate_type)
    FILTER (WHERE c.oid IS NULL),'{}'::TEXT[]) AS invalid_aggregates
FROM platform.aggregate_ownership o
LEFT JOIN pg_namespace n ON n.nspname=o.source_schema
LEFT JOIN pg_class c ON c.relnamespace=n.oid AND c.relname=o.source_table
  AND c.relkind IN ('r','p');

INSERT INTO public.schema_migrations(version)
VALUES ('078_correctness_recovery_contracts')
ON CONFLICT (version) DO UPDATE SET applied_at=EXCLUDED.applied_at;

COMMIT;
