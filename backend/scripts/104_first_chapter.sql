BEGIN;
CREATE TABLE IF NOT EXISTS matching.first_chapters (
 id UUID PRIMARY KEY,
 match_id UUID NOT NULL REFERENCES matching.matches(id) ON DELETE CASCADE,
 creator_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
 scene TEXT NOT NULL,
 beginning TEXT NOT NULL,
 surprise TEXT NOT NULL DEFAULT '',
 closed BOOLEAN NOT NULL DEFAULT FALSE,
 version INTEGER NOT NULL DEFAULT 1,
 created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
 updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE UNIQUE INDEX IF NOT EXISTS one_open_chapter ON matching.first_chapters(match_id) WHERE NOT closed;
CREATE TABLE IF NOT EXISTS matching.chapter_green_lights (
 id UUID NOT NULL UNIQUE DEFAULT gen_random_uuid(),
 match_id UUID NOT NULL REFERENCES matching.matches(id) ON DELETE CASCADE,
 user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
 choices JSONB NOT NULL DEFAULT '[]',
 expires_at TIMESTAMPTZ NOT NULL,
 version INTEGER NOT NULL DEFAULT 1,
 PRIMARY KEY(match_id,user_id)
);
CREATE TABLE IF NOT EXISTS matching.comfort_cards (
 user_id UUID PRIMARY KEY REFERENCES user_management.users(id) ON DELETE CASCADE,
 cards JSONB NOT NULL DEFAULT '[]',
 shared BOOLEAN NOT NULL DEFAULT FALSE,
 version INTEGER NOT NULL DEFAULT 1,
 updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TABLE IF NOT EXISTS matching.chapter_publications (
 id UUID PRIMARY KEY,
 owner_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
 partner_id UUID REFERENCES user_management.users(id) ON DELETE CASCADE,
 chapter_id UUID REFERENCES matching.first_chapters(id) ON DELETE CASCADE,
 scene TEXT NOT NULL,
 beginning TEXT NOT NULL,
 surprise TEXT NOT NULL DEFAULT '',
 owner_approved BOOLEAN NOT NULL DEFAULT TRUE,
 partner_approved BOOLEAN NOT NULL DEFAULT FALSE,
 revoked BOOLEAN NOT NULL DEFAULT FALSE,
 version INTEGER NOT NULL DEFAULT 1,
 created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
 CHECK((partner_id IS NULL AND chapter_id IS NULL AND surprise='') OR
       (partner_id IS NOT NULL AND chapter_id IS NOT NULL))
);
CREATE INDEX IF NOT EXISTS chapter_publication_owner ON matching.chapter_publications(owner_id);
CREATE INDEX IF NOT EXISTS chapter_publication_partner ON matching.chapter_publications(partner_id);
DO $$
DECLARE item TEXT;
BEGIN
 FOREACH item IN ARRAY ARRAY['first_chapters','chapter_green_lights','comfort_cards','chapter_publications'] LOOP
  PERFORM platform.register_event_source('matching',item,'chapter.'||item);
  INSERT INTO platform.aggregate_ownership(aggregate_type,owner_component,source_schema,source_table,transaction_boundary,recovery_strategy)
  VALUES('chapter.'||item,'mobile-bff.first-chapter','matching',item,'member or match lock; atomic row and field-names-only outbox','UUID creation retries; versioned transitions; authoritative reread') ON CONFLICT DO NOTHING;
  INSERT INTO platform.required_aggregates(aggregate_type) VALUES('chapter.'||item) ON CONFLICT DO NOTHING;
 END LOOP;
END $$;
INSERT INTO public.schema_migrations(version) VALUES('104_first_chapter') ON CONFLICT DO NOTHING;
COMMIT;
