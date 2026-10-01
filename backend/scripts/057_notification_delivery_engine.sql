BEGIN;

ALTER TABLE user_management.user_settings
  ADD COLUMN IF NOT EXISTS notify_match_nudges BOOLEAN NOT NULL DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS notify_incoming_calls BOOLEAN NOT NULL DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS notify_safety BOOLEAN NOT NULL DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS in_app_notifications_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS push_notifications_enabled BOOLEAN NOT NULL DEFAULT TRUE;

CREATE TABLE IF NOT EXISTS user_management.device_push_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  provider TEXT NOT NULL CHECK (provider IN ('fcm','apns','webhook')),
  platform TEXT NOT NULL CHECK (platform IN ('android','ios','web')),
  token TEXT NOT NULL,
  enabled BOOLEAN NOT NULL DEFAULT TRUE,
  failure_count INTEGER NOT NULL DEFAULT 0 CHECK (failure_count >= 0),
  disabled_reason TEXT,
  last_seen_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(provider, token)
);

CREATE INDEX IF NOT EXISTS idx_device_push_tokens_user_enabled
  ON user_management.device_push_tokens(user_id, platform)
  WHERE enabled;

CREATE TABLE IF NOT EXISTS matching.notification_outbox (
  sequence_id BIGINT GENERATED ALWAYS AS IDENTITY UNIQUE,
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  recipient_user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  actor_user_id UUID REFERENCES user_management.users(id) ON DELETE SET NULL,
  event_type TEXT NOT NULL,
  category TEXT NOT NULL CHECK (category IN ('match','message','like','nudge','call','safety','system')),
  reference_id UUID,
  dedupe_key TEXT NOT NULL UNIQUE,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  action_route TEXT,
  payload JSONB NOT NULL DEFAULT '{}'::JSONB,
  priority SMALLINT NOT NULL DEFAULT 5 CHECK (priority BETWEEN 0 AND 9),
  status TEXT NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending','processing','retry','delivered','suppressed','dead_letter')),
  available_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  attempt_count INTEGER NOT NULL DEFAULT 0 CHECK (attempt_count >= 0),
  max_attempts INTEGER NOT NULL DEFAULT 5 CHECK (max_attempts BETWEEN 1 AND 20),
  locked_at TIMESTAMPTZ,
  worker_id TEXT,
  last_error TEXT,
  processed_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '30 days'),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notification_outbox_claim
  ON matching.notification_outbox(priority DESC, available_at, sequence_id)
  WHERE status IN ('pending','retry');
CREATE INDEX IF NOT EXISTS idx_notification_outbox_recipient_replay
  ON matching.notification_outbox(recipient_user_id, sequence_id);
CREATE INDEX IF NOT EXISTS idx_notification_outbox_stale_processing
  ON matching.notification_outbox(locked_at)
  WHERE status = 'processing';

CREATE TABLE IF NOT EXISTS matching.user_notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  outbox_id UUID NOT NULL UNIQUE REFERENCES matching.notification_outbox(id) ON DELETE CASCADE,
  sequence_id BIGINT NOT NULL UNIQUE,
  recipient_user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  actor_user_id UUID REFERENCES user_management.users(id) ON DELETE SET NULL,
  event_type TEXT NOT NULL,
  category TEXT NOT NULL,
  reference_id UUID,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  action_route TEXT,
  payload JSONB NOT NULL DEFAULT '{}'::JSONB,
  is_read BOOLEAN NOT NULL DEFAULT FALSE,
  read_at TIMESTAMPTZ,
  dismissed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK ((is_read AND read_at IS NOT NULL) OR (NOT is_read))
);

CREATE INDEX IF NOT EXISTS idx_user_notifications_recipient_sequence
  ON matching.user_notifications(recipient_user_id, sequence_id DESC);
CREATE INDEX IF NOT EXISTS idx_user_notifications_unread
  ON matching.user_notifications(recipient_user_id, created_at DESC)
  WHERE NOT is_read AND dismissed_at IS NULL;

CREATE TABLE IF NOT EXISTS matching.notification_deliveries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  outbox_id UUID NOT NULL REFERENCES matching.notification_outbox(id) ON DELETE CASCADE,
  channel TEXT NOT NULL CHECK (channel IN ('in_app','push')),
  device_token_id UUID REFERENCES user_management.device_push_tokens(id) ON DELETE SET NULL,
  status TEXT NOT NULL CHECK (status IN ('delivered','suppressed','failed','dead_letter')),
  provider_message_id TEXT,
  attempt_count INTEGER NOT NULL DEFAULT 1 CHECK (attempt_count >= 1),
  last_error TEXT,
  delivered_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_notification_delivery_in_app
  ON matching.notification_deliveries(outbox_id, channel)
  WHERE channel = 'in_app';
CREATE UNIQUE INDEX IF NOT EXISTS uq_notification_delivery_push_device
  ON matching.notification_deliveries(outbox_id, channel, device_token_id)
  WHERE channel = 'push';

CREATE OR REPLACE FUNCTION matching.enqueue_notification(
  p_recipient_user_id UUID,
  p_actor_user_id UUID,
  p_event_type TEXT,
  p_category TEXT,
  p_reference_id UUID,
  p_dedupe_key TEXT,
  p_title TEXT,
  p_body TEXT,
  p_action_route TEXT,
  p_payload JSONB,
  p_priority SMALLINT DEFAULT 5
) RETURNS VOID
LANGUAGE plpgsql
AS $$
BEGIN
  IF p_recipient_user_id IS NULL OR p_recipient_user_id = p_actor_user_id THEN
    RETURN;
  END IF;
  INSERT INTO matching.notification_outbox (
    recipient_user_id, actor_user_id, event_type, category, reference_id,
    dedupe_key, title, body, action_route, payload, priority
  ) VALUES (
    p_recipient_user_id, p_actor_user_id, p_event_type, p_category, p_reference_id,
    p_dedupe_key, p_title, p_body, p_action_route, COALESCE(p_payload, '{}'::JSONB), p_priority
  ) ON CONFLICT (dedupe_key) DO NOTHING;
END;
$$;

CREATE OR REPLACE FUNCTION matching.notify_swipe_insert() RETURNS TRIGGER
LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.is_like THEN
    PERFORM matching.enqueue_notification(
      NEW.target_user_id, NEW.user_id, 'like.received', 'like', NEW.id,
      'like:' || NEW.id::text, 'Someone liked you',
      'Open the app to see who is interested.', '/likes',
      jsonb_build_object('swipe_id', NEW.id, 'actor_user_id', NEW.user_id), 4::SMALLINT
    );
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_notify_swipe_insert ON matching.swipes;
CREATE TRIGGER trg_notify_swipe_insert AFTER INSERT ON matching.swipes
FOR EACH ROW EXECUTE FUNCTION matching.notify_swipe_insert();

CREATE OR REPLACE FUNCTION matching.notify_match_insert() RETURNS TRIGGER
LANGUAGE plpgsql AS $$
BEGIN
  PERFORM matching.enqueue_notification(
    NEW.user_id_1, NEW.user_id_2, 'match.created', 'match', NEW.id,
    'match:' || NEW.id::text || ':' || NEW.user_id_1::text,
    'It is a match', 'You can start a conversation now.',
    '/matches/' || NEW.id::text, jsonb_build_object('match_id', NEW.id), 7::SMALLINT
  );
  PERFORM matching.enqueue_notification(
    NEW.user_id_2, NEW.user_id_1, 'match.created', 'match', NEW.id,
    'match:' || NEW.id::text || ':' || NEW.user_id_2::text,
    'It is a match', 'You can start a conversation now.',
    '/matches/' || NEW.id::text, jsonb_build_object('match_id', NEW.id), 7::SMALLINT
  );
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_notify_match_insert ON matching.matches;
CREATE TRIGGER trg_notify_match_insert AFTER INSERT ON matching.matches
FOR EACH ROW EXECUTE FUNCTION matching.notify_match_insert();

CREATE OR REPLACE FUNCTION matching.notify_message_insert() RETURNS TRIGGER
LANGUAGE plpgsql AS $$
DECLARE
  recipient UUID;
BEGIN
  SELECT CASE WHEN m.user_id_1 = NEW.sender_id THEN m.user_id_2 ELSE m.user_id_1 END
    INTO recipient FROM matching.matches m WHERE m.id = NEW.match_id;
  PERFORM matching.enqueue_notification(
    recipient, NEW.sender_id, 'message.created', 'message', NEW.id,
    'message:' || NEW.id::text, 'New message', LEFT(NEW.text, 180),
    '/chat/' || NEW.match_id::text,
    jsonb_build_object('match_id', NEW.match_id, 'message_id', NEW.id), 6::SMALLINT
  );
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_notify_message_insert ON matching.messages;
CREATE TRIGGER trg_notify_message_insert AFTER INSERT ON matching.messages
FOR EACH ROW EXECUTE FUNCTION matching.notify_message_insert();

CREATE OR REPLACE FUNCTION matching.notify_match_nudge_insert() RETURNS TRIGGER
LANGUAGE plpgsql AS $$
BEGIN
  PERFORM matching.enqueue_notification(
    NEW.counterparty_user_id, NEW.user_id, 'match_nudge.received', 'nudge', NEW.id,
    'match_nudge:' || NEW.id::text, 'A match nudged you',
    'They would like to keep the conversation going.',
    '/engagement/match-nudges/' || NEW.id::text,
    jsonb_build_object('match_id', NEW.match_id, 'nudge_id', NEW.id, 'nudge_type', NEW.nudge_type), 7::SMALLINT
  );
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_notify_match_nudge_insert ON matching.match_nudges;
CREATE TRIGGER trg_notify_match_nudge_insert AFTER INSERT ON matching.match_nudges
FOR EACH ROW EXECUTE FUNCTION matching.notify_match_nudge_insert();

CREATE OR REPLACE FUNCTION matching.notify_video_call_insert() RETURNS TRIGGER
LANGUAGE plpgsql AS $$
BEGIN
  PERFORM matching.enqueue_notification(
    NEW.recipient_id, NEW.initiator_id, 'call.incoming', 'call', NEW.id,
    'call:' || NEW.id::text, 'Incoming call',
    'A match is calling you.', '/calls/' || NEW.id::text,
    jsonb_build_object('call_id', NEW.id, 'match_id', NEW.match_id, 'room_id', COALESCE(NEW.metadata->>'room_id', 'room-' || NEW.id::text)), 9::SMALLINT
  );
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_notify_video_call_insert ON matching.video_call_sessions;
CREATE TRIGGER trg_notify_video_call_insert AFTER INSERT ON matching.video_call_sessions
FOR EACH ROW EXECUTE FUNCTION matching.notify_video_call_insert();

CREATE OR REPLACE VIEW matching.notification_queue_metrics AS
SELECT
  COUNT(*) FILTER (WHERE status IN ('pending','retry')) AS queue_depth,
  COUNT(*) FILTER (WHERE status = 'processing') AS processing,
  COUNT(*) FILTER (WHERE status = 'dead_letter') AS dead_letter,
  COUNT(*) FILTER (WHERE status = 'delivered') AS delivered,
  COALESCE(EXTRACT(EPOCH FROM (NOW() - MIN(created_at) FILTER (WHERE status IN ('pending','retry')))), 0)::BIGINT AS oldest_pending_age_seconds
FROM matching.notification_outbox;

CREATE OR REPLACE VIEW matching.notification_dead_letters AS
SELECT id, sequence_id, recipient_user_id, event_type, category, reference_id,
       attempt_count, max_attempts, last_error, created_at, updated_at
FROM matching.notification_outbox
WHERE status = 'dead_letter';

COMMIT;
