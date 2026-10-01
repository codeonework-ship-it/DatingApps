BEGIN;
CREATE TABLE IF NOT EXISTS growth.city_pilots (
 id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
 city TEXT NOT NULL CHECK(char_length(city) BETWEEN 2 AND 100),
 country TEXT NOT NULL CHECK(char_length(country) BETWEEN 2 AND 100),
 owner TEXT NOT NULL CHECK(char_length(owner) BETWEEN 3 AND 120),
 safety_owner TEXT NOT NULL CHECK(char_length(safety_owner) BETWEEN 3 AND 120),
 status TEXT NOT NULL DEFAULT 'draft' CHECK(status IN ('draft','recruiting','measuring','experiences','paused','completed')),
 starts_at TIMESTAMPTZ NOT NULL,
 closes_at TIMESTAMPTZ NOT NULL,
 capacity INTEGER NOT NULL CHECK(capacity BETWEEN 20 AND 5000),
 minimum_pairs INTEGER NOT NULL CHECK(minimum_pairs BETWEEN 20 AND 10000),
 conversation_target INTEGER NOT NULL CHECK(conversation_target BETWEEN 1 AND 100),
 plan_target INTEGER NOT NULL CHECK(plan_target BETWEEN 1 AND 100),
 date_target INTEGER NOT NULL CHECK(date_target BETWEEN 1 AND 100),
 review_note TEXT NOT NULL DEFAULT '' CHECK(char_length(review_note)<=2000),
 safety_ready BOOLEAN NOT NULL DEFAULT FALSE,
 version INTEGER NOT NULL DEFAULT 1,
 created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
 updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
 CHECK(closes_at>starts_at AND closes_at<=starts_at+INTERVAL '56 days')
);
-- Focus on one pilot at a time. A completed pilot remains reviewable.
CREATE UNIQUE INDEX IF NOT EXISTS idx_one_city_pilot ON growth.city_pilots((TRUE)) WHERE status<>'completed';
CREATE TABLE IF NOT EXISTS growth.city_pilot_members (
 id UUID NOT NULL UNIQUE DEFAULT gen_random_uuid(),
 pilot_id UUID NOT NULL REFERENCES growth.city_pilots(id) ON DELETE CASCADE,
 member_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
 consent_version TEXT NOT NULL DEFAULT 'city-pilot-v1' CHECK(consent_version='city-pilot-v1'),
 joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
 withdrawn_at TIMESTAMPTZ,
 PRIMARY KEY(pilot_id,member_id)
);
CREATE INDEX IF NOT EXISTS idx_city_pilot_member ON growth.city_pilot_members(member_id);
CREATE TABLE IF NOT EXISTS growth.city_pilot_experiences (
 id UUID NOT NULL UNIQUE DEFAULT gen_random_uuid(),
 event_id UUID PRIMARY KEY REFERENCES growth.events(id) ON DELETE CASCADE,
 pilot_id UUID NOT NULL REFERENCES growth.city_pilots(id) ON DELETE CASCADE,
 ends_at TIMESTAMPTZ NOT NULL,
 host_name TEXT NOT NULL CHECK(char_length(host_name) BETWEEN 3 AND 120),
 accessibility_note TEXT NOT NULL CHECK(char_length(accessibility_note) BETWEEN 10 AND 1000)
);
CREATE TABLE IF NOT EXISTS growth.city_pilot_feedback (
 id UUID NOT NULL UNIQUE DEFAULT gen_random_uuid(),
 event_id UUID NOT NULL REFERENCES growth.city_pilot_experiences(event_id) ON DELETE CASCADE,
 member_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
 attended BOOLEAN NOT NULL,
 worthwhile BOOLEAN,
 created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
 PRIMARY KEY(event_id,member_id),
 CHECK(attended OR worthwhile IS NULL)
);
INSERT INTO matching.platform_feature_flags(key,value_bool,description,updated_by) VALUES('city_pilot_enabled',FALSE,'Opt-in city pilot recruitment and hosted experience bookings. Withdrawal stays available.','migration-103') ON CONFLICT(key) DO NOTHING;
-- Cancellation uses the existing transactional notification outbox.
CREATE OR REPLACE FUNCTION growth.notify_city_pilot_cancellation() RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE booking RECORD;
BEGIN
 IF NEW.status='cancelled' AND OLD.status<>'cancelled' AND EXISTS(SELECT 1 FROM growth.city_pilot_experiences WHERE event_id=NEW.id) THEN
  FOR booking IN SELECT member_id FROM growth.event_registrations WHERE event_id=NEW.id AND status='registered' LOOP
   PERFORM matching.enqueue_notification(booking.member_id,NULL,'city_pilot.experience_cancelled','system',NEW.id,
    'city-pilot:cancel:'||NEW.id::text||':'||booking.member_id::text,'Your experience is cancelled',
    NEW.title||' has been cancelled. Please do not travel to the venue.','/engagement',jsonb_build_object('event_id',NEW.id));
  END LOOP;
 END IF;
 RETURN NEW;
END;
$$;
DROP TRIGGER IF EXISTS trg_city_pilot_cancellation ON growth.events;
CREATE TRIGGER trg_city_pilot_cancellation AFTER UPDATE OF status ON growth.events FOR EACH ROW EXECUTE FUNCTION growth.notify_city_pilot_cancellation();
DO $$
DECLARE item TEXT;
BEGIN
 FOREACH item IN ARRAY ARRAY['city_pilots','city_pilot_members','city_pilot_experiences','city_pilot_feedback'] LOOP
  PERFORM platform.register_event_source('growth',item,'growth.'||item);
  INSERT INTO platform.aggregate_ownership(aggregate_type,owner_component,source_schema,source_table,transaction_boundary,recovery_strategy)
  VALUES('growth.'||item,'mobile-bff.city-pilot','growth',item,'pilot lock then event lock; atomic source change and outbox','authoritative re-read; unique membership, RSVP and feedback; versioned transitions') ON CONFLICT DO NOTHING;
  INSERT INTO platform.required_aggregates(aggregate_type) VALUES('growth.'||item) ON CONFLICT DO NOTHING;
 END LOOP;
END $$;
INSERT INTO public.schema_migrations(version) VALUES('103_city_pilot') ON CONFLICT DO NOTHING;
COMMIT;
