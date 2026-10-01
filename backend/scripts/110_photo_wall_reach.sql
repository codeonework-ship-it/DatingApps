-- Likes, author-approved comments and tiered wall reach for Photo Theme
-- photos, matching the rules chapters follow (migrations 108 and 109).
BEGIN;

ALTER TABLE matching.photo_theme_entries ADD COLUMN IF NOT EXISTS allow_featuring BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE matching.photo_theme_entries ADD COLUMN IF NOT EXISTS wall_tier SMALLINT NOT NULL DEFAULT 0 CHECK(wall_tier>=0);
ALTER TABLE matching.photo_theme_entries ADD COLUMN IF NOT EXISTS featured_at TIMESTAMPTZ;

CREATE TABLE IF NOT EXISTS matching.photo_entry_likes (
 entry_id UUID NOT NULL REFERENCES matching.photo_theme_entries(id) ON DELETE CASCADE,
 user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
 created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
 PRIMARY KEY(entry_id,user_id)
);
CREATE INDEX IF NOT EXISTS photo_entry_likes_user ON matching.photo_entry_likes(user_id,created_at DESC);

CREATE TABLE IF NOT EXISTS matching.photo_entry_comments (
 id UUID PRIMARY KEY,
 entry_id UUID NOT NULL REFERENCES matching.photo_theme_entries(id) ON DELETE CASCADE,
 author_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
 owner_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
 body TEXT NOT NULL CHECK(char_length(body) <= 500),
 status TEXT NOT NULL DEFAULT 'pending' CHECK(status IN ('pending','approved','declined')),
 moderation_state TEXT NOT NULL DEFAULT 'active' CHECK(moderation_state IN ('active','removed')),
 version INTEGER NOT NULL DEFAULT 1 CHECK(version>0),
 created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
 decided_at TIMESTAMPTZ,
 deleted_at TIMESTAMPTZ,
 CHECK(author_id<>owner_id)
);
CREATE INDEX IF NOT EXISTS photo_entry_comments_entry ON matching.photo_entry_comments(entry_id,status,created_at) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS photo_entry_comments_author ON matching.photo_entry_comments(author_id,created_at DESC);

CREATE TABLE IF NOT EXISTS matching.photo_wall_deliveries (
 entry_id UUID NOT NULL REFERENCES matching.photo_theme_entries(id) ON DELETE CASCADE,
 recipient_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
 tier SMALLINT NOT NULL CHECK(tier>=1),
 delivered_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
 PRIMARY KEY(entry_id,recipient_id)
);
CREATE INDEX IF NOT EXISTS photo_wall_deliveries_recipient ON matching.photo_wall_deliveries(recipient_id,delivered_at DESC);

ALTER TABLE matching.blog_cases DROP CONSTRAINT IF EXISTS blog_cases_content_type_check;
ALTER TABLE matching.blog_cases ADD CONSTRAINT blog_cases_content_type_check
 CHECK(content_type IN ('post','response','publication','theme_entry','club','club_post','review','list','comment','photo_comment'));

DO $$ DECLARE item TEXT; BEGIN
 FOREACH item IN ARRAY ARRAY['photo_entry_likes','photo_entry_comments','photo_wall_deliveries'] LOOP
  PERFORM platform.register_event_source('matching',item,'themes.'||item);
  INSERT INTO platform.aggregate_ownership(aggregate_type,owner_component,source_schema,source_table,transaction_boundary,recovery_strategy)
  VALUES('themes.'||item,'mobile-bff.themes','matching',item,'member lock then entry; atomic with tier change','stable command UUIDs; idempotent likes and deliveries; privacy-checked readback') ON CONFLICT DO NOTHING;
  INSERT INTO platform.required_aggregates(aggregate_type) VALUES('themes.'||item) ON CONFLICT DO NOTHING;
 END LOOP;
END $$;

INSERT INTO public.schema_migrations(version) VALUES('110_photo_wall_reach') ON CONFLICT DO NOTHING;
COMMIT;
