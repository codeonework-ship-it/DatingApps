-- Blog topics, writer subscriptions and XP rewards for creative contributions.
BEGIN;

CREATE TABLE IF NOT EXISTS matching.blog_topics (
 slug TEXT PRIMARY KEY CHECK(slug ~ '^[a-z][a-z0-9-]{1,31}$'),
 title TEXT NOT NULL CHECK(char_length(title) BETWEEN 2 AND 40),
 description TEXT NOT NULL DEFAULT '' CHECK(char_length(description) <= 160),
 sort_order INTEGER NOT NULL DEFAULT 0,
 active BOOLEAN NOT NULL DEFAULT TRUE
);
INSERT INTO matching.blog_topics(slug,title,description,sort_order) VALUES
 ('feelings','Feelings & healing','What you are carrying, what helped, what you are still figuring out.',10),
 ('love','Love & relationships','Crushes, heartbreak, the good ones and the lessons.',20),
 ('growth','Self-growth','Habits, boundaries and the person you are becoming.',30),
 ('family','Family & friends','The people who made you and the ones you chose.',40),
 ('travel','Travel & places','Streets, trains and the places that changed you.',50),
 ('food','Food & home','Recipes, kitchens and comfort.',60),
 ('culture','Books, films & music','What you read, watched and played on repeat.',70),
 ('work','Work & ambition','Careers, side projects and big dreams.',80),
 ('humour','Funny moments','The stories you tell at dinner.',90),
 ('reflection','Faith & reflection','Belief, meaning and quiet moments.',100)
ON CONFLICT (slug) DO NOTHING;

ALTER TABLE matching.blog_posts ADD COLUMN IF NOT EXISTS topic_slug TEXT REFERENCES matching.blog_topics(slug);
CREATE INDEX IF NOT EXISTS blog_posts_topic ON matching.blog_posts(topic_slug,created_at DESC) WHERE deleted_at IS NULL AND audience<>'private';

CREATE TABLE IF NOT EXISTS matching.blog_subscriptions (
 subscriber_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
 author_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
 created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
 PRIMARY KEY(subscriber_id,author_id),
 CHECK(subscriber_id<>author_id)
);
CREATE INDEX IF NOT EXISTS blog_subscriptions_author ON matching.blog_subscriptions(author_id,created_at DESC);

-- Rewards go to creators for what readers do, never to readers for tapping.
INSERT INTO progression.xp_source_policies(source,display_name,base_xp,daily_xp_cap,daily_event_cap,cooldown_seconds) VALUES
 ('story_published','Chapter shared',25,50,2,0),
 ('photo_shared','Photo shared',20,40,2,0),
 ('like_received','Like received',2,40,20,0),
 ('comment_received','Comment received and approved',5,50,10,0),
 ('comment_approved','Your comment was approved',5,30,6,0),
 ('subscriber_gained','New follower',10,100,10,0),
 ('wall_tier_reached','Reached more walls',50,150,3,0),
 ('cover_of_week','Cover of the Week',150,150,1,0)
ON CONFLICT (source) DO NOTHING;

DO $$ DECLARE item TEXT; BEGIN
 FOREACH item IN ARRAY ARRAY['blog_topics','blog_subscriptions'] LOOP
  PERFORM platform.register_event_source('matching',item,'blog.'||item);
  INSERT INTO platform.aggregate_ownership(aggregate_type,owner_component,source_schema,source_table,transaction_boundary,recovery_strategy)
  VALUES('blog.'||item,'mobile-bff.blog','matching',item,'member lock then row; atomic with notifications and reward intents','idempotent toggles; privacy-checked readback') ON CONFLICT DO NOTHING;
  INSERT INTO platform.required_aggregates(aggregate_type) VALUES('blog.'||item) ON CONFLICT DO NOTHING;
 END LOOP;
END $$;

INSERT INTO public.schema_migrations(version) VALUES('113_blog_topics_subscriptions_rewards') ON CONFLICT DO NOTHING;
COMMIT;
