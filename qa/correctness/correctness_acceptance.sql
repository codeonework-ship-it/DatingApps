\set ON_ERROR_STOP on

DO $$
DECLARE
  declared_count BIGINT;
  missing_count BIGINT;
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.schema_migrations
    WHERE version='078_correctness_recovery_contracts'
  ) THEN
    RAISE EXCEPTION 'correctness recovery migration is not recorded';
  END IF;

  SELECT declared_aggregates,missing_relations
    INTO declared_count,missing_count
  FROM platform.aggregate_ownership_health;
  IF declared_count < 7 OR missing_count <> 0 THEN
    RAISE EXCEPTION 'aggregate ownership is incomplete: declared %, missing %', declared_count,missing_count;
  END IF;

  IF to_regclass('platform.replay_cursor_checkpoints') IS NULL
     OR to_regclass('progression.xp_award_repair_queue') IS NULL THEN
    RAISE EXCEPTION 'cursor or XP recovery persistence is missing';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname='trg_realtime_cursor_checkpoint' AND tgenabled<>'D')
     OR NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname='trg_notification_cursor_checkpoint' AND tgenabled<>'D') THEN
    RAISE EXCEPTION 'cursor retention checkpoints are not active';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes
    WHERE schemaname='progression' AND indexname='idx_xp_award_repair_claim'
  ) THEN
    RAISE EXCEPTION 'XP repair claim index is missing';
  END IF;
END
$$;

SELECT 'correctness recovery acceptance passed' AS result;

BEGIN;
DO $$
DECLARE
  test_user UUID;
  test_sequence BIGINT;
  checkpoint BIGINT;
BEGIN
  SELECT id INTO test_user FROM user_management.users ORDER BY created_at LIMIT 1;
  IF test_user IS NULL THEN
    RAISE EXCEPTION 'a local fixture user is required for recovery acceptance';
  END IF;

  INSERT INTO matching.realtime_outbox(recipient_user_id,event_type,payload)
  VALUES (test_user,'message.created','{"acceptance":"cursor_checkpoint"}'::JSONB)
  RETURNING sequence_id INTO test_sequence;
  DELETE FROM matching.realtime_outbox WHERE sequence_id=test_sequence;
  SELECT pruned_through_sequence INTO checkpoint
  FROM platform.replay_cursor_checkpoints
  WHERE stream_name='chat' AND recipient_user_id=test_user;
  IF checkpoint IS NULL OR checkpoint < test_sequence THEN
    RAISE EXCEPTION 'cursor checkpoint did not advance';
  END IF;

  INSERT INTO progression.xp_award_repair_queue(
    user_id,source,source_event_id,idempotency_key,input,last_error
  ) VALUES (
    test_user,'profile_completed','correctness-gate','correctness-gate:' || test_user,
    jsonb_build_object(
      'user_id',test_user,'source','profile_completed',
      'source_event_id','correctness-gate','idempotency_key','correctness-gate:' || test_user
    ),'acceptance injection'
  );
  IF NOT EXISTS (
    SELECT 1 FROM progression.xp_award_repair_queue
    WHERE user_id=test_user AND idempotency_key='correctness-gate:' || test_user
      AND status='pending'
  ) THEN
    RAISE EXCEPTION 'XP repair command was not durable';
  END IF;
END
$$;
ROLLBACK;
