\set ON_ERROR_STOP on

BEGIN;

DO $$
DECLARE
  missing INTEGER;
  event_floor BIGINT;
  captured_name TEXT;
  captured_payload JSONB;
  event_one UUID;
  event_two UUID;
  claimed INTEGER;
  acked BOOLEAN;
  failed_status TEXT;
  conflict_rejected BOOLEAN := FALSE;
  before_rollback BIGINT;
  after_rollback BIGINT;
BEGIN
  SELECT COUNT(*) INTO missing
  FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
  WHERE n.nspname IN ('user_management','matching','progression','audit')
    AND c.relkind IN ('r','p') AND NOT c.relispartition
    AND NOT EXISTS (
      SELECT 1 FROM platform.event_source_registry r
      WHERE r.source_schema=n.nspname AND r.source_table=c.relname AND r.enabled
    );
  IF missing <> 0 THEN
    RAISE EXCEPTION 'unregistered event sources: %',missing;
  END IF;

  SELECT COALESCE(MAX(sequence_id),0) INTO event_floor FROM platform.domain_event_outbox;
  UPDATE matching.platform_feature_flags
     SET updated_at=updated_at
   WHERE key='level_progression_enabled';
  SELECT event_name,payload INTO captured_name,captured_payload
  FROM platform.domain_event_outbox
  WHERE sequence_id>event_floor ORDER BY sequence_id DESC LIMIT 1;
  IF captured_name IS DISTINCT FROM 'matching.platform_feature_flags.updated' THEN
    RAISE EXCEPTION 'generic capture failed: event %',captured_name;
  END IF;
  IF captured_payload ? 'value_bool' OR NOT (captured_payload ? 'changed_fields') THEN
    RAISE EXCEPTION 'generic payload copied row values or omitted field-name metadata';
  END IF;

  event_one := platform.publish_domain_event(
    'architecture.acceptance.completed',1,'architecture','local-gate','qa',
    NULL,NULL,'event-gate',NULL,'event-gate-idempotency',
    '{"result":"passed"}'::JSONB,'{"source":"acceptance"}'::JSONB,NOW());
  event_two := platform.publish_domain_event(
    'architecture.acceptance.completed',1,'architecture','local-gate','qa',
    NULL,NULL,'event-gate',NULL,'event-gate-idempotency',
    '{"result":"passed"}'::JSONB,'{"source":"acceptance"}'::JSONB,NOW());
  IF event_one IS DISTINCT FROM event_two THEN
    RAISE EXCEPTION 'idempotent event publication failed';
  END IF;
  BEGIN
    PERFORM platform.publish_domain_event(
      'architecture.acceptance.completed',1,'architecture','local-gate','qa',
      NULL,NULL,'event-gate',NULL,'event-gate-idempotency',
      '{"result":"different"}'::JSONB,'{"source":"acceptance"}'::JSONB,NOW());
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM='domain event idempotency key reused with different content' THEN
      conflict_rejected := TRUE;
    ELSE
      RAISE;
    END IF;
  END;
  IF NOT conflict_rejected THEN
    RAISE EXCEPTION 'conflicting idempotent event was accepted';
  END IF;

  INSERT INTO platform.event_subscriptions(consumer_name,event_pattern,max_attempts)
  VALUES ('architecture-gate','architecture.*',3);
  SELECT COUNT(*) INTO claimed
  FROM platform.claim_domain_events('architecture-gate','gate-worker',10,30);
  IF claimed <> 1 THEN RAISE EXCEPTION 'expected one claim, got %',claimed; END IF;
  SELECT platform.ack_domain_event('architecture-gate',event_one,'gate-worker') INTO acked;
  IF NOT acked THEN RAISE EXCEPTION 'event acknowledgement failed'; END IF;

  INSERT INTO platform.event_subscriptions(consumer_name,event_pattern,max_attempts)
  VALUES ('architecture-dead-letter-gate','architecture.*',1);
  SELECT COUNT(*) INTO claimed
  FROM platform.claim_domain_events('architecture-dead-letter-gate','failure-worker',10,30);
  IF claimed <> 1 THEN RAISE EXCEPTION 'expected one failure claim, got %',claimed; END IF;
  SELECT platform.nack_domain_event(
    'architecture-dead-letter-gate',event_one,'failure-worker','forced acceptance failure'
  ) INTO failed_status;
  IF failed_status IS DISTINCT FROM 'dead_letter' THEN
    RAISE EXCEPTION 'dead-letter transition failed: %',failed_status;
  END IF;

  SELECT COUNT(*) INTO before_rollback FROM platform.domain_event_outbox;
  BEGIN
    UPDATE matching.platform_feature_flags
       SET updated_at=clock_timestamp()
     WHERE key='level_progression_enabled';
    RAISE EXCEPTION 'force source transaction rollback';
  EXCEPTION WHEN OTHERS THEN
    NULL;
  END;
  SELECT COUNT(*) INTO after_rollback FROM platform.domain_event_outbox;
  IF after_rollback <> before_rollback THEN
    RAISE EXCEPTION 'event escaped rolled-back source transaction';
  END IF;

  RAISE NOTICE 'event architecture passed: sources %, event %, idempotent %, conflict %, ack %, dead-letter %',
    (SELECT COUNT(*) FROM platform.event_source_registry WHERE enabled),
    captured_name,event_one,conflict_rejected,acked,failed_status;
END $$;

ROLLBACK;
