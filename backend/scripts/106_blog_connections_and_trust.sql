BEGIN;
ALTER TABLE matching.blog_posts ADD COLUMN IF NOT EXISTS moderation_state TEXT NOT NULL DEFAULT 'active' CHECK(moderation_state IN ('active','removed'));
CREATE TABLE IF NOT EXISTS matching.blog_responses (
 id UUID PRIMARY KEY,
 post_id UUID NOT NULL REFERENCES matching.blog_posts(id) ON DELETE CASCADE,
 sender_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
 author_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
 text TEXT NOT NULL CHECK(char_length(text) BETWEEN 1 AND 600),
 status TEXT NOT NULL DEFAULT 'pending' CHECK(status IN ('pending','accepted','declined','withdrawn')),
 sender_story TEXT NOT NULL DEFAULT '' CHECK(char_length(sender_story)<=1000),
 author_story TEXT NOT NULL DEFAULT '' CHECK(char_length(author_story)<=1000),
 sender_contributed_at TIMESTAMPTZ,
 author_contributed_at TIMESTAMPTZ,
 moderation_state TEXT NOT NULL DEFAULT 'active' CHECK(moderation_state IN ('active','removed')),
 version INTEGER NOT NULL DEFAULT 1 CHECK(version>0),
 created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
 updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
 CHECK(sender_id<>author_id), UNIQUE(post_id,sender_id)
);
CREATE INDEX IF NOT EXISTS blog_responses_sender ON matching.blog_responses(sender_id,created_at DESC,id DESC);
CREATE INDEX IF NOT EXISTS blog_responses_author ON matching.blog_responses(author_id,created_at DESC,id DESC);
CREATE TABLE IF NOT EXISTS matching.blog_publications (
 id UUID PRIMARY KEY,
 post_id UUID NOT NULL REFERENCES matching.blog_posts(id) ON DELETE CASCADE,
 response_id UUID REFERENCES matching.blog_responses(id) ON DELETE CASCADE,
 owner_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
 partner_id UUID REFERENCES user_management.users(id) ON DELETE CASCADE,
 title TEXT NOT NULL CHECK(char_length(title) BETWEEN 1 AND 100),
 excerpt TEXT NOT NULL CHECK(char_length(excerpt) BETWEEN 1 AND 2200),
 photo_ids UUID[] NOT NULL DEFAULT '{}' CHECK(cardinality(photo_ids)<=6),
 source_version INTEGER NOT NULL,
 owner_approved BOOLEAN NOT NULL DEFAULT TRUE,
 partner_approved BOOLEAN NOT NULL DEFAULT FALSE,
 revoked BOOLEAN NOT NULL DEFAULT FALSE,
 moderation_state TEXT NOT NULL DEFAULT 'active' CHECK(moderation_state IN ('active','removed')),
 version INTEGER NOT NULL DEFAULT 1 CHECK(version>0),
 created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
 CHECK((response_id IS NULL AND partner_id IS NULL) OR (response_id IS NOT NULL AND partner_id IS NOT NULL AND cardinality(photo_ids)=0)),
 CHECK(partner_id IS NULL OR partner_id<>owner_id)
);
CREATE INDEX IF NOT EXISTS blog_publications_owner ON matching.blog_publications(owner_id,created_at DESC);
CREATE INDEX IF NOT EXISTS blog_publications_partner ON matching.blog_publications(partner_id,created_at DESC);
CREATE TABLE IF NOT EXISTS matching.blog_cases (
 id UUID PRIMARY KEY,
 content_type TEXT NOT NULL CHECK(content_type IN ('post','response','publication')),
 content_id UUID NOT NULL,
 subject_id UUID NOT NULL REFERENCES user_management.users(id),
 reporter_id UUID REFERENCES user_management.users(id) ON DELETE SET NULL,
 reporter_key TEXT NOT NULL,
 reason TEXT NOT NULL CHECK(reason IN ('harassment','inappropriate','fraud','fake')),
 description TEXT NOT NULL DEFAULT '' CHECK(char_length(description)<=1000),
 snapshot JSONB NOT NULL,
 photo_ids UUID[] NOT NULL DEFAULT '{}',
 status TEXT NOT NULL DEFAULT 'pending' CHECK(status IN ('pending','dismissed','removed','restored')),
 decision_note TEXT NOT NULL DEFAULT '',
 appeal TEXT NOT NULL DEFAULT '' CHECK(char_length(appeal)<=1000),
 version INTEGER NOT NULL DEFAULT 1,
 created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
 review_due_at TIMESTAMPTZ NOT NULL DEFAULT NOW()+INTERVAL '24 hours',
 resolved_at TIMESTAMPTZ,
 evidence_purged_at TIMESTAMPTZ,
 UNIQUE(content_type,content_id,reporter_key)
);
CREATE INDEX IF NOT EXISTS blog_cases_queue ON matching.blog_cases(status,review_due_at,id);
CREATE TABLE IF NOT EXISTS matching.blog_case_actions (
 id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
 case_id UUID NOT NULL REFERENCES matching.blog_cases(id),
 actor_id UUID NOT NULL REFERENCES user_management.users(id),
 action TEXT NOT NULL CHECK(action IN ('dismissed','removed','restored','appealed')),
 note TEXT NOT NULL CHECK(char_length(note) BETWEEN 1 AND 1000),
 created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TABLE IF NOT EXISTS matching.blog_evidence_photos (
 case_id UUID NOT NULL REFERENCES matching.blog_cases(id) ON DELETE CASCADE,
 photo_id UUID NOT NULL,
 storage_path TEXT NOT NULL,
 alt_text TEXT NOT NULL,
 mime_type TEXT NOT NULL,
 PRIMARY KEY(case_id,photo_id)
);
ALTER TABLE matching.match_date_plans ADD COLUMN IF NOT EXISTS source_blog_response_id UUID REFERENCES matching.blog_responses(id) ON DELETE SET NULL;
DO $$ DECLARE item TEXT; BEGIN
 FOREACH item IN ARRAY ARRAY['blog_responses','blog_publications','blog_cases','blog_case_actions','blog_evidence_photos'] LOOP
  PERFORM platform.register_event_source('matching',item,'blog.'||item);
  INSERT INTO platform.aggregate_ownership(aggregate_type,owner_component,source_schema,source_table,transaction_boundary,recovery_strategy)
  VALUES('blog.'||item,'mobile-bff.blog','matching',item,'ordered member locks then source aggregate; atomic state and metadata-only outbox','stable command UUID, expected version, privacy checked readback') ON CONFLICT DO NOTHING;
  INSERT INTO platform.required_aggregates(aggregate_type) VALUES('blog.'||item) ON CONFLICT DO NOTHING;
 END LOOP;
END $$;
-- Durable retries for private evidence object deletion, including object stores.
CREATE TABLE IF NOT EXISTS matching.blog_media_deletions (
 storage_path text PRIMARY KEY, created_at timestamptz NOT NULL DEFAULT NOW()
);

INSERT INTO public.schema_migrations(version) VALUES('106_blog_connections_and_trust') ON CONFLICT DO NOTHING;
COMMIT;

