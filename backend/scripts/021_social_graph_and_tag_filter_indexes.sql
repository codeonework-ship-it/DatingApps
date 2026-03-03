-- Social graph + advanced profile tag filtering support
-- Run after 020_engagement_surfaces_tables.sql

CREATE TABLE IF NOT EXISTS matching.user_profile_tag_filters (
  user_id UUID PRIMARY KEY,
  intent_tags TEXT[] NOT NULL DEFAULT '{}',
  language_tags TEXT[] NOT NULL DEFAULT '{}',
  pet_preference TEXT,
  workout_frequency TEXT,
  diet_type TEXT,
  sleep_schedule TEXT,
  travel_style TEXT,
  political_comfort_range TEXT,
  deal_breaker_tags TEXT[] NOT NULL DEFAULT '{}',
  country TEXT,
  state TEXT,
  city TEXT,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_profile_tag_filters_intent_gin
  ON matching.user_profile_tag_filters USING GIN (intent_tags);

CREATE INDEX IF NOT EXISTS idx_profile_tag_filters_language_gin
  ON matching.user_profile_tag_filters USING GIN (language_tags);

CREATE INDEX IF NOT EXISTS idx_profile_tag_filters_deal_breaker_gin
  ON matching.user_profile_tag_filters USING GIN (deal_breaker_tags);

CREATE INDEX IF NOT EXISTS idx_profile_tag_filters_location
  ON matching.user_profile_tag_filters(country, state, city);

CREATE TABLE IF NOT EXISTS matching.user_trust_filter_preferences (
  user_id UUID PRIMARY KEY,
  enabled BOOLEAN NOT NULL DEFAULT FALSE,
  minimum_active_badges INTEGER NOT NULL DEFAULT 0,
  required_badge_codes TEXT[] NOT NULL DEFAULT '{}',
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (minimum_active_badges >= 0)
);

CREATE INDEX IF NOT EXISTS idx_user_trust_filter_required_badges_gin
  ON matching.user_trust_filter_preferences USING GIN (required_badge_codes);

CREATE TABLE IF NOT EXISTS matching.friend_connections (
  user_id UUID NOT NULL,
  friend_user_id UUID NOT NULL,
  status TEXT NOT NULL DEFAULT 'accepted' CHECK (status IN ('pending', 'accepted', 'blocked')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (user_id, friend_user_id),
  CHECK (user_id <> friend_user_id)
);

CREATE INDEX IF NOT EXISTS idx_friend_connections_friend
  ON matching.friend_connections(friend_user_id, status, updated_at DESC);

CREATE TABLE IF NOT EXISTS matching.friend_activity_feed (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL,
  friend_user_id UUID,
  activity_type TEXT NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_friend_activity_feed_user_created
  ON matching.friend_activity_feed(user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_friend_activity_feed_type
  ON matching.friend_activity_feed(activity_type, created_at DESC);
