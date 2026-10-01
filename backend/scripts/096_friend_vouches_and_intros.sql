-- ─────────────────────────────────────────────────────────────────────────────
-- 096: Friend vouches and friend-made intros
--
-- Vouches: an accepted friend writes a short, private-until-approved vouch for
-- a member. The member approves or hides it; only approved vouches (at most
-- three) appear on the member's public profile, attributed to the voucher's
-- first name. The voucher can withdraw at any time.
--
-- Intros: a member introduces two of their accepted friends to each other with
-- a message. Each invitee sees the other's public preview and the message and
-- accepts or declines privately. When both accept a match is created through
-- the ordinary matches table (its triggers send the usual "It is a match"
-- notifications) and the introducer is told the intro worked. A decline ends
-- the intro without saying who declined. Open intros expire after 14 days.
--
-- Safe to run repeatedly.
-- ─────────────────────────────────────────────────────────────────────────────

BEGIN;

-- ── Vouches ──────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS matching.friend_vouches (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  subject_user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  voucher_user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  text TEXT NOT NULL CHECK (char_length(BTRIM(text)) BETWEEN 12 AND 200),
  status TEXT NOT NULL DEFAULT 'pending' CHECK (
    status IN ('pending','approved','hidden','withdrawn')
  ),
  decided_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (subject_user_id, voucher_user_id),
  CHECK (subject_user_id <> voucher_user_id)
);
CREATE INDEX IF NOT EXISTS idx_friend_vouches_subject
  ON matching.friend_vouches(subject_user_id, status, decided_at DESC);
CREATE INDEX IF NOT EXISTS idx_friend_vouches_voucher
  ON matching.friend_vouches(voucher_user_id, updated_at DESC);

CREATE OR REPLACE FUNCTION matching.accepted_friends(p_user_id UUID, p_other_user_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM matching.friend_connections f
    WHERE f.status = 'accepted'
      AND ((f.user_id = p_user_id AND f.friend_user_id = p_other_user_id)
        OR (f.user_id = p_other_user_id AND f.friend_user_id = p_user_id))
  ) AND NOT EXISTS (
    SELECT 1 FROM user_management.blocked_users b
    WHERE (b.user_id = p_user_id AND b.blocked_user_id = p_other_user_id)
       OR (b.user_id = p_other_user_id AND b.blocked_user_id = p_user_id)
  )
$$;

CREATE OR REPLACE FUNCTION matching.validate_friend_vouch()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF TG_OP = 'INSERT' AND NOT matching.accepted_friends(NEW.voucher_user_id, NEW.subject_user_id) THEN
    RAISE EXCEPTION 'a vouch must come from an accepted friend';
  END IF;
  IF TG_OP = 'UPDATE' AND NEW.status <> OLD.status THEN
    NEW.decided_at := NOW();
  END IF;
  NEW.text := BTRIM(NEW.text);
  NEW.updated_at := NOW();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_validate_friend_vouch ON matching.friend_vouches;
CREATE TRIGGER trg_validate_friend_vouch
BEFORE INSERT OR UPDATE ON matching.friend_vouches
FOR EACH ROW EXECUTE FUNCTION matching.validate_friend_vouch();

-- ── Intros ───────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS matching.friend_intros (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  introducer_user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  first_user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  second_user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  message TEXT CHECK (message IS NULL OR char_length(message) <= 200),
  first_decision TEXT NOT NULL DEFAULT 'pending' CHECK (first_decision IN ('pending','accepted','declined')),
  second_decision TEXT NOT NULL DEFAULT 'pending' CHECK (second_decision IN ('pending','accepted','declined')),
  status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open','matched','declined','expired')),
  match_id UUID REFERENCES matching.matches(id) ON DELETE SET NULL,
  expires_at TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '14 days'),
  decided_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (introducer_user_id <> first_user_id AND introducer_user_id <> second_user_id),
  CHECK (first_user_id <> second_user_id)
);
-- One open intro per pair, whichever way round.
CREATE UNIQUE INDEX IF NOT EXISTS uq_friend_intros_open_pair
  ON matching.friend_intros(LEAST(first_user_id, second_user_id), GREATEST(first_user_id, second_user_id))
  WHERE status = 'open';
CREATE INDEX IF NOT EXISTS idx_friend_intros_first
  ON matching.friend_intros(first_user_id, status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_friend_intros_second
  ON matching.friend_intros(second_user_id, status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_friend_intros_introducer
  ON matching.friend_intros(introducer_user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_friend_intros_expiry
  ON matching.friend_intros(expires_at) WHERE status = 'open';

-- Each invitee's saved preferences must welcome the other's gender.
CREATE OR REPLACE FUNCTION matching.intro_pair_compatible(p_first UUID, p_second UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
AS $$
  SELECT COALESCE((
    SELECT (pf.seeking_genders IS NULL OR cardinality(pf.seeking_genders) = 0
            OR us.gender = ANY (pf.seeking_genders))
       AND (ps.seeking_genders IS NULL OR cardinality(ps.seeking_genders) = 0
            OR uf.gender = ANY (ps.seeking_genders))
    FROM user_management.users uf
    JOIN user_management.users us ON us.id = p_second
    LEFT JOIN user_management.preferences pf ON pf.user_id = uf.id
    LEFT JOIN user_management.preferences ps ON ps.user_id = us.id
    WHERE uf.id = p_first
  ), FALSE)
$$;

CREATE OR REPLACE FUNCTION matching.validate_friend_intro()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    IF NOT matching.accepted_friends(NEW.introducer_user_id, NEW.first_user_id)
       OR NOT matching.accepted_friends(NEW.introducer_user_id, NEW.second_user_id) THEN
      RAISE EXCEPTION 'an intro must be between two accepted friends of the introducer';
    END IF;
    IF EXISTS (
      SELECT 1 FROM user_management.blocked_users b
      WHERE (b.user_id = NEW.first_user_id AND b.blocked_user_id = NEW.second_user_id)
         OR (b.user_id = NEW.second_user_id AND b.blocked_user_id = NEW.first_user_id)
    ) THEN
      RAISE EXCEPTION 'intro is unavailable for this pair';
    END IF;
    IF EXISTS (
      SELECT 1 FROM matching.matches m
      WHERE m.user_id_1 = LEAST(NEW.first_user_id, NEW.second_user_id)
        AND m.user_id_2 = GREATEST(NEW.first_user_id, NEW.second_user_id)
        AND m.unmatched_at IS NULL
    ) THEN
      RAISE EXCEPTION 'these members are already matched';
    END IF;
    IF NOT matching.intro_pair_compatible(NEW.first_user_id, NEW.second_user_id) THEN
      RAISE EXCEPTION 'intro does not fit both members'' preferences';
    END IF;
  END IF;
  IF TG_OP = 'UPDATE' AND NEW.status <> OLD.status THEN
    NEW.decided_at := NOW();
  END IF;
  NEW.updated_at := NOW();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_validate_friend_intro ON matching.friend_intros;
CREATE TRIGGER trg_validate_friend_intro
BEFORE INSERT OR UPDATE ON matching.friend_intros
FOR EACH ROW EXECUTE FUNCTION matching.validate_friend_intro();

-- Both accepted: create (or reuse) the match and close the intro.
CREATE OR REPLACE FUNCTION matching.friend_intro_match(p_intro_id UUID)
RETURNS UUID
LANGUAGE plpgsql
AS $$
DECLARE
  intro matching.friend_intros%ROWTYPE;
  new_match UUID;
  introducer_name TEXT;
  first_name TEXT;
  second_name TEXT;
BEGIN
  SELECT * INTO intro FROM matching.friend_intros WHERE id = p_intro_id FOR UPDATE;
  IF intro.id IS NULL OR intro.status <> 'open'
     OR intro.first_decision <> 'accepted' OR intro.second_decision <> 'accepted' THEN
    RETURN intro.match_id;
  END IF;
  INSERT INTO matching.matches(user_id_1, user_id_2)
  VALUES (LEAST(intro.first_user_id, intro.second_user_id), GREATEST(intro.first_user_id, intro.second_user_id))
  ON CONFLICT DO NOTHING
  RETURNING id INTO new_match;
  IF new_match IS NULL THEN
    SELECT id INTO new_match FROM matching.matches
    WHERE user_id_1 = LEAST(intro.first_user_id, intro.second_user_id)
      AND user_id_2 = GREATEST(intro.first_user_id, intro.second_user_id);
  END IF;
  UPDATE matching.friend_intros
  SET status = 'matched', match_id = new_match WHERE id = p_intro_id;

  SELECT COALESCE(NULLIF(BTRIM(name), ''), 'A friend') INTO introducer_name
  FROM user_management.users WHERE id = intro.introducer_user_id;
  SELECT COALESCE(NULLIF(BTRIM(name), ''), 'your friend') INTO first_name
  FROM user_management.users WHERE id = intro.first_user_id;
  SELECT COALESCE(NULLIF(BTRIM(name), ''), 'your friend') INTO second_name
  FROM user_management.users WHERE id = intro.second_user_id;
  PERFORM matching.enqueue_notification(
    intro.introducer_user_id, NULL, 'friend_intro.matched', 'friend_plan', p_intro_id,
    'friend-intro:' || p_intro_id::text || ':matched',
    'Your intro worked', first_name || ' and ' || second_name || ' matched. Nice one.',
    '/friends/intros',
    jsonb_build_object('intro_id', p_intro_id, 'match_id', new_match), 6::SMALLINT
  );
  INSERT INTO matching.friend_activity_feed(user_id, friend_user_id, activity_type, title, description, metadata)
  VALUES (intro.introducer_user_id, intro.first_user_id, 'friend_intro_matched',
          'Your intro worked', first_name || ' and ' || second_name || ' matched.',
          jsonb_build_object('intro_id', p_intro_id, 'match_id', new_match));
  PERFORM platform.publish_domain_event(
    'friend_intro.matched', 1, 'friend_intro', p_intro_id::text, 'mobile-bff.friend-social',
    intro.introducer_user_id, NULL, NULL, NULL, 'friend-intro:matched:' || p_intro_id::text,
    jsonb_build_object('match_id', new_match), '{}'::jsonb, NOW()
  );
  RETURN new_match;
END;
$$;

-- Expire open intros nobody answered.
CREATE OR REPLACE FUNCTION matching.friend_intro_sweep(p_now TIMESTAMPTZ DEFAULT NOW())
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
  intro RECORD;
  n INTEGER := 0;
BEGIN
  FOR intro IN
    SELECT id, introducer_user_id FROM matching.friend_intros
    WHERE status = 'open' AND expires_at <= p_now
    FOR UPDATE SKIP LOCKED
  LOOP
    UPDATE matching.friend_intros SET status = 'expired' WHERE id = intro.id;
    PERFORM matching.enqueue_notification(
      intro.introducer_user_id, NULL, 'friend_intro.expired', 'friend_plan', intro.id,
      'friend-intro:' || intro.id::text || ':expired',
      'An intro expired', 'Two weeks passed without both answers. You can try again later.',
      '/friends/intros', jsonb_build_object('intro_id', intro.id), 3::SMALLINT
    );
    n := n + 1;
  END LOOP;
  RETURN n;
END;
$$;

-- ── Flag, registry, ownership ────────────────────────────────────────────────
INSERT INTO matching.platform_feature_flags(key, value_bool, description, updated_by)
VALUES ('friend_intros_enabled', TRUE,
        'Friend vouches on profiles and friend-made intros', 'migration_096')
ON CONFLICT (key) DO NOTHING;

SELECT platform.register_event_source('matching', 'friend_vouches', 'friend_vouch');
SELECT platform.register_event_source('matching', 'friend_intros', 'friend_intro');

INSERT INTO platform.aggregate_ownership(
  aggregate_type, owner_component, source_schema, source_table,
  transaction_boundary, recovery_strategy
) VALUES
  ('friend_vouch', 'mobile-bff.friend-social', 'matching', 'friend_vouches',
   'single PostgreSQL transaction', 'idempotent command replay'),
  ('friend_intro', 'mobile-bff.friend-social', 'matching', 'friend_intros',
   'single PostgreSQL transaction', 'idempotent command replay')
ON CONFLICT (aggregate_type) DO UPDATE
SET owner_component = EXCLUDED.owner_component, updated_at = NOW();

INSERT INTO platform.required_aggregates(aggregate_type)
VALUES ('friend_vouch'), ('friend_intro')
ON CONFLICT DO NOTHING;

COMMIT;
