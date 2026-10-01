BEGIN;

ALTER TABLE matching.matches
  ADD COLUMN IF NOT EXISTS unmatched_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS unmatched_by_user_id UUID,
  ADD COLUMN IF NOT EXISTS ended_reason TEXT;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'matches_unmatched_by_user_id_fkey'
      AND conrelid = 'matching.matches'::regclass
  ) THEN
    ALTER TABLE matching.matches
      ADD CONSTRAINT matches_unmatched_by_user_id_fkey
      FOREIGN KEY (unmatched_by_user_id)
      REFERENCES user_management.users(id)
      ON DELETE SET NULL;
  END IF;
END $$;

CREATE TABLE IF NOT EXISTS matching.chat_read_cursors (
  match_id UUID NOT NULL REFERENCES matching.matches(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  last_read_message_id UUID REFERENCES matching.messages(id) ON DELETE SET NULL,
  last_read_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (match_id, user_id)
);

CREATE TABLE IF NOT EXISTS matching.realtime_outbox (
  sequence_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  event_id UUID NOT NULL DEFAULT gen_random_uuid() UNIQUE,
  recipient_user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  match_id UUID REFERENCES matching.matches(id) ON DELETE CASCADE,
  event_type TEXT NOT NULL,
  payload JSONB NOT NULL DEFAULT '{}'::JSONB,
  occurred_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  delivered_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '30 days'),
  CONSTRAINT realtime_outbox_event_type_check CHECK (
    event_type IN (
      'match.created',
      'match.unmatched',
      'message.created',
      'message.delivered',
      'message.read',
      'message.deleted'
    )
  )
);

CREATE INDEX IF NOT EXISTS idx_realtime_outbox_recipient_sequence
  ON matching.realtime_outbox(recipient_user_id, sequence_id);

CREATE INDEX IF NOT EXISTS idx_realtime_outbox_expiry
  ON matching.realtime_outbox(expires_at);

CREATE INDEX IF NOT EXISTS idx_chat_read_cursors_user_updated
  ON matching.chat_read_cursors(user_id, updated_at DESC);

CREATE INDEX IF NOT EXISTS idx_messages_unread_match_sender
  ON matching.messages(match_id, sender_id, created_at DESC)
  WHERE read_at IS NULL AND is_deleted = FALSE;

CREATE INDEX IF NOT EXISTS idx_matches_user_1_active
  ON matching.matches(user_id_1, COALESCE(last_message_at, created_at) DESC)
  WHERE user_1_status = 'active' AND user_2_status = 'active';

CREATE INDEX IF NOT EXISTS idx_matches_user_2_active
  ON matching.matches(user_id_2, COALESCE(last_message_at, created_at) DESC)
  WHERE user_1_status = 'active' AND user_2_status = 'active';

CREATE OR REPLACE FUNCTION matching.capture_match_realtime_event()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  event_payload JSONB;
BEGIN
  IF TG_OP = 'INSERT' THEN
    event_payload := jsonb_build_object(
      'match_id', NEW.id,
      'user_id_1', NEW.user_id_1,
      'user_id_2', NEW.user_id_2,
      'created_at', NEW.created_at
    );
    INSERT INTO matching.realtime_outbox(recipient_user_id, match_id, event_type, payload)
    VALUES
      (NEW.user_id_1, NEW.id, 'match.created', event_payload),
      (NEW.user_id_2, NEW.id, 'match.created', event_payload);
    RETURN NEW;
  END IF;

  IF (OLD.user_1_status, OLD.user_2_status) IS DISTINCT FROM
     (NEW.user_1_status, NEW.user_2_status)
     AND (NEW.user_1_status = 'unmatched' OR NEW.user_2_status = 'unmatched') THEN
    event_payload := jsonb_build_object(
      'match_id', NEW.id,
      'unmatched_by_user_id', NEW.unmatched_by_user_id,
      'unmatched_at', COALESCE(NEW.unmatched_at, NOW()),
      'reason', COALESCE(NEW.ended_reason, 'user_unmatched')
    );
    INSERT INTO matching.realtime_outbox(recipient_user_id, match_id, event_type, payload)
    VALUES
      (NEW.user_id_1, NEW.id, 'match.unmatched', event_payload),
      (NEW.user_id_2, NEW.id, 'match.unmatched', event_payload);
  END IF;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION matching.capture_message_realtime_event()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
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
$$;

DROP TRIGGER IF EXISTS trg_matches_realtime_outbox ON matching.matches;
CREATE TRIGGER trg_matches_realtime_outbox
AFTER INSERT OR UPDATE OF user_1_status, user_2_status, unmatched_at,
  unmatched_by_user_id, ended_reason
ON matching.matches
FOR EACH ROW EXECUTE FUNCTION matching.capture_match_realtime_event();

DROP TRIGGER IF EXISTS trg_messages_realtime_outbox ON matching.messages;
CREATE TRIGGER trg_messages_realtime_outbox
AFTER INSERT OR UPDATE OF delivered_at, read_at, is_deleted, deleted_at
ON matching.messages
FOR EACH ROW EXECUTE FUNCTION matching.capture_message_realtime_event();

INSERT INTO public.schema_migrations(version)
VALUES ('054_core_dating_realtime_outbox')
ON CONFLICT (version) DO UPDATE SET applied_at = EXCLUDED.applied_at;

COMMIT;
