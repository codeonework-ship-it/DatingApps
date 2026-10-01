-- Rose rain: one celebration per new wall tier, played once on the author's
-- next app open and then marked seen. Recorded in the same transaction that
-- advances the tier, so a celebration exists exactly when a tier was reached.
BEGIN;

CREATE TABLE IF NOT EXISTS matching.wall_celebrations (
 id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
 author_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
 kind TEXT NOT NULL CHECK(kind IN ('chapter','photo')),
 content_id UUID NOT NULL,
 tier SMALLINT NOT NULL CHECK(tier>=1),
 reach INTEGER NOT NULL CHECK(reach>=1),
 title TEXT NOT NULL DEFAULT '' CHECK(char_length(title)<=120),
 created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
 seen_at TIMESTAMPTZ,
 UNIQUE(kind,content_id,tier)
);
CREATE INDEX IF NOT EXISTS wall_celebrations_unseen ON matching.wall_celebrations(author_id,created_at DESC) WHERE seen_at IS NULL;

DO $$ BEGIN
 PERFORM platform.register_event_source('matching','wall_celebrations','walls.wall_celebrations');
 INSERT INTO platform.aggregate_ownership(aggregate_type,owner_component,source_schema,source_table,transaction_boundary,recovery_strategy)
 VALUES('walls.wall_celebrations','mobile-bff.walls','matching','wall_celebrations','written with the tier change; seen by the author only','unique per content and tier; seen is idempotent') ON CONFLICT DO NOTHING;
 INSERT INTO platform.required_aggregates(aggregate_type) VALUES('walls.wall_celebrations') ON CONFLICT DO NOTHING;
END $$;

INSERT INTO public.schema_migrations(version) VALUES('111_wall_celebrations') ON CONFLICT DO NOTHING;
COMMIT;
