\set ON_ERROR_STOP on
\if :{?scale_rows}
\else
  \set scale_rows 250000
\endif

SET statement_timeout = '120s';
SET lock_timeout = '2s';

CREATE TEMP TABLE scale_messages (
  id UUID NOT NULL,
  match_id UUID NOT NULL,
  sender_id UUID NOT NULL,
  text TEXT NOT NULL,
  delivered_at TIMESTAMPTZ,
  read_at TIMESTAMPTZ,
  is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL
);
CREATE INDEX scale_messages_timeline_cover
  ON scale_messages(match_id, created_at DESC, id)
  INCLUDE (sender_id, text, delivered_at, read_at)
  WHERE is_deleted = FALSE;

INSERT INTO scale_messages
SELECT md5('message-' || g)::UUID,
       md5('match-' || (g % 10000))::UUID,
       md5('sender-' || (g % 100000))::UUID,
       'production-cardinality message ' || g,
       NOW(), NULL, FALSE, NOW() - (g * INTERVAL '1 millisecond')
FROM generate_series(1, :scale_rows) AS g;
ANALYZE scale_messages;

\echo PLAN_CHAT_RESUME
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT id,sender_id,text,delivered_at,read_at,created_at
FROM scale_messages
WHERE match_id=md5('match-42')::UUID AND is_deleted=FALSE
ORDER BY created_at DESC,id
LIMIT 50;

CREATE TEMP TABLE scale_notification_outbox (
  sequence_id BIGINT NOT NULL,
  id UUID NOT NULL,
  recipient_user_id UUID NOT NULL,
  event_type TEXT NOT NULL,
  category TEXT NOT NULL,
  priority SMALLINT NOT NULL,
  status TEXT NOT NULL,
  available_at TIMESTAMPTZ NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  attempt_count INTEGER NOT NULL,
  max_attempts INTEGER NOT NULL
);
CREATE INDEX scale_notification_claim_cover
  ON scale_notification_outbox(priority DESC, available_at, expires_at, sequence_id)
  INCLUDE (id, recipient_user_id, event_type, category, attempt_count, max_attempts)
  WHERE status IN ('pending','retry');

INSERT INTO scale_notification_outbox
SELECT g,md5('notification-' || g)::UUID,md5('recipient-' || (g % 100000))::UUID,
       'message.created','message',(g % 10)::SMALLINT,
       CASE WHEN g % 20=0 THEN 'pending' ELSE 'delivered' END,
       NOW() - (g * INTERVAL '1 millisecond'),NOW()+INTERVAL '30 days',0,5
FROM generate_series(1, :scale_rows) AS g;
ANALYZE scale_notification_outbox;

\echo PLAN_NOTIFICATION_CLAIM
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT id
FROM scale_notification_outbox
WHERE status IN ('pending','retry') AND available_at<=NOW() AND expires_at>NOW()
ORDER BY priority DESC,available_at,sequence_id
LIMIT 100
FOR UPDATE SKIP LOCKED;

CREATE TEMP TABLE scale_idempotency_records (
  cache_key TEXT PRIMARY KEY,
  actor_id TEXT NOT NULL,
  state TEXT NOT NULL,
  request_hash TEXT NOT NULL,
  response_status INTEGER,
  response_content_type TEXT,
  expires_at TIMESTAMPTZ NOT NULL,
  lease_expires_at TIMESTAMPTZ NOT NULL
);
CREATE INDEX scale_idempotency_expiry
  ON scale_idempotency_records(expires_at,cache_key)
  INCLUDE (response_status,response_content_type)
  WHERE state='completed';

INSERT INTO scale_idempotency_records
SELECT md5('idem-a-' || g) || md5('idem-b-' || g),
       'actor-' || (g % 100000),'completed',md5('hash-a-' || g) || md5('hash-b-' || g),
       200,'application/json',NOW()+INTERVAL '10 minutes',NOW()
FROM generate_series(1, :scale_rows) AS g;
ANALYZE scale_idempotency_records;

\echo PLAN_IDEMPOTENCY_CLAIM
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT request_hash,state,response_status,response_content_type
FROM scale_idempotency_records
WHERE cache_key=md5('idem-a-42') || md5('idem-b-42');

\echo PLAN_IDEMPOTENCY_RETENTION
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT cache_key
FROM scale_idempotency_records
WHERE state='completed' AND expires_at<NOW()
ORDER BY expires_at,cache_key
LIMIT 1000
FOR UPDATE SKIP LOCKED;
