-- Tiered wall reach for Featured Stories.
--
-- A community chapter whose author allowed featuring reaches more members as
-- readers engage: by default 50 likes + 5 approved comments reach 50 members'
-- walls and 100 likes + 10 comments reach 100 (tiers are configured in the
-- BFF). Each delivery is recorded once per member so reach only grows, the
-- wall query is a cheap lookup, and erasure can remove a member's deliveries.
BEGIN;

ALTER TABLE matching.blog_posts ADD COLUMN IF NOT EXISTS wall_tier SMALLINT NOT NULL DEFAULT 0 CHECK(wall_tier>=0);

CREATE TABLE IF NOT EXISTS matching.blog_wall_deliveries (
 post_id UUID NOT NULL REFERENCES matching.blog_posts(id) ON DELETE CASCADE,
 recipient_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
 tier SMALLINT NOT NULL CHECK(tier>=1),
 delivered_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
 PRIMARY KEY(post_id,recipient_id)
);
CREATE INDEX IF NOT EXISTS blog_wall_deliveries_recipient
 ON matching.blog_wall_deliveries(recipient_id,delivered_at DESC);

DO $$ BEGIN
 PERFORM platform.register_event_source('matching','blog_wall_deliveries','blog.blog_wall_deliveries');
 INSERT INTO platform.aggregate_ownership(aggregate_type,owner_component,source_schema,source_table,transaction_boundary,recovery_strategy)
 VALUES('blog.blog_wall_deliveries','mobile-bff.blog','matching','blog_wall_deliveries','post lock then idempotent recipient inserts; atomic with tier change','re-evaluate tier on next like or approval; deliveries never duplicate') ON CONFLICT DO NOTHING;
 INSERT INTO platform.required_aggregates(aggregate_type) VALUES('blog.blog_wall_deliveries') ON CONFLICT DO NOTHING;
END $$;

INSERT INTO public.schema_migrations(version) VALUES('109_blog_wall_reach_tiers') ON CONFLICT DO NOTHING;
COMMIT;
