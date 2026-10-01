-- Lifestyle community groups and private friend groups.
--
-- A group is either a community group (kind 'community': public, listed under
-- a lifestyle category, anyone eligible can join) or a private group (kind
-- 'private': a plain friends group, invitation only). Initial and later
-- invitations go to accepted, unblocked friends only. Members chat in the
-- group's shared channel (migration 115, channel kind 'group').
--
-- Existing groups stay valid: public groups become community groups in the
-- general "Friends & socials" category, private groups stay private.
BEGIN;

CREATE TABLE IF NOT EXISTS matching.group_categories (
 slug TEXT PRIMARY KEY CHECK (slug ~ '^[a-z0-9][a-z0-9-]{1,39}$'),
 title TEXT NOT NULL CHECK (char_length(title) BETWEEN 2 AND 60),
 emoji TEXT NOT NULL CHECK (char_length(emoji) BETWEEN 1 AND 16),
 description TEXT NOT NULL DEFAULT '' CHECK (char_length(description) <= 200),
 sort_order INTEGER NOT NULL DEFAULT 100,
 is_active BOOLEAN NOT NULL DEFAULT TRUE,
 created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
 updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO matching.group_categories(slug,title,emoji,description,sort_order) VALUES
 ('fitness-running','Fitness & running','🏃','Run clubs, gym buddies, yoga at sunrise and weekend 5Ks.',10),
 ('foodies','Foodies','🍜','Street food crawls, new cafés, home cooks and supper clubs.',20),
 ('travel','Travel','✈️','Weekend getaways, backpacking tips and travel buddies.',30),
 ('outdoors-hiking','Outdoors & hiking','🥾','Trails, treks, camping and anything under an open sky.',40),
 ('books','Books','📚','Reading circles, swaps and long talks about favourite authors.',50),
 ('music','Music','🎶','Gigs, jam sessions, playlists and concert companions.',60),
 ('movies-series','Movies & series','🎬','Watch parties, film nights and what to binge next.',70),
 ('arts-crafts','Arts & crafts','🎨','Sketching, pottery, photography and making things together.',80),
 ('dance','Dance','💃','Salsa, Bollywood, hip hop, swing — every rhythm welcome.',90),
 ('gaming','Gaming','🎮','Co-op nights, board games, esports and retro favourites.',100),
 ('pets','Pets','🐾','Dog walks, cat people, adoption drives and pet-friendly spots.',110),
 ('wellness-mindfulness','Wellness & mindfulness','🧘','Meditation, journaling, slow living and mental wellbeing.',120),
 ('faith-spirituality','Faith & spirituality','🕊️','Faith communities, spiritual practice and reflective conversation, in every tradition.',130),
 ('volunteering','Volunteering','🤝','Give back together: clean-ups, mentoring and local causes.',140),
 ('career-founders','Career & founders','💼','Builders, founders, career switchers and side projects.',150),
 ('learning-languages','Learning & languages','🗣️','Language exchanges, workshops and curious minds.',160),
 ('tech-science','Tech & science','🔭','Gadgets, coding, space and nerdy deep dives.',170),
 ('sports-fans','Sports fans','🏏','Cricket, football and match-day watch parties.',180),
 ('nightlife','Nightlife','🌙','Live music, comedy nights and evenings out with good company.',190),
 ('sober-curious','Sober & mindful drinking','🍵','Alcohol-free socials, mocktails and clear-headed fun.',200),
 ('parents-family','Parents & family','👨‍👩‍👧','Single parents, family days out and parenting support.',210),
 ('lgbtq-community','LGBTQ+ community','🏳️‍🌈','A warm, safe space for LGBTQ+ members and allies.',220),
 ('culture-heritage','Culture & heritage','🪔','Festivals, languages, food and traditions from home.',230),
 ('new-in-town','New in town','🧭','Just moved? Find your people and your new favourite places.',240),
 ('social','Friends & socials','✨','Easygoing meetups, brunches and making new friends.',250)
ON CONFLICT (slug) DO NOTHING;

ALTER TABLE matching.community_groups ADD COLUMN IF NOT EXISTS kind TEXT NOT NULL DEFAULT 'private';
ALTER TABLE matching.community_groups ADD COLUMN IF NOT EXISTS category_slug TEXT REFERENCES matching.group_categories(slug) ON UPDATE CASCADE;
ALTER TABLE matching.community_groups ADD COLUMN IF NOT EXISTS cover_emoji TEXT;
ALTER TABLE matching.community_groups ADD COLUMN IF NOT EXISTS cover_color TEXT;
ALTER TABLE matching.community_groups ADD COLUMN IF NOT EXISTS member_cap INTEGER NOT NULL DEFAULT 200;
ALTER TABLE matching.community_groups ALTER COLUMN city SET DEFAULT '';
ALTER TABLE matching.community_groups ALTER COLUMN topic SET DEFAULT '';

-- Backfill: public groups become community groups in the general category.
UPDATE matching.community_groups SET kind='community' WHERE visibility='public' AND kind<>'community';
UPDATE matching.community_groups SET category_slug='social' WHERE kind='community' AND category_slug IS NULL;

ALTER TABLE matching.community_groups DROP CONSTRAINT IF EXISTS community_groups_kind_check;
ALTER TABLE matching.community_groups ADD CONSTRAINT community_groups_kind_check CHECK (kind IN ('community','private'));
ALTER TABLE matching.community_groups DROP CONSTRAINT IF EXISTS community_groups_category_required;
ALTER TABLE matching.community_groups ADD CONSTRAINT community_groups_category_required CHECK (kind='private' OR category_slug IS NOT NULL);
ALTER TABLE matching.community_groups DROP CONSTRAINT IF EXISTS community_groups_cover_color_check;
-- Cover colours name theme roles; the app resolves them from the member's theme.
ALTER TABLE matching.community_groups ADD CONSTRAINT community_groups_cover_color_check CHECK (cover_color IS NULL OR cover_color IN ('primary','secondary','tertiary'));
ALTER TABLE matching.community_groups DROP CONSTRAINT IF EXISTS community_groups_cover_emoji_check;
ALTER TABLE matching.community_groups ADD CONSTRAINT community_groups_cover_emoji_check CHECK (cover_emoji IS NULL OR char_length(cover_emoji) BETWEEN 1 AND 16);
ALTER TABLE matching.community_groups DROP CONSTRAINT IF EXISTS community_groups_member_cap_check;
ALTER TABLE matching.community_groups ADD CONSTRAINT community_groups_member_cap_check CHECK (member_cap BETWEEN 2 AND 500);

CREATE INDEX IF NOT EXISTS idx_community_groups_discover ON matching.community_groups(category_slug,updated_at DESC) WHERE kind='community';
CREATE INDEX IF NOT EXISTS idx_community_group_members_active ON matching.community_group_members(group_id,joined_at) WHERE status='active';
CREATE INDEX IF NOT EXISTS idx_community_group_invites_pending ON matching.community_group_invites(invitee_user_id,invited_at DESC) WHERE status='pending';

INSERT INTO matching.platform_feature_flags(key,value_bool,description,updated_by) VALUES
 ('groups_enabled',TRUE,'Lifestyle community groups and private friend groups with group chat','migration_118')
ON CONFLICT (key) DO NOTHING;

INSERT INTO public.schema_migrations(version) VALUES('118_lifestyle_groups') ON CONFLICT DO NOTHING;
COMMIT;
