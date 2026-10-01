-- Intentional dating: opt-in availability, private chemistry, collaborative
-- plans and a second yes. Domain events contain field names, never answers.
BEGIN;

CREATE TABLE IF NOT EXISTS matching.dating_preferences (
  user_id UUID PRIMARY KEY REFERENCES user_management.users(id) ON DELETE CASCADE,
  intent TEXT NOT NULL DEFAULT '' CHECK (intent IN ('','relationship','exploring','casual')),
  pace TEXT NOT NULL DEFAULT '' CHECK (pace IN ('','slow','steady','frequent')),
  pace_status TEXT NOT NULL DEFAULT '' CHECK (pace_status IN ('','slow_week')),
  share_pace BOOLEAN NOT NULL DEFAULT FALSE,
  activities JSONB NOT NULL DEFAULT '[]' CHECK (jsonb_typeof(activities)='array'),
  share_availability BOOLEAN NOT NULL DEFAULT FALSE,
  availability JSONB NOT NULL DEFAULT '[]' CHECK (jsonb_typeof(availability)='array'),
  allow_friend_intros BOOLEAN NOT NULL DEFAULT FALSE,
  intro_share_photo BOOLEAN NOT NULL DEFAULT FALSE,
  intro_share_city BOOLEAN NOT NULL DEFAULT FALSE,
  version INTEGER NOT NULL DEFAULT 1,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS matching.chemistry_moments (
  id UUID PRIMARY KEY,
  match_id UUID NOT NULL REFERENCES matching.matches(id) ON DELETE CASCADE,
  started_by UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  prompt TEXT NOT NULL CHECK (prompt IN ('sunday','adventure','first_date')),
  completed_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ NOT NULL DEFAULT NOW()+INTERVAL '7 days',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE UNIQUE INDEX IF NOT EXISTS uq_chemistry_pending
  ON matching.chemistry_moments(match_id) WHERE completed_at IS NULL;
CREATE TABLE IF NOT EXISTS matching.chemistry_answers (
  moment_id UUID NOT NULL REFERENCES matching.chemistry_moments(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  answer TEXT NOT NULL CHECK (char_length(answer) BETWEEN 1 AND 40),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY(moment_id,user_id)
);

ALTER TABLE matching.match_date_plans
  ADD COLUMN IF NOT EXISTS pending_proposer_id UUID REFERENCES user_management.users(id),
  ADD COLUMN IF NOT EXISTS budget_preference TEXT NOT NULL DEFAULT 'flexible'
    CHECK (budget_preference IN ('flexible','free','modest','treat'));
ALTER TABLE matching.match_date_plan_debriefs
  ADD COLUMN IF NOT EXISTS share_mutual_interest BOOLEAN NOT NULL DEFAULT FALSE;

-- Consent is required before an introduction can disclose a public preview.
CREATE OR REPLACE FUNCTION matching.validate_intro_consent()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM matching.dating_preferences WHERE user_id=NEW.first_user_id AND allow_friend_intros)
     OR NOT EXISTS (SELECT 1 FROM matching.dating_preferences WHERE user_id=NEW.second_user_id AND allow_friend_intros)
     OR EXISTS(SELECT 1 FROM user_management.discovery_pauses WHERE user_id IN (NEW.first_user_id,NEW.second_user_id) AND resumed_at IS NULL) THEN
    RAISE EXCEPTION 'intro is unavailable for this pair';
  END IF;
  RETURN NEW;
END;
$$;
DROP TRIGGER IF EXISTS trg_intro_consent ON matching.friend_intros;
CREATE TRIGGER trg_intro_consent BEFORE INSERT ON matching.friend_intros
FOR EACH ROW EXECUTE FUNCTION matching.validate_intro_consent();

-- Match outcomes belong to the two invitees; they are not a friend feed item.
CREATE OR REPLACE FUNCTION matching.friend_intro_match(p_intro_id UUID)
RETURNS UUID LANGUAGE plpgsql AS $$
DECLARE intro matching.friend_intros%ROWTYPE; new_match UUID;
BEGIN
  SELECT * INTO intro FROM matching.friend_intros WHERE id=p_intro_id FOR UPDATE;
  IF intro.id IS NULL OR intro.status<>'open'
     OR intro.first_decision<>'accepted' OR intro.second_decision<>'accepted' THEN
    RETURN intro.match_id;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM matching.dating_preferences WHERE user_id=intro.first_user_id AND allow_friend_intros)
     OR NOT EXISTS (SELECT 1 FROM matching.dating_preferences WHERE user_id=intro.second_user_id AND allow_friend_intros)
     OR EXISTS(SELECT 1 FROM user_management.discovery_pauses WHERE user_id IN(intro.first_user_id,intro.second_user_id) AND resumed_at IS NULL)
     OR intro.expires_at<=NOW()
     OR NOT matching.intro_pair_compatible(intro.first_user_id,intro.second_user_id)
     OR EXISTS(SELECT 1 FROM user_management.users WHERE id IN(intro.first_user_id,intro.second_user_id) AND (NOT is_active OR deactivated_at IS NOT NULL OR deletion_requested_at IS NOT NULL))
     OR NOT matching.accepted_friends(intro.introducer_user_id,intro.first_user_id)
     OR NOT matching.accepted_friends(intro.introducer_user_id,intro.second_user_id)
     OR EXISTS (SELECT 1 FROM user_management.blocked_users
       WHERE (user_id=intro.first_user_id AND blocked_user_id=intro.second_user_id)
          OR (user_id=intro.second_user_id AND blocked_user_id=intro.first_user_id)) THEN
    RAISE EXCEPTION 'intro is unavailable for this pair';
  END IF;
  INSERT INTO matching.matches(user_id_1,user_id_2)
  VALUES (LEAST(intro.first_user_id,intro.second_user_id),GREATEST(intro.first_user_id,intro.second_user_id))
  ON CONFLICT DO NOTHING RETURNING id INTO new_match;
  IF new_match IS NULL THEN
    SELECT id INTO new_match FROM matching.matches
      WHERE user_id_1=LEAST(intro.first_user_id,intro.second_user_id)
        AND user_id_2=GREATEST(intro.first_user_id,intro.second_user_id)
        AND unmatched_at IS NULL AND user_1_status='active' AND user_2_status='active' AND NOT user_1_blocked AND NOT user_2_blocked;
    IF new_match IS NULL THEN RAISE EXCEPTION 'intro is unavailable for this pair'; END IF;
  END IF;
  UPDATE matching.friend_intros SET status='matched',match_id=new_match WHERE id=p_intro_id;
  RETURN new_match;
END;
$$;

CREATE OR REPLACE FUNCTION matching.friend_intro_sweep(p_now TIMESTAMPTZ DEFAULT NOW())
RETURNS INTEGER LANGUAGE plpgsql AS $$
DECLARE n INTEGER;
BEGIN
  UPDATE matching.friend_intros SET status='expired' WHERE status='open' AND expires_at<=p_now;
  GET DIAGNOSTICS n=ROW_COUNT;
  RETURN n;
END;
$$;

-- Remove expired broad windows on the existing five-minute plan worker.
CREATE OR REPLACE FUNCTION matching.expire_dating_availability()
RETURNS VOID LANGUAGE sql AS $$
 UPDATE matching.dating_preferences p
 SET availability=(SELECT COALESCE(jsonb_agg(w),'[]'::jsonb) FROM jsonb_array_elements(p.availability) w WHERE (w->>'end')::timestamptz>NOW()),version=version+1
 WHERE EXISTS(SELECT 1 FROM jsonb_array_elements(p.availability) w WHERE (w->>'end')::timestamptz<=NOW());
$$;

INSERT INTO matching.platform_feature_flags(key,value_bool,description,updated_by)
VALUES ('intentional_dating_enabled',TRUE,'Optional dating rhythm and private chemistry moments','migration_098')
ON CONFLICT(key) DO NOTHING;
SELECT platform.register_event_source('matching','dating_preferences','dating.preferences');
SELECT platform.register_event_source('matching','chemistry_moments','chemistry.moment');
SELECT platform.register_event_source('matching','chemistry_answers','chemistry.answer');
INSERT INTO platform.aggregate_ownership(aggregate_type,owner_component,source_schema,source_table,transaction_boundary,recovery_strategy)
VALUES ('dating.preferences','mobile-bff.intentional-dating','matching','dating_preferences','versioned PostgreSQL transaction','re-read and reconcile version'),
       ('chemistry.moment','mobile-bff.intentional-dating','matching','chemistry_moments','locked PostgreSQL transaction','client UUID and immutable answer replay')
ON CONFLICT(aggregate_type) DO NOTHING;
INSERT INTO platform.required_aggregates(aggregate_type)
VALUES ('dating.preferences'),('chemistry.moment') ON CONFLICT DO NOTHING;
COMMIT;
