-- Member-authored Chapters. Media is private and served only after post access checks.
BEGIN;
CREATE TABLE IF NOT EXISTS matching.blog_posts (
 id UUID PRIMARY KEY,
 author_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
 title TEXT NOT NULL DEFAULT '' CHECK(char_length(title)<=100),
 body TEXT NOT NULL DEFAULT '' CHECK(char_length(body)<=8000),
 audience TEXT NOT NULL DEFAULT 'private' CHECK(audience IN ('private','friends','community')),
 invitation TEXT NOT NULL DEFAULT '' CHECK(invitation IN ('','your_version','teach_me','what_next')),
 version INTEGER NOT NULL DEFAULT 1 CHECK(version>0),
 created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
 updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
 published_at TIMESTAMPTZ,
 deleted_at TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS blog_posts_author ON matching.blog_posts(author_id,created_at DESC,id DESC) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS blog_posts_feed ON matching.blog_posts(created_at DESC,id DESC) WHERE deleted_at IS NULL AND audience <> 'private';
CREATE TABLE IF NOT EXISTS matching.blog_photos (
 id UUID PRIMARY KEY,
 post_id UUID NOT NULL REFERENCES matching.blog_posts(id) ON DELETE CASCADE,
 author_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
 alt_text TEXT NOT NULL CHECK(char_length(alt_text) BETWEEN 1 AND 160),
 storage_path TEXT NOT NULL,
 mime_type TEXT NOT NULL CHECK(mime_type IN ('image/jpeg','image/png')),
 size_bytes BIGINT NOT NULL CHECK(size_bytes>0 AND size_bytes<=10485760),
 content_sha256 TEXT NOT NULL,
 moderation_status TEXT NOT NULL CHECK(moderation_status IN ('approved','rejected')),
 moderation_provider TEXT NOT NULL,
 created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
 deleted_at TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS blog_photos_post ON matching.blog_photos(post_id,created_at,id);
DO $$
DECLARE item TEXT;
BEGIN
 FOREACH item IN ARRAY ARRAY['blog_posts','blog_photos'] LOOP
  PERFORM platform.register_event_source('matching',item,'blog.'||item);
  INSERT INTO platform.aggregate_ownership(aggregate_type,owner_component,source_schema,source_table,transaction_boundary,recovery_strategy)
  VALUES('blog.'||item,'mobile-bff.blog','matching',item,'author then post lock; atomic state and metadata-only outbox','stable UUID commands; expected versions; authoritative readback; private media cleanup') ON CONFLICT DO NOTHING;
  INSERT INTO platform.required_aggregates(aggregate_type) VALUES('blog.'||item) ON CONFLICT DO NOTHING;
 END LOOP;
END $$;
INSERT INTO public.schema_migrations(version) VALUES('105_member_blogging') ON CONFLICT DO NOTHING;
COMMIT;
