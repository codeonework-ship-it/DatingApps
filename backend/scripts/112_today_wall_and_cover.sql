-- Today wall carousel (up to 10 picks per member per day) and Cover of the
-- Week (one photo per ISO week). Both rank by likes, approved comments and
-- unique views, with random tie-breaks, and persist their choice so it stays
-- fixed for the day or week and unchosen items get their turn later.
BEGIN;

CREATE TABLE IF NOT EXISTS matching.content_views (
 kind TEXT NOT NULL CHECK(kind IN ('chapter','photo')),
 content_id UUID NOT NULL,
 viewer_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
 first_viewed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
 PRIMARY KEY(kind,content_id,viewer_id)
);
CREATE INDEX IF NOT EXISTS content_views_viewer ON matching.content_views(viewer_id,first_viewed_at DESC);

CREATE TABLE IF NOT EXISTS matching.wall_daily_picks (
 recipient_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
 day DATE NOT NULL,
 kind TEXT NOT NULL CHECK(kind IN ('chapter','photo')),
 content_id UUID NOT NULL,
 position SMALLINT NOT NULL CHECK(position BETWEEN 1 AND 10),
 created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
 PRIMARY KEY(recipient_id,day,kind,content_id),
 UNIQUE(recipient_id,day,position)
);
CREATE INDEX IF NOT EXISTS wall_daily_picks_history ON matching.wall_daily_picks(recipient_id,kind,content_id);

CREATE TABLE IF NOT EXISTS matching.photo_covers (
 week_start DATE PRIMARY KEY CHECK(EXTRACT(ISODOW FROM week_start)=1),
 entry_id UUID NOT NULL UNIQUE REFERENCES matching.photo_theme_entries(id) ON DELETE CASCADE,
 chosen_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE matching.wall_celebrations DROP CONSTRAINT IF EXISTS wall_celebrations_kind_check;
ALTER TABLE matching.wall_celebrations ADD CONSTRAINT wall_celebrations_kind_check CHECK(kind IN ('chapter','photo','cover'));
ALTER TABLE matching.wall_celebrations DROP CONSTRAINT IF EXISTS wall_celebrations_reach_check;
ALTER TABLE matching.wall_celebrations ADD CONSTRAINT wall_celebrations_reach_check CHECK(reach>=0);

DO $$ DECLARE item TEXT; BEGIN
 FOREACH item IN ARRAY ARRAY['content_views','wall_daily_picks','photo_covers'] LOOP
  PERFORM platform.register_event_source('matching',item,'walls.'||item);
  INSERT INTO platform.aggregate_ownership(aggregate_type,owner_component,source_schema,source_table,transaction_boundary,recovery_strategy)
  VALUES('walls.'||item,'mobile-bff.walls','matching',item,'single insert per member, day or week; first writer wins','idempotent inserts; re-read the persisted choice') ON CONFLICT DO NOTHING;
  INSERT INTO platform.required_aggregates(aggregate_type) VALUES('walls.'||item) ON CONFLICT DO NOTHING;
 END LOOP;
END $$;

INSERT INTO public.schema_migrations(version) VALUES('112_today_wall_and_cover') ON CONFLICT DO NOTHING;
COMMIT;
