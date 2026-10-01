-- ─────────────────────────────────────────────────────────────────────────────
-- 097: Verified-human conversations and the writing copilot
--
-- The copilot drafts openers, replies and date ideas for a member. It never
-- sends anything. When a member sends a message that started as a copilot
-- draft, the message carries an "assisted" mark that the other member can
-- see, so help is honest rather than hidden. Drafts are stored with a
-- minimised context digest (never the other member's message bodies) so
-- usage can be rate limited and audited.
--
-- Safe to run repeatedly.
-- ─────────────────────────────────────────────────────────────────────────────

BEGIN;

CREATE TABLE IF NOT EXISTS matching.copilot_drafts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  match_id UUID REFERENCES matching.matches(id) ON DELETE CASCADE,
  kind TEXT NOT NULL CHECK (kind IN ('opener','reply','plan_idea')),
  tone TEXT NOT NULL DEFAULT 'warm' CHECK (tone IN ('warm','playful','direct')),
  draft TEXT NOT NULL CHECK (char_length(draft) BETWEEN 1 AND 600),
  provider TEXT NOT NULL,
  model TEXT,
  context_digest TEXT,
  used_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_copilot_drafts_member
  ON matching.copilot_drafts(user_id, created_at DESC);

CREATE TABLE IF NOT EXISTS matching.message_assist_marks (
  message_id UUID PRIMARY KEY REFERENCES matching.messages(id) ON DELETE CASCADE,
  match_id UUID NOT NULL REFERENCES matching.matches(id) ON DELETE CASCADE,
  sender_user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  draft_id UUID REFERENCES matching.copilot_drafts(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_message_assist_marks_match
  ON matching.message_assist_marks(match_id, created_at DESC);

-- The mark must belong to the message's own sender and match.
CREATE OR REPLACE FUNCTION matching.validate_message_assist_mark()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM matching.messages m
    WHERE m.id = NEW.message_id AND m.match_id = NEW.match_id AND m.sender_id = NEW.sender_user_id
  ) THEN
    RAISE EXCEPTION 'assist mark must belong to the message sender';
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_validate_message_assist_mark ON matching.message_assist_marks;
CREATE TRIGGER trg_validate_message_assist_mark
BEFORE INSERT OR UPDATE ON matching.message_assist_marks
FOR EACH ROW EXECUTE FUNCTION matching.validate_message_assist_mark();

INSERT INTO matching.platform_feature_flags(key, value_bool, description, updated_by)
VALUES ('copilot_enabled', TRUE,
        'Writing copilot drafts with honest assisted-message marks', 'migration_097')
ON CONFLICT (key) DO NOTHING;

SELECT platform.register_event_source('matching', 'copilot_drafts', 'copilot.draft');
SELECT platform.register_event_source('matching', 'message_assist_marks', 'message.assist_mark');

INSERT INTO platform.aggregate_ownership(
  aggregate_type, owner_component, source_schema, source_table,
  transaction_boundary, recovery_strategy
) VALUES
  ('copilot.draft', 'mobile-bff.copilot', 'matching', 'copilot_drafts',
   'single PostgreSQL transaction', 'idempotent command replay')
ON CONFLICT (aggregate_type) DO UPDATE
SET owner_component = EXCLUDED.owner_component, updated_at = NOW();

INSERT INTO platform.required_aggregates(aggregate_type)
VALUES ('copilot.draft')
ON CONFLICT DO NOTHING;

COMMIT;
