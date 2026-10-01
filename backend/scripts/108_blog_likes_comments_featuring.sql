-- Blog likes, author-approved comments and Featured Stories.
--
-- Featuring is opt-in per chapter (allow_featuring) and only ever applies to
-- community chapters. featured_at records the first time a chapter qualified
-- so the author is notified once; whether it is on the wall is re-evaluated on
-- every read (opt-out, open reports and moderation take effect immediately).
BEGIN;

ALTER TABLE matching.blog_posts ADD COLUMN IF NOT EXISTS allow_featuring BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE matching.blog_posts ADD COLUMN IF NOT EXISTS featured_at TIMESTAMPTZ;
CREATE INDEX IF NOT EXISTS blog_posts_featured ON matching.blog_posts(featured_at DESC)
 WHERE featured_at IS NOT NULL AND deleted_at IS NULL;

CREATE TABLE IF NOT EXISTS matching.blog_likes (
 post_id UUID NOT NULL REFERENCES matching.blog_posts(id) ON DELETE CASCADE,
 user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
 created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
 PRIMARY KEY(post_id,user_id)
);
CREATE INDEX IF NOT EXISTS blog_likes_user ON matching.blog_likes(user_id,created_at DESC);

CREATE TABLE IF NOT EXISTS matching.blog_comments (
 id UUID PRIMARY KEY,
 post_id UUID NOT NULL REFERENCES matching.blog_posts(id) ON DELETE CASCADE,
 author_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
 post_author_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
 body TEXT NOT NULL CHECK(char_length(body) <= 500),
 status TEXT NOT NULL DEFAULT 'pending' CHECK(status IN ('pending','approved','declined')),
 moderation_state TEXT NOT NULL DEFAULT 'active' CHECK(moderation_state IN ('active','removed')),
 version INTEGER NOT NULL DEFAULT 1 CHECK(version>0),
 created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
 decided_at TIMESTAMPTZ,
 deleted_at TIMESTAMPTZ,
 CHECK(author_id<>post_author_id)
);
CREATE INDEX IF NOT EXISTS blog_comments_post ON matching.blog_comments(post_id,status,created_at) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS blog_comments_author ON matching.blog_comments(author_id,created_at DESC);

ALTER TABLE matching.blog_cases DROP CONSTRAINT IF EXISTS blog_cases_content_type_check;
ALTER TABLE matching.blog_cases ADD CONSTRAINT blog_cases_content_type_check
 CHECK(content_type IN ('post','response','publication','theme_entry','club','club_post','review','list','comment'));

DO $$ DECLARE item TEXT; BEGIN
 FOREACH item IN ARRAY ARRAY['blog_likes','blog_comments'] LOOP
  PERFORM platform.register_event_source('matching',item,'blog.'||item);
  INSERT INTO platform.aggregate_ownership(aggregate_type,owner_component,source_schema,source_table,transaction_boundary,recovery_strategy)
  VALUES('blog.'||item,'mobile-bff.blog','matching',item,'member lock then post; atomic state and metadata-only outbox','stable command UUIDs; idempotent like toggles; privacy-checked readback') ON CONFLICT DO NOTHING;
  INSERT INTO platform.required_aggregates(aggregate_type) VALUES('blog.'||item) ON CONFLICT DO NOTHING;
 END LOOP;
END $$;

INSERT INTO public.schema_migrations(version) VALUES('108_blog_likes_comments_featuring') ON CONFLICT DO NOTHING;
COMMIT;
