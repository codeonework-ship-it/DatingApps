#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
database_url="${LOCAL_DATABASE_URL:-postgresql://dating_app@127.0.0.1:55433/dating_app?sslmode=disable}"
psql_bin="${PSQL_BIN:-/opt/homebrew/opt/postgresql@17/bin/psql}"

"$psql_bin" "$database_url" -X -v ON_ERROR_STOP=1 <<'SQL'
DO $$
DECLARE
  module_count INTEGER;
  source_count INTEGER;
  unsafe_flag_count INTEGER;
  support_enabled BOOLEAN;
  precise_location_columns INTEGER;
BEGIN
  SELECT COUNT(*) INTO module_count FROM growth.portfolio_modules;
  IF module_count <> 11 THEN
    RAISE EXCEPTION 'expected 11 governed growth modules, got %', module_count;
  END IF;

  SELECT COUNT(*) INTO source_count
  FROM platform.event_source_registry
  WHERE source_schema='growth' AND enabled;
  IF source_count <> 14 THEN
    RAISE EXCEPTION 'expected 14 event-backed growth tables, got %', source_count;
  END IF;

  SELECT value_bool INTO support_enabled
  FROM matching.platform_feature_flags WHERE key='support_ticketing_enabled';
  IF support_enabled IS DISTINCT FROM TRUE THEN
    RAISE EXCEPTION 'support ticketing must be enabled after local acceptance';
  END IF;

  SELECT COUNT(*) INTO unsafe_flag_count
  FROM matching.platform_feature_flags
  WHERE key IN (
    'referrals_enabled','growth_events_enabled','partnerships_enabled',
    'social_imports_enabled','member_history_enabled',
    'recommendation_graph_enabled','fraud_graph_enabled',
    'admirer_gifts_enabled','expanded_gift_economy_enabled','paid_xp_enabled'
  ) AND value_bool;
  IF unsafe_flag_count <> 0 THEN
    RAISE EXCEPTION 'sensitive or monetized growth flags must default off';
  END IF;

  SELECT COUNT(*) INTO precise_location_columns
  FROM information_schema.columns
  WHERE table_schema='growth' AND table_name='location_checkins'
    AND column_name IN ('latitude','longitude','accuracy','address');
  IF precise_location_columns <> 0 THEN
    RAISE EXCEPTION 'location history contains prohibited precise-location columns';
  END IF;
END $$;

BEGIN;
DO $$
DECLARE
  member UUID;
  ticket UUID;
  event_count INTEGER;
BEGIN
  SELECT id INTO member FROM user_management.users ORDER BY created_at LIMIT 1;
  IF member IS NULL THEN
    RAISE EXCEPTION 'local acceptance fixture has no member';
  END IF;

  INSERT INTO growth.support_tickets(
    member_id,category,priority,subject,first_response_due_at,resolution_due_at,
    idempotency_key,request_hash
  ) VALUES (
    member,'technical','normal','Growth acceptance ticket',NOW()+INTERVAL '4 hours',
    NOW()+INTERVAL '24 hours','growth-acceptance','acceptance-hash'
  ) RETURNING id INTO ticket;
  INSERT INTO growth.support_ticket_messages(
    ticket_id,author_id,author_role,body,idempotency_key
  ) VALUES(ticket,member,'member','Acceptance message','growth-acceptance-message');
  INSERT INTO growth.support_ticket_events(ticket_id,event_type,actor_id,payload)
  VALUES(ticket,'ticket.created',member,'{}');

  SELECT COUNT(*) INTO event_count
  FROM platform.domain_event_outbox
  WHERE aggregate_id IN (ticket::TEXT)
     OR (aggregate_type='growth.support_ticket_messages'
         AND payload->>'transaction_id'=txid_current()::TEXT);
  IF event_count < 1 THEN
    RAISE EXCEPTION 'support mutation did not reach the domain event outbox';
  END IF;

  BEGIN
    UPDATE growth.support_ticket_events SET event_type='tampered' WHERE ticket_id=ticket;
    RAISE EXCEPTION 'support audit event accepted an update';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM NOT LIKE '%append-only%' THEN RAISE; END IF;
  END;
END $$;
ROLLBACK;

SELECT 'deferred growth portfolio acceptance: PASS' AS result;
SQL
