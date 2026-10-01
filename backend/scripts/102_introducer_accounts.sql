-- Friend-only accounts and scoped, revocable introduction consent.
BEGIN;
ALTER TABLE user_management.users ADD COLUMN IF NOT EXISTS account_kind TEXT NOT NULL DEFAULT 'dating'
 CHECK(account_kind IN ('dating','introducer'));
ALTER TABLE user_management.users ALTER COLUMN gender DROP NOT NULL;
ALTER TABLE user_management.users DROP CONSTRAINT IF EXISTS introducer_not_published;
ALTER TABLE user_management.users ADD CONSTRAINT introducer_not_published CHECK(account_kind<>'introducer' OR (profile_completion=0 AND gender IS NULL));
CREATE TABLE IF NOT EXISTS matching.introducer_invites (
 id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
 member_user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
 token_hash BYTEA NOT NULL UNIQUE,
 share_photo BOOLEAN NOT NULL DEFAULT FALSE,
 share_city BOOLEAN NOT NULL DEFAULT FALSE,
 expires_at TIMESTAMPTZ NOT NULL DEFAULT NOW()+INTERVAL '48 hours',
 consumed_by UUID REFERENCES user_management.users(id) ON DELETE CASCADE,
 consumed_at TIMESTAMPTZ,
 revoked_at TIMESTAMPTZ,
 created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_introducer_invites_member ON matching.introducer_invites(member_user_id);
CREATE TABLE IF NOT EXISTS matching.introducer_consents (
 id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
 introducer_user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
 member_user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
 share_photo BOOLEAN NOT NULL DEFAULT FALSE,
 share_city BOOLEAN NOT NULL DEFAULT FALSE,
 status TEXT NOT NULL DEFAULT 'pending' CHECK(status IN('pending','active')),
 revoked_at TIMESTAMPTZ,
 created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
 UNIQUE(introducer_user_id,member_user_id), CHECK(introducer_user_id<>member_user_id)
);
CREATE INDEX IF NOT EXISTS idx_introducer_consents_member ON matching.introducer_consents(member_user_id);
-- A consent does not create a general friendship or access to date-plan feeds.
CREATE OR REPLACE FUNCTION matching.introducer_can_introduce(p_introducer UUID,p_member UUID)
RETURNS BOOLEAN LANGUAGE sql STABLE AS $$
 SELECT EXISTS(SELECT 1 FROM user_management.users i JOIN user_management.users m ON m.id=p_member
 WHERE i.id=p_introducer AND m.account_kind='dating'
 AND i.is_active AND NOT i.is_banned AND i.erased_at IS NULL AND i.deactivated_at IS NULL AND i.deletion_requested_at IS NULL
 AND (i.suspended_at IS NULL OR (i.suspended_until IS NOT NULL AND i.suspended_until<=NOW()))
 AND m.is_active AND NOT m.is_banned AND m.erased_at IS NULL AND m.deactivated_at IS NULL AND m.deletion_requested_at IS NULL
 AND (m.suspended_at IS NULL OR (m.suspended_until IS NOT NULL AND m.suspended_until<=NOW()))
 AND NOT EXISTS(SELECT 1 FROM user_management.blocked_users b WHERE (b.user_id=i.id AND b.blocked_user_id=m.id) OR (b.user_id=m.id AND b.blocked_user_id=i.id))
 AND NOT EXISTS(SELECT 1 FROM user_management.auth_credentials c WHERE c.user_id IN(i.id,m.id) AND c.is_disabled)
 AND CASE WHEN i.account_kind='introducer' THEN EXISTS(SELECT 1 FROM matching.introducer_consents c WHERE c.introducer_user_id=i.id AND c.member_user_id=m.id AND c.revoked_at IS NULL AND c.status='active')
 ELSE matching.accepted_friends(i.id,m.id) END);
$$;
-- Serialize new proposals, acceptance and revocation on the introducer account.
CREATE OR REPLACE FUNCTION matching.lock_intro_consent() RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
 PERFORM 1 FROM user_management.users WHERE id=NEW.introducer_user_id FOR UPDATE;
 IF NOT matching.introducer_can_introduce(NEW.introducer_user_id,NEW.first_user_id)
 OR NOT matching.introducer_can_introduce(NEW.introducer_user_id,NEW.second_user_id) THEN
 RAISE EXCEPTION 'intro is unavailable for this pair'; END IF;
 RETURN NEW;
END; $$;
DROP TRIGGER IF EXISTS trg_aaa_intro_permission ON matching.friend_intros;
CREATE TRIGGER trg_aaa_intro_permission BEFORE INSERT OR UPDATE OF first_decision,second_decision ON matching.friend_intros
 FOR EACH ROW EXECUTE FUNCTION matching.lock_intro_consent();
CREATE OR REPLACE FUNCTION matching.validate_friend_intro()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    IF NOT matching.introducer_can_introduce(NEW.introducer_user_id, NEW.first_user_id)
       OR NOT matching.introducer_can_introduce(NEW.introducer_user_id, NEW.second_user_id) THEN
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
     OR NOT matching.introducer_can_introduce(intro.introducer_user_id,intro.first_user_id)
     OR NOT matching.introducer_can_introduce(intro.introducer_user_id,intro.second_user_id)
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


SELECT platform.register_event_source('matching','introducer_invites','introducer.invite');
SELECT platform.register_event_source('matching','introducer_consents','introducer.consent');
-- Never publish invite secrets or preview permissions as event values.
INSERT INTO platform.aggregate_ownership(aggregate_type,owner_component,source_schema,source_table,transaction_boundary,recovery_strategy)
VALUES ('introducer.invite','mobile-bff.introducer','matching','introducer_invites','member lock and atomic redemption','one-use digest and replay by same actor'),
 ('introducer.consent','mobile-bff.introducer','matching','introducer_consents','introducer lock and transaction','idempotent revocation and authoritative re-read') ON CONFLICT DO NOTHING;
INSERT INTO platform.required_aggregates(aggregate_type) VALUES('introducer.invite'),('introducer.consent') ON CONFLICT DO NOTHING;
COMMIT;
