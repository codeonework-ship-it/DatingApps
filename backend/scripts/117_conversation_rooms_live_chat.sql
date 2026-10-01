-- Conversation Rooms as live chat rooms.
--
-- Rooms become places to drop into and talk, like the topic chat rooms of the
-- early web: a list of always-on public rooms ("Late-night talks", "Bookworms'
-- corner", "Bengaluru hangout" ...) alongside time-boxed rooms members host.
-- Chat itself lives in the shared chat engine (migration 115, channel kind
-- 'room'); this migration reconciles the room tables, which exist in two
-- shapes (020_engagement_surfaces_tables and 036_full_create_all_screens),
-- and seeds the always-on rooms.
--
--  * conversation_rooms: title/description/capacity in both shapes, plus
--    always_on (no end time), slug (stable seed key), category, icon_key,
--    emoji and sort_order.
--  * conversation_room_participants: role (host / moderator / participant)
--    and last_seen_at, the presence heartbeat behind "N here now".
--  * conversation_room_moderation_actions: actor_user_id in both shapes.
--  * conversation_room_blocks: removal until the session ends (24 hours for
--    always-on rooms).
--
-- Idempotent: safe to run more than once; seeding never duplicates a room and
-- never overwrites an operator's later edits to a seeded room.
BEGIN;

-- ---------------------------------------------------------------------------
-- Rooms
-- ---------------------------------------------------------------------------
ALTER TABLE matching.conversation_rooms ALTER COLUMN id SET DEFAULT gen_random_uuid();
ALTER TABLE matching.conversation_rooms ADD COLUMN IF NOT EXISTS title TEXT;
ALTER TABLE matching.conversation_rooms ADD COLUMN IF NOT EXISTS description TEXT;
ALTER TABLE matching.conversation_rooms ADD COLUMN IF NOT EXISTS topic TEXT;
ALTER TABLE matching.conversation_rooms ADD COLUMN IF NOT EXISTS city TEXT;
ALTER TABLE matching.conversation_rooms ADD COLUMN IF NOT EXISTS room_type TEXT;
ALTER TABLE matching.conversation_rooms ADD COLUMN IF NOT EXISTS capacity INTEGER;
ALTER TABLE matching.conversation_rooms ADD COLUMN IF NOT EXISTS always_on BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE matching.conversation_rooms ADD COLUMN IF NOT EXISTS slug TEXT;
ALTER TABLE matching.conversation_rooms ADD COLUMN IF NOT EXISTS category TEXT;
ALTER TABLE matching.conversation_rooms ADD COLUMN IF NOT EXISTS icon_key TEXT;
ALTER TABLE matching.conversation_rooms ADD COLUMN IF NOT EXISTS emoji TEXT;
ALTER TABLE matching.conversation_rooms ADD COLUMN IF NOT EXISTS sort_order INTEGER NOT NULL DEFAULT 100;

DO $$
BEGIN
  -- The 020 shape named the title "theme" and required it.
  IF EXISTS (SELECT 1 FROM information_schema.columns
             WHERE table_schema='matching' AND table_name='conversation_rooms' AND column_name='theme') THEN
    EXECUTE 'UPDATE matching.conversation_rooms SET title=theme WHERE title IS NULL';
    EXECUTE 'ALTER TABLE matching.conversation_rooms ALTER COLUMN theme DROP NOT NULL';
  END IF;
  ALTER TABLE matching.conversation_rooms ALTER COLUMN description DROP NOT NULL;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint
                 WHERE conname='conversation_rooms_slug_key' AND conrelid='matching.conversation_rooms'::regclass) THEN
    ALTER TABLE matching.conversation_rooms ADD CONSTRAINT conversation_rooms_slug_key UNIQUE (slug);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint
                 WHERE conname='conversation_rooms_capacity_range' AND conrelid='matching.conversation_rooms'::regclass) THEN
    ALTER TABLE matching.conversation_rooms ADD CONSTRAINT conversation_rooms_capacity_range
      CHECK (capacity BETWEEN 2 AND 500) NOT VALID;
  END IF;
  -- A scheduled room has a window; an always-on room has no end.
  IF NOT EXISTS (SELECT 1 FROM pg_constraint
                 WHERE conname='conversation_rooms_schedule_shape' AND conrelid='matching.conversation_rooms'::regclass) THEN
    ALTER TABLE matching.conversation_rooms ADD CONSTRAINT conversation_rooms_schedule_shape
      CHECK (always_on OR (starts_at IS NOT NULL AND ends_at IS NOT NULL AND ends_at > starts_at)) NOT VALID;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint
                 WHERE conname='conversation_rooms_category_check' AND conrelid='matching.conversation_rooms'::regclass) THEN
    ALTER TABLE matching.conversation_rooms ADD CONSTRAINT conversation_rooms_category_check
      CHECK (category IS NULL OR category IN ('talk','interests','active','city')) NOT VALID;
  END IF;
END $$;

UPDATE matching.conversation_rooms SET title=COALESCE(NULLIF(btrim(topic),''),'Conversation room') WHERE title IS NULL;
ALTER TABLE matching.conversation_rooms ALTER COLUMN title SET NOT NULL;
UPDATE matching.conversation_rooms SET room_type='scheduled' WHERE room_type IS NULL;
ALTER TABLE matching.conversation_rooms ALTER COLUMN room_type SET DEFAULT 'scheduled';
ALTER TABLE matching.conversation_rooms ALTER COLUMN room_type SET NOT NULL;
UPDATE matching.conversation_rooms SET capacity=50 WHERE capacity IS NULL OR capacity < 2;
ALTER TABLE matching.conversation_rooms ALTER COLUMN capacity SET DEFAULT 50;
ALTER TABLE matching.conversation_rooms ALTER COLUMN capacity SET NOT NULL;

CREATE INDEX IF NOT EXISTS conversation_rooms_listing
  ON matching.conversation_rooms(always_on DESC, sort_order, starts_at);
-- One open hosted room per member is checked in code; this keeps it cheap.
CREATE INDEX IF NOT EXISTS conversation_rooms_creator
  ON matching.conversation_rooms(created_by_user_id, created_at DESC) WHERE created_by_user_id IS NOT NULL;

-- ---------------------------------------------------------------------------
-- Participants
-- ---------------------------------------------------------------------------
ALTER TABLE matching.conversation_room_participants ADD COLUMN IF NOT EXISTS role TEXT NOT NULL DEFAULT 'participant';
ALTER TABLE matching.conversation_room_participants ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'joined';
ALTER TABLE matching.conversation_room_participants ADD COLUMN IF NOT EXISTS left_at TIMESTAMPTZ;
-- Presence heartbeat: a member counts as "here now" for two minutes after it.
ALTER TABLE matching.conversation_room_participants ADD COLUMN IF NOT EXISTS last_seen_at TIMESTAMPTZ;
UPDATE matching.conversation_room_participants SET last_seen_at=joined_at WHERE last_seen_at IS NULL;
ALTER TABLE matching.conversation_room_participants ALTER COLUMN status SET DEFAULT 'joined';

DO $$
DECLARE c TEXT;
BEGIN
  -- Both shapes carried an inline status check ('joined' in 036, 'active' in
  -- 020) and 020 an inline role check; replace them with one named check each.
  FOR c IN SELECT conname FROM pg_constraint
           WHERE conrelid='matching.conversation_room_participants'::regclass AND contype='c'
             AND conname IN ('conversation_room_participants_status_check','conversation_room_participants_role_check')
  LOOP
    EXECUTE format('ALTER TABLE matching.conversation_room_participants DROP CONSTRAINT %I', c);
  END LOOP;
END $$;
ALTER TABLE matching.conversation_room_participants ADD CONSTRAINT conversation_room_participants_status_check
  CHECK (status IN ('joined','active','left','removed','blocked','muted'));
ALTER TABLE matching.conversation_room_participants ADD CONSTRAINT conversation_room_participants_role_check
  CHECK (role IN ('host','moderator','participant'));

CREATE INDEX IF NOT EXISTS conversation_room_participants_presence
  ON matching.conversation_room_participants(room_id, last_seen_at DESC) WHERE left_at IS NULL;
CREATE INDEX IF NOT EXISTS conversation_room_participants_user
  ON matching.conversation_room_participants(user_id, last_seen_at DESC);

-- ---------------------------------------------------------------------------
-- Moderation log and removals
-- ---------------------------------------------------------------------------
ALTER TABLE matching.conversation_room_moderation_actions ALTER COLUMN id SET DEFAULT gen_random_uuid();
ALTER TABLE matching.conversation_room_moderation_actions ADD COLUMN IF NOT EXISTS actor_user_id UUID REFERENCES user_management.users(id) ON DELETE SET NULL;
ALTER TABLE matching.conversation_room_moderation_actions ADD COLUMN IF NOT EXISTS metadata JSONB NOT NULL DEFAULT '{}'::jsonb;
DO $$
BEGIN
  -- The 020 shape named the actor moderator_user_id and required it.
  IF EXISTS (SELECT 1 FROM information_schema.columns
             WHERE table_schema='matching' AND table_name='conversation_room_moderation_actions' AND column_name='moderator_user_id') THEN
    EXECUTE 'UPDATE matching.conversation_room_moderation_actions SET actor_user_id=moderator_user_id WHERE actor_user_id IS NULL';
    EXECUTE 'ALTER TABLE matching.conversation_room_moderation_actions ALTER COLUMN moderator_user_id DROP NOT NULL';
  END IF;
  ALTER TABLE matching.conversation_room_moderation_actions ALTER COLUMN target_user_id DROP NOT NULL;
  IF EXISTS (SELECT 1 FROM pg_constraint
             WHERE conname='conversation_room_moderation_actions_action_check'
               AND conrelid='matching.conversation_room_moderation_actions'::regclass) THEN
    ALTER TABLE matching.conversation_room_moderation_actions DROP CONSTRAINT conversation_room_moderation_actions_action_check;
  END IF;
END $$;
ALTER TABLE matching.conversation_room_moderation_actions ADD CONSTRAINT conversation_room_moderation_actions_action_check
  CHECK (action IN ('warn','mute','remove','close','set_role')) NOT VALID;
CREATE INDEX IF NOT EXISTS conversation_room_moderation_room_created
  ON matching.conversation_room_moderation_actions(room_id, created_at DESC);

CREATE TABLE IF NOT EXISTS matching.conversation_room_blocks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id UUID NOT NULL REFERENCES matching.conversation_rooms(id) ON DELETE CASCADE,
  blocked_user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  blocked_by_user_id UUID REFERENCES user_management.users(id) ON DELETE SET NULL,
  reason TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMPTZ,
  UNIQUE(room_id, blocked_user_id)
);

-- A room's chat channel goes with the room.
CREATE OR REPLACE FUNCTION matching.conversation_room_drop_channel() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  DELETE FROM matching.social_channels WHERE kind='room' AND ref_id=OLD.id;
  RETURN OLD;
END $$;
DROP TRIGGER IF EXISTS trg_conversation_room_drop_channel ON matching.conversation_rooms;
CREATE TRIGGER trg_conversation_room_drop_channel AFTER DELETE ON matching.conversation_rooms
  FOR EACH ROW EXECUTE FUNCTION matching.conversation_room_drop_channel();

-- ---------------------------------------------------------------------------
-- Always-on public rooms
-- ---------------------------------------------------------------------------
INSERT INTO matching.conversation_rooms
  (slug, title, description, topic, city, room_type, always_on, category, icon_key, emoji, sort_order,
   capacity, lifecycle_state, starts_at, ends_at)
SELECT v.slug, v.title, v.description, v.title, v.city, 'topic', TRUE, v.category, v.icon_key, v.emoji, v.sort_order,
       200, 'active', NOW(), NULL
FROM (VALUES
  ('late-night-talks',   'Late-night talks',    'Can''t sleep? Neither can we. Slow, honest conversation for night owls.', NULL, 'talk', 'night', '🌙', 10),
  ('first-date-stories', 'First-date stories',  'The sweet, the awkward and the unforgettable. Share yours, laugh along with ours.', NULL, 'talk', 'coffee', '☕', 20),
  ('green-flags-only',   'Green flags only',    'The small, kind things that made you think: this one''s a keeper.', NULL, 'talk', 'favorite', '💚', 30),
  ('faith-and-reflection','Faith & reflection', 'A gentle space for belief, doubt, gratitude and the big questions.', NULL, 'talk', 'spa', '🕊️', 40),
  ('bookworms-corner',   'Bookworms'' corner',  'What you''re reading, what you gave up on, and the one you press on everyone.', NULL, 'interests', 'book', '📚', 50),
  ('foodies-table',      'Foodies'' table',     'Hidden dosa spots, family recipes and the dish you''d cook on a third date.', NULL, 'interests', 'restaurant', '🍜', 60),
  ('music-on-repeat',    'Music on repeat',     'The song stuck in your head, the gig you''ll never forget, the long-drive playlist.', NULL, 'interests', 'music', '🎧', 70),
  ('movie-night',        'Movie night',         'Recommendations, hot takes and spoiler-tagged rants. Popcorn optional.', NULL, 'interests', 'movie', '🍿', 80),
  ('pets-and-paws',      'Pets & paws',         'Show-and-tell for dog people, cat people and everyone who stops to say hi.', NULL, 'interests', 'pets', '🐾', 90),
  ('gamers-lounge',      'Gamers'' lounge',     'Co-op partners, cosy games and console debates, kept friendly.', NULL, 'interests', 'games', '🎮', 100),
  ('wanderlust',         'Wanderlust',          'Trips taken, trips dreamed of, and where you''d go with someone new.', NULL, 'active', 'travel', '🧭', 110),
  ('fitness-and-runs',   'Fitness & runs',      'Morning runs, gym wins, yoga and finding a weekend hiking buddy.', NULL, 'active', 'run', '🏃', 120),
  ('bengaluru-hangout',  'Bengaluru hangout',   'Weekend plans, traffic stories and the best filter coffee in town.', 'Bengaluru', 'city', 'city', '🌳', 130),
  ('mumbai-locals',      'Mumbai locals',       'From the sea face to the last local: plans, cutting chai and city chatter.', 'Mumbai', 'city', 'train', '🌊', 140),
  ('delhi-diaries',      'Delhi diaries',       'Winter walks, food streets and where to take someone on a first date.', 'Delhi', 'city', 'city', '🏛️', 150),
  ('hyderabad-nights',   'Hyderabad nights',    'Biryani debates, lake walks and what''s on this weekend.', 'Hyderabad', 'city', 'city', '🌙', 160)
) AS v(slug, title, description, city, category, icon_key, emoji, sort_order)
ON CONFLICT (slug) DO NOTHING;

INSERT INTO public.schema_migrations(version) VALUES('117_conversation_rooms_live_chat') ON CONFLICT DO NOTHING;
COMMIT;
