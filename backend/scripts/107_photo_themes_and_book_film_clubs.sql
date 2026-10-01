-- Photo Themes and Book & Film Clubs.
--
-- Photo Themes: one moderated photo per member per operator-authored prompt.
-- Clubs: member-run book or film clubs with a weekly pick, a discussion per
-- pick, title reviews and personal lists. All member content is reportable
-- through the existing Open Chapters case queue (matching.blog_cases).
BEGIN;

CREATE TABLE IF NOT EXISTS matching.photo_themes (
 id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
 slug TEXT NOT NULL UNIQUE CHECK(slug ~ '^[a-z0-9][a-z0-9-]{2,47}$'),
 title TEXT NOT NULL CHECK(char_length(title) BETWEEN 3 AND 60),
 prompt TEXT NOT NULL CHECK(char_length(prompt) BETWEEN 3 AND 200),
 status TEXT NOT NULL DEFAULT 'active' CHECK(status IN ('active','archived')),
 sort_order INTEGER NOT NULL DEFAULT 0,
 updated_by TEXT NOT NULL DEFAULT 'migration_107',
 created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
 updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS matching.photo_theme_entries (
 id UUID PRIMARY KEY,
 theme_id UUID NOT NULL REFERENCES matching.photo_themes(id),
 author_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
 caption TEXT NOT NULL CHECK(char_length(caption) <= 280),
 alt_text TEXT NOT NULL CHECK(char_length(alt_text) <= 160),
 storage_path TEXT NOT NULL,
 mime_type TEXT NOT NULL CHECK(mime_type IN ('image/jpeg','image/png')),
 size_bytes BIGINT NOT NULL CHECK(size_bytes>0 AND size_bytes<=10485760),
 content_sha256 TEXT NOT NULL,
 moderation_status TEXT NOT NULL CHECK(moderation_status='approved'),
 moderation_provider TEXT NOT NULL,
 moderation_state TEXT NOT NULL DEFAULT 'active' CHECK(moderation_state IN ('active','removed')),
 version INTEGER NOT NULL DEFAULT 1 CHECK(version>0),
 created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
 deleted_at TIMESTAMPTZ
);
CREATE UNIQUE INDEX IF NOT EXISTS photo_theme_entries_one_live_per_member
 ON matching.photo_theme_entries(theme_id,author_id) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS photo_theme_entries_gallery
 ON matching.photo_theme_entries(theme_id,created_at DESC,id DESC) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS photo_theme_entries_author
 ON matching.photo_theme_entries(author_id,created_at DESC);

INSERT INTO matching.photo_themes(slug,title,prompt,sort_order) VALUES
 ('perfect-sunday','My perfect Sunday','Show us what an unhurried Sunday looks like for you.',10),
 ('something-i-made','Something I made','A meal, a sketch, a shelf, a playlist cover. Anything you made with your hands.',20),
 ('view-i-love','A view I love','The window, street or skyline you would show someone on a first walk.',30),
 ('comfort-food','Comfort food','The dish you reach for after a long week.',40),
 ('where-i-feel-like-me','Where I feel most like me','A place that says more about you than a bio could.',50),
 ('little-ritual','A little ritual','The small daily thing you would not skip.',60)
ON CONFLICT (slug) DO NOTHING;

CREATE TABLE IF NOT EXISTS matching.clubs (
 id UUID PRIMARY KEY,
 kind TEXT NOT NULL CHECK(kind IN ('book','film')),
 name TEXT NOT NULL CHECK(char_length(name) BETWEEN 3 AND 60),
 description TEXT NOT NULL DEFAULT '' CHECK(char_length(description) <= 500),
 owner_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
 moderation_state TEXT NOT NULL DEFAULT 'active' CHECK(moderation_state IN ('active','removed')),
 version INTEGER NOT NULL DEFAULT 1 CHECK(version>0),
 created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
 updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
 deleted_at TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS clubs_discover ON matching.clubs(kind,created_at DESC,id DESC) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS clubs_owner ON matching.clubs(owner_id) WHERE deleted_at IS NULL;

CREATE TABLE IF NOT EXISTS matching.club_members (
 club_id UUID NOT NULL REFERENCES matching.clubs(id) ON DELETE CASCADE,
 user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
 role TEXT NOT NULL DEFAULT 'member' CHECK(role IN ('owner','moderator','member')),
 status TEXT NOT NULL DEFAULT 'active' CHECK(status IN ('active','left','removed')),
 joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
 updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
 PRIMARY KEY(club_id,user_id)
);
CREATE INDEX IF NOT EXISTS club_members_user ON matching.club_members(user_id,status);
CREATE UNIQUE INDEX IF NOT EXISTS club_members_one_owner ON matching.club_members(club_id) WHERE role='owner' AND status='active';

CREATE TABLE IF NOT EXISTS matching.club_titles (
 id UUID PRIMARY KEY,
 kind TEXT NOT NULL CHECK(kind IN ('book','film')),
 title TEXT NOT NULL CHECK(char_length(title) BETWEEN 1 AND 200),
 creator TEXT NOT NULL DEFAULT '' CHECK(char_length(creator) <= 120),
 release_year INTEGER CHECK(release_year IS NULL OR release_year BETWEEN 1450 AND 2100),
 normalized_key TEXT NOT NULL UNIQUE,
 created_by UUID REFERENCES user_management.users(id) ON DELETE SET NULL,
 created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS club_titles_search ON matching.club_titles(kind,lower(title));

CREATE TABLE IF NOT EXISTS matching.club_selections (
 id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
 club_id UUID NOT NULL REFERENCES matching.clubs(id) ON DELETE CASCADE,
 title_id UUID NOT NULL REFERENCES matching.club_titles(id),
 week_start DATE NOT NULL CHECK(EXTRACT(ISODOW FROM week_start)=1),
 note TEXT NOT NULL DEFAULT '' CHECK(char_length(note) <= 280),
 chosen_by UUID REFERENCES user_management.users(id) ON DELETE SET NULL,
 created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
 updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
 UNIQUE(club_id,week_start)
);

CREATE TABLE IF NOT EXISTS matching.club_posts (
 id UUID PRIMARY KEY,
 club_id UUID NOT NULL REFERENCES matching.clubs(id) ON DELETE CASCADE,
 selection_id UUID NOT NULL REFERENCES matching.club_selections(id) ON DELETE CASCADE,
 author_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
 body TEXT NOT NULL CHECK(char_length(body) <= 2000),
 has_spoilers BOOLEAN NOT NULL DEFAULT FALSE,
 hidden_at TIMESTAMPTZ,
 hidden_by UUID REFERENCES user_management.users(id) ON DELETE SET NULL,
 moderation_state TEXT NOT NULL DEFAULT 'active' CHECK(moderation_state IN ('active','removed')),
 version INTEGER NOT NULL DEFAULT 1 CHECK(version>0),
 created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
 deleted_at TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS club_posts_thread ON matching.club_posts(selection_id,created_at,id) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS club_posts_author_day ON matching.club_posts(author_id,club_id,created_at);

CREATE TABLE IF NOT EXISTS matching.title_reviews (
 id UUID PRIMARY KEY,
 title_id UUID NOT NULL REFERENCES matching.club_titles(id),
 author_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
 rating SMALLINT NOT NULL CHECK(rating BETWEEN 1 AND 5),
 body TEXT NOT NULL DEFAULT '' CHECK(char_length(body) <= 4000),
 has_spoilers BOOLEAN NOT NULL DEFAULT FALSE,
 audience TEXT NOT NULL DEFAULT 'private' CHECK(audience IN ('private','friends','community')),
 moderation_state TEXT NOT NULL DEFAULT 'active' CHECK(moderation_state IN ('active','removed')),
 version INTEGER NOT NULL DEFAULT 1 CHECK(version>0),
 created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
 updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
 deleted_at TIMESTAMPTZ
);
CREATE UNIQUE INDEX IF NOT EXISTS title_reviews_one_per_member
 ON matching.title_reviews(title_id,author_id) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS title_reviews_title ON matching.title_reviews(title_id,updated_at DESC) WHERE deleted_at IS NULL;

CREATE TABLE IF NOT EXISTS matching.member_lists (
 id UUID PRIMARY KEY,
 owner_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
 name TEXT NOT NULL CHECK(char_length(name) <= 60),
 kind TEXT NOT NULL CHECK(kind IN ('book','film')),
 audience TEXT NOT NULL DEFAULT 'private' CHECK(audience IN ('private','friends','community')),
 moderation_state TEXT NOT NULL DEFAULT 'active' CHECK(moderation_state IN ('active','removed')),
 version INTEGER NOT NULL DEFAULT 1 CHECK(version>0),
 created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
 updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
 deleted_at TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS member_lists_owner ON matching.member_lists(owner_id,created_at) WHERE deleted_at IS NULL;

CREATE TABLE IF NOT EXISTS matching.member_list_items (
 list_id UUID NOT NULL REFERENCES matching.member_lists(id) ON DELETE CASCADE,
 title_id UUID NOT NULL REFERENCES matching.club_titles(id),
 note TEXT NOT NULL DEFAULT '' CHECK(char_length(note) <= 280),
 position INTEGER NOT NULL DEFAULT 0,
 added_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
 PRIMARY KEY(list_id,title_id)
);

-- Reports for the new content flow through the existing case queue.
ALTER TABLE matching.blog_cases DROP CONSTRAINT IF EXISTS blog_cases_content_type_check;
ALTER TABLE matching.blog_cases ADD CONSTRAINT blog_cases_content_type_check
 CHECK(content_type IN ('post','response','publication','theme_entry','club','club_post','review','list'));

INSERT INTO matching.platform_feature_flags(key,value_bool,description,updated_by) VALUES
 ('photo_themes_enabled',TRUE,'Photo Themes: one moderated photo per prompt','migration_107'),
 ('clubs_enabled',TRUE,'Book & Film Clubs: weekly picks, discussion, reviews and lists','migration_107')
ON CONFLICT (key) DO NOTHING;

DO $$
DECLARE item TEXT;
BEGIN
 FOREACH item IN ARRAY ARRAY['photo_themes','photo_theme_entries'] LOOP
  PERFORM platform.register_event_source('matching',item,'themes.'||item);
  INSERT INTO platform.aggregate_ownership(aggregate_type,owner_component,source_schema,source_table,transaction_boundary,recovery_strategy)
  VALUES('themes.'||item,'mobile-bff.themes','matching',item,'author lock then entry; atomic state and metadata-only outbox','stable entry UUID plus content digest; authoritative readback; private media cleanup') ON CONFLICT DO NOTHING;
  INSERT INTO platform.required_aggregates(aggregate_type) VALUES('themes.'||item) ON CONFLICT DO NOTHING;
 END LOOP;
 FOREACH item IN ARRAY ARRAY['clubs','club_members','club_titles','club_selections','club_posts','title_reviews','member_lists','member_list_items'] LOOP
  PERFORM platform.register_event_source('matching',item,'clubs.'||item);
  INSERT INTO platform.aggregate_ownership(aggregate_type,owner_component,source_schema,source_table,transaction_boundary,recovery_strategy)
  VALUES('clubs.'||item,'mobile-bff.clubs','matching',item,'member lock then club row; atomic state and metadata-only outbox','stable command UUIDs; expected versions; privacy-checked readback') ON CONFLICT DO NOTHING;
  INSERT INTO platform.required_aggregates(aggregate_type) VALUES('clubs.'||item) ON CONFLICT DO NOTHING;
 END LOOP;
END $$;

INSERT INTO public.schema_migrations(version) VALUES('107_photo_themes_and_book_film_clubs') ON CONFLICT DO NOTHING;
COMMIT;
