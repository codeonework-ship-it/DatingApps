-- ─────────────────────────────────────────────────────────────────────────────
-- 083: Receiver controls for gifts
--
-- A gift stays part of the sender's ledger and chat history, while its receiver
-- can hide it from their own view or report it to moderation. Reports hide the
-- gift immediately and retain a durable link to the moderation case.
-- Safe to run repeatedly.
-- ─────────────────────────────────────────────────────────────────────────────

BEGIN;

CREATE TABLE IF NOT EXISTS matching.gift_receiver_actions (
  gift_send_id UUID PRIMARY KEY
    REFERENCES matching.match_gift_sends(id) ON DELETE CASCADE,
  receiver_user_id UUID NOT NULL
    REFERENCES user_management.users(id) ON DELETE CASCADE,
  hidden_at TIMESTAMPTZ,
  reported_at TIMESTAMPTZ,
  report_reason TEXT CHECK (
    report_reason IS NULL OR report_reason IN
      ('unwanted','harassment','sexual_content','scam','other')
  ),
  report_details TEXT CHECK (
    report_details IS NULL OR char_length(report_details) <= 500
  ),
  moderation_report_id UUID UNIQUE
    REFERENCES matching.moderation_reports(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (hidden_at IS NOT NULL OR reported_at IS NOT NULL),
  CHECK (
    (reported_at IS NULL AND report_reason IS NULL AND moderation_report_id IS NULL)
    OR
    (reported_at IS NOT NULL AND report_reason IS NOT NULL AND moderation_report_id IS NOT NULL)
  )
);

CREATE INDEX IF NOT EXISTS idx_gift_receiver_actions_member
  ON matching.gift_receiver_actions(receiver_user_id, updated_at DESC);
CREATE INDEX IF NOT EXISTS idx_gift_receiver_actions_reports
  ON matching.gift_receiver_actions(moderation_report_id)
  WHERE moderation_report_id IS NOT NULL;

CREATE OR REPLACE FUNCTION matching.validate_gift_receiver_action()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE expected_receiver UUID;
BEGIN
  SELECT receiver_user_id INTO expected_receiver
  FROM matching.match_gift_sends
  WHERE id=NEW.gift_send_id;
  IF expected_receiver IS NULL OR expected_receiver <> NEW.receiver_user_id THEN
    RAISE EXCEPTION 'gift receiver action must belong to the recorded receiver';
  END IF;
  NEW.updated_at := NOW();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_validate_gift_receiver_action
  ON matching.gift_receiver_actions;
CREATE TRIGGER trg_validate_gift_receiver_action
BEFORE INSERT OR UPDATE ON matching.gift_receiver_actions
FOR EACH ROW EXECUTE FUNCTION matching.validate_gift_receiver_action();

-- Gift notifications use receiver-facing language and never expose the
-- encoded message token.
CREATE OR REPLACE FUNCTION matching.notify_message_insert()
RETURNS trigger
LANGUAGE plpgsql
AS $function$
DECLARE
  recipient UUID;
  gift_label TEXT;
  sender_label TEXT;
  title TEXT := 'New message';
  body TEXT := LEFT(NEW.text, 180);
BEGIN
  SELECT CASE WHEN m.user_id_1 = NEW.sender_id THEN m.user_id_2 ELSE m.user_id_1 END
    INTO recipient FROM matching.matches m WHERE m.id = NEW.match_id;
  IF NEW.gift_send_id IS NOT NULL THEN
    SELECT NULLIF(TRIM(c.name), ''), NULLIF(TRIM(u.name), '')
      INTO gift_label, sender_label
      FROM matching.match_gift_sends s
      JOIN matching.gift_catalog c ON c.id = s.gift_id
      LEFT JOIN user_management.users u ON u.id = s.sender_user_id
     WHERE s.id = NEW.gift_send_id;
    title := 'Gift received';
    body := COALESCE(sender_label, 'Your match') || ' sent you ' ||
      COALESCE(gift_label, 'a gift') || '.';
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

DO $$
BEGIN
  IF to_regprocedure('platform.register_event_source(text,text,text)') IS NOT NULL THEN
    PERFORM platform.register_event_source(
      'matching','gift_receiver_actions','matching.gift_receiver_action'
    );
  END IF;
END $$;

INSERT INTO public.schema_migrations(version)
VALUES ('083_gift_receiver_controls')
ON CONFLICT (version) DO UPDATE SET applied_at=EXCLUDED.applied_at;

COMMIT;
