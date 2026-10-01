-- ─────────────────────────────────────────────────────────────────────────────
-- 074: Gift send integrity (GIFT-003 / GIFT-004 / GIFT-005)
--   • Links a chat message to the gift send it represents (messages.gift_send_id)
--     so a gift is a first-class chat event rather than only a text token.
--   • Push notifications for a gift say "sent you a gift" instead of echoing
--     the raw `[gift:…]` token.
--   • The realtime `message.created` payload carries gift_send_id.
-- The debit, send row, free-gift entitlement and chat message are written in
-- one transaction by the BFF (gift_send_ledger.go); this migration only adds
-- the columns and trigger behaviour that transaction relies on.
-- Safe to run repeatedly.
-- ─────────────────────────────────────────────────────────────────────────────

ALTER TABLE matching.messages
  ADD COLUMN IF NOT EXISTS gift_send_id UUID DEFAULT NULL
    REFERENCES matching.match_gift_sends(id) ON DELETE SET NULL;

-- One chat message per gift send.
CREATE UNIQUE INDEX IF NOT EXISTS idx_messages_gift_send
  ON matching.messages(gift_send_id)
  WHERE gift_send_id IS NOT NULL;

-- Gift notifications name the gift, never the encoded token.
CREATE OR REPLACE FUNCTION matching.notify_message_insert()
RETURNS trigger
LANGUAGE plpgsql
AS $function$
DECLARE
  recipient UUID;
  gift_label TEXT;
  title TEXT := 'New message';
  body TEXT := LEFT(NEW.text, 180);
BEGIN
  SELECT CASE WHEN m.user_id_1 = NEW.sender_id THEN m.user_id_2 ELSE m.user_id_1 END
    INTO recipient FROM matching.matches m WHERE m.id = NEW.match_id;
  IF NEW.gift_send_id IS NOT NULL THEN
    SELECT NULLIF(TRIM(c.name), '')
      INTO gift_label
      FROM matching.match_gift_sends s
      JOIN matching.gift_catalog c ON c.id = s.gift_id
     WHERE s.id = NEW.gift_send_id;
    title := 'You received a gift';
    body := 'Your match sent you ' || COALESCE(gift_label, 'a gift') || '.';
  END IF;
  PERFORM matching.enqueue_notification(
    recipient, NEW.sender_id, 'message.created', 'message', NEW.id,
    'message:' || NEW.id::text, title, body,
    '/chat/' || NEW.match_id::text,
    jsonb_build_object(
      'match_id', NEW.match_id,
      'message_id', NEW.id,
      'gift_send_id', NEW.gift_send_id
    ),
    6::SMALLINT
  );
  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION matching.capture_message_realtime_event()
RETURNS trigger
LANGUAGE plpgsql
AS $function$
DECLARE
  recipient_id UUID;
  reader_id UUID;
  event_payload JSONB;
BEGIN
  SELECT CASE WHEN m.user_id_1 = NEW.sender_id THEN m.user_id_2 ELSE m.user_id_1 END
  INTO recipient_id
  FROM matching.matches m
  WHERE m.id = NEW.match_id;

  IF TG_OP = 'INSERT' THEN
    UPDATE matching.matches
    SET chat_count = chat_count + 1,
        last_message_at = NEW.created_at,
        lock_version = lock_version + 1
    WHERE id = NEW.match_id;

    event_payload := jsonb_build_object(
      'message_id', NEW.id,
      'match_id', NEW.match_id,
      'sender_id', NEW.sender_id,
      'text', NEW.text,
      'gift_send_id', NEW.gift_send_id,
      'created_at', NEW.created_at,
      'delivered_at', NEW.delivered_at,
      'read_at', NEW.read_at,
      'is_deleted', NEW.is_deleted
    );
    INSERT INTO matching.realtime_outbox(recipient_user_id, match_id, event_type, payload)
    VALUES (recipient_id, NEW.match_id, 'message.created', event_payload);
    RETURN NEW;
  END IF;

  IF OLD.delivered_at IS NULL AND NEW.delivered_at IS NOT NULL THEN
    INSERT INTO matching.realtime_outbox(recipient_user_id, match_id, event_type, payload)
    VALUES (
      NEW.sender_id,
      NEW.match_id,
      'message.delivered',
      jsonb_build_object(
        'message_id', NEW.id,
        'match_id', NEW.match_id,
        'delivered_at', NEW.delivered_at
      )
    );
  END IF;

  IF OLD.read_at IS NULL AND NEW.read_at IS NOT NULL THEN
    reader_id := recipient_id;
    INSERT INTO matching.chat_read_cursors(
      match_id, user_id, last_read_message_id, last_read_at, updated_at
    ) VALUES (
      NEW.match_id, reader_id, NEW.id, NEW.read_at, NOW()
    )
    ON CONFLICT (match_id, user_id) DO UPDATE
      SET last_read_message_id = EXCLUDED.last_read_message_id,
          last_read_at = GREATEST(matching.chat_read_cursors.last_read_at, EXCLUDED.last_read_at),
          updated_at = NOW();

    INSERT INTO matching.realtime_outbox(recipient_user_id, match_id, event_type, payload)
    VALUES (
      NEW.sender_id,
      NEW.match_id,
      'message.read',
      jsonb_build_object(
        'message_id', NEW.id,
        'match_id', NEW.match_id,
        'read_by_user_id', reader_id,
        'read_at', NEW.read_at
      )
    );
  END IF;

  IF OLD.is_deleted = FALSE AND NEW.is_deleted = TRUE THEN
    INSERT INTO matching.realtime_outbox(recipient_user_id, match_id, event_type, payload)
    VALUES (
      recipient_id,
      NEW.match_id,
      'message.deleted',
      jsonb_build_object(
        'message_id', NEW.id,
        'match_id', NEW.match_id,
        'deleted_at', NEW.deleted_at
      )
    );
  END IF;
  RETURN NEW;
END;
$function$;
