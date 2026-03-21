-- 036_full_create_all_screens_schema.sql
-- Full create script for all screen-backed modules with strict constraints,
-- ACID-oriented keys/relations, activity logging, and generic auditing.

BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE SCHEMA IF NOT EXISTS user_management;
CREATE SCHEMA IF NOT EXISTS matching;
CREATE SCHEMA IF NOT EXISTS audit;

-- ============================================================================
-- USER MANAGEMENT (MASTER + TRANSACTION)
-- ============================================================================

CREATE TABLE IF NOT EXISTS user_management.users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  phone_number TEXT NOT NULL UNIQUE,
  email TEXT UNIQUE,
  name TEXT NOT NULL,
  date_of_birth DATE NOT NULL,
  gender TEXT NOT NULL CHECK (gender IN ('male', 'female', 'other')),
  bio TEXT,
  height_cm INTEGER CHECK (height_cm BETWEEN 80 AND 260),
  education TEXT,
  profession TEXT,
  income_range TEXT,
  drinking TEXT,
  smoking TEXT,
  religion TEXT,
  mother_tongue TEXT,
  relationship_status TEXT,
  personality_type TEXT,
  country TEXT,
  state TEXT,
  city TEXT,
  profile_completion INTEGER NOT NULL DEFAULT 0 CHECK (profile_completion BETWEEN 0 AND 100),
  is_verified BOOLEAN NOT NULL DEFAULT FALSE,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  last_login_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_users_gender_dob ON user_management.users(gender, date_of_birth);
CREATE INDEX IF NOT EXISTS idx_users_country_state_city ON user_management.users(country, state, city);
CREATE INDEX IF NOT EXISTS idx_users_created_at ON user_management.users(created_at DESC);

CREATE TABLE IF NOT EXISTS user_management.preferences (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL UNIQUE REFERENCES user_management.users(id) ON DELETE CASCADE,
  seeking_genders TEXT[] NOT NULL DEFAULT ARRAY['male','female'],
  min_age_years INTEGER NOT NULL DEFAULT 18 CHECK (min_age_years BETWEEN 18 AND 100),
  max_age_years INTEGER NOT NULL DEFAULT 60 CHECK (max_age_years BETWEEN 18 AND 100),
  max_distance_km INTEGER NOT NULL DEFAULT 50 CHECK (max_distance_km BETWEEN 1 AND 5000),
  education_filter TEXT[] NOT NULL DEFAULT ARRAY[]::TEXT[],
  serious_only BOOLEAN NOT NULL DEFAULT TRUE,
  verified_only BOOLEAN NOT NULL DEFAULT FALSE,
  intent_tags TEXT[] NOT NULL DEFAULT ARRAY[]::TEXT[],
  language_tags TEXT[] NOT NULL DEFAULT ARRAY[]::TEXT[],
  deal_breaker_tags TEXT[] NOT NULL DEFAULT ARRAY[]::TEXT[],
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (min_age_years <= max_age_years)
);

CREATE INDEX IF NOT EXISTS idx_preferences_user_id ON user_management.preferences(user_id);
CREATE INDEX IF NOT EXISTS idx_preferences_intent_tags ON user_management.preferences USING GIN(intent_tags);
CREATE INDEX IF NOT EXISTS idx_preferences_language_tags ON user_management.preferences USING GIN(language_tags);

CREATE TABLE IF NOT EXISTS user_management.photos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  photo_url TEXT NOT NULL,
  ordering INTEGER NOT NULL CHECK (ordering >= 0),
  uploaded_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  is_moderated BOOLEAN NOT NULL DEFAULT FALSE,
  is_flagged BOOLEAN NOT NULL DEFAULT FALSE,
  UNIQUE(user_id, ordering)
);

CREATE INDEX IF NOT EXISTS idx_photos_user_order ON user_management.photos(user_id, ordering);

CREATE TABLE IF NOT EXISTS user_management.profile_drafts (
  user_id UUID PRIMARY KEY REFERENCES user_management.users(id) ON DELETE CASCADE,
  draft_payload JSONB NOT NULL DEFAULT '{}'::JSONB,
  lock_version INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS user_management.user_settings (
  user_id UUID PRIMARY KEY REFERENCES user_management.users(id) ON DELETE CASCADE,
  show_age BOOLEAN NOT NULL DEFAULT TRUE,
  show_exact_distance BOOLEAN NOT NULL DEFAULT FALSE,
  show_online_status BOOLEAN NOT NULL DEFAULT TRUE,
  notify_new_match BOOLEAN NOT NULL DEFAULT TRUE,
  notify_new_message BOOLEAN NOT NULL DEFAULT TRUE,
  notify_likes BOOLEAN NOT NULL DEFAULT TRUE,
  theme TEXT NOT NULL DEFAULT 'auto',
  lock_version INTEGER NOT NULL DEFAULT 0,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS user_management.emergency_contacts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  phone_number TEXT NOT NULL,
  ordering INTEGER NOT NULL CHECK (ordering BETWEEN 1 AND 3),
  added_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, ordering)
);

CREATE INDEX IF NOT EXISTS idx_emergency_contacts_user ON user_management.emergency_contacts(user_id);

CREATE TABLE IF NOT EXISTS user_management.blocked_users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  blocked_user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  reason TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, blocked_user_id),
  CHECK (user_id <> blocked_user_id)
);

CREATE INDEX IF NOT EXISTS idx_blocked_users_user ON user_management.blocked_users(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_blocked_users_target ON user_management.blocked_users(blocked_user_id);

CREATE TABLE IF NOT EXISTS user_management.user_login_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  request_id TEXT,
  correlation_id TEXT,
  device_id TEXT,
  device_platform TEXT,
  device_model TEXT,
  app_version TEXT,
  ip_address INET,
  user_agent TEXT,
  geo_country TEXT,
  geo_state TEXT,
  geo_city TEXT,
  geo_latitude NUMERIC(10,7),
  geo_longitude NUMERIC(10,7),
  login_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  logout_at TIMESTAMPTZ,
  is_active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE INDEX IF NOT EXISTS idx_login_sessions_user_time ON user_management.user_login_sessions(user_id, login_at DESC);
CREATE INDEX IF NOT EXISTS idx_login_sessions_ip ON user_management.user_login_sessions(ip_address, login_at DESC);

-- ============================================================================
-- MATCHING + ENGAGEMENT + SAFETY + BILLING RUNTIME
-- ============================================================================

CREATE TABLE IF NOT EXISTS matching.swipes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  target_user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  is_like BOOLEAN NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, target_user_id),
  CHECK (user_id <> target_user_id)
);

CREATE INDEX IF NOT EXISTS idx_swipes_user_time ON matching.swipes(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_swipes_target ON matching.swipes(target_user_id, created_at DESC);

CREATE TABLE IF NOT EXISTS matching.matches (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id_1 UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  user_id_2 UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  user_1_status TEXT NOT NULL DEFAULT 'active' CHECK (user_1_status IN ('active','unmatched','reported','blocked')),
  user_2_status TEXT NOT NULL DEFAULT 'active' CHECK (user_2_status IN ('active','unmatched','reported','blocked')),
  user_1_blocked BOOLEAN NOT NULL DEFAULT FALSE,
  user_2_blocked BOOLEAN NOT NULL DEFAULT FALSE,
  chat_count INTEGER NOT NULL DEFAULT 0,
  last_message_at TIMESTAMPTZ,
  lock_version INTEGER NOT NULL DEFAULT 0,
  UNIQUE(user_id_1, user_id_2),
  CHECK (user_id_1 <> user_id_2),
  CHECK (user_id_1 < user_id_2)
);

CREATE INDEX IF NOT EXISTS idx_matches_user_1 ON matching.matches(user_id_1, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_matches_user_2 ON matching.matches(user_id_2, created_at DESC);

CREATE TABLE IF NOT EXISTS matching.messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  match_id UUID NOT NULL REFERENCES matching.matches(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  text TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  delivered_at TIMESTAMPTZ,
  read_at TIMESTAMPTZ,
  is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
  deleted_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_messages_match_time ON matching.messages(match_id, created_at DESC);

CREATE TABLE IF NOT EXISTS matching.friend_connections (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  friend_user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'accepted' CHECK (status IN ('pending','accepted','blocked','removed')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, friend_user_id),
  CHECK (user_id <> friend_user_id)
);

CREATE INDEX IF NOT EXISTS idx_friend_connections_user ON matching.friend_connections(user_id, status, updated_at DESC);

CREATE TABLE IF NOT EXISTS matching.friend_activity_feed (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  friend_user_id UUID REFERENCES user_management.users(id) ON DELETE SET NULL,
  activity_type TEXT NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  metadata JSONB NOT NULL DEFAULT '{}'::JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_friend_activity_user ON matching.friend_activity_feed(user_id, created_at DESC);

CREATE TABLE IF NOT EXISTS matching.verification_states (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL UNIQUE REFERENCES user_management.users(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','verified','rejected','expired')),
  submitted_at TIMESTAMPTZ,
  reviewed_at TIMESTAMPTZ,
  reviewed_by UUID REFERENCES user_management.users(id) ON DELETE SET NULL,
  rejection_reason TEXT,
  details JSONB NOT NULL DEFAULT '{}'::JSONB,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_verification_states_status ON matching.verification_states(status, updated_at DESC);

CREATE TABLE IF NOT EXISTS matching.moderation_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  reported_user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  match_id UUID REFERENCES matching.matches(id) ON DELETE SET NULL,
  reason TEXT NOT NULL,
  description TEXT,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','reviewed','actioned','dismissed')),
  action TEXT,
  reviewed_by UUID REFERENCES user_management.users(id) ON DELETE SET NULL,
  reviewed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_moderation_reports_status ON matching.moderation_reports(status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_moderation_reports_reported ON matching.moderation_reports(reported_user_id, created_at DESC);

CREATE TABLE IF NOT EXISTS matching.moderation_appeals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  report_id UUID NOT NULL REFERENCES matching.moderation_reports(id) ON DELETE CASCADE,
  requester_user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  reason TEXT NOT NULL,
  description TEXT,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','approved','rejected')),
  reviewed_by UUID REFERENCES user_management.users(id) ON DELETE SET NULL,
  reviewed_at TIMESTAMPTZ,
  resolution_reason TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_moderation_appeals_status ON matching.moderation_appeals(status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_moderation_appeals_user ON matching.moderation_appeals(requester_user_id, created_at DESC);

CREATE TABLE IF NOT EXISTS matching.sos_alerts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  match_id UUID REFERENCES matching.matches(id) ON DELETE SET NULL,
  level TEXT NOT NULL CHECK (level IN ('low','medium','high','critical')),
  message TEXT,
  latitude NUMERIC(10,7),
  longitude NUMERIC(10,7),
  status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open','acknowledged','resolved')),
  resolved_by UUID REFERENCES user_management.users(id) ON DELETE SET NULL,
  resolved_note TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  resolved_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_sos_alerts_user ON matching.sos_alerts(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_sos_alerts_status ON matching.sos_alerts(status, created_at DESC);

CREATE TABLE IF NOT EXISTS matching.match_unlock_states (
  match_id UUID PRIMARY KEY REFERENCES matching.matches(id) ON DELETE CASCADE,
  unlock_state TEXT NOT NULL DEFAULT 'matched' CHECK (unlock_state IN ('matched','quest_pending','quest_under_review','conversation_unlocked','restricted')),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS matching.match_quest_templates (
  match_id UUID PRIMARY KEY REFERENCES matching.matches(id) ON DELETE CASCADE,
  template_id TEXT NOT NULL,
  creator_user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  prompt_template TEXT NOT NULL,
  min_chars INTEGER NOT NULL CHECK (min_chars BETWEEN 20 AND 1000),
  max_chars INTEGER NOT NULL CHECK (max_chars BETWEEN 20 AND 5000),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (min_chars < max_chars)
);

CREATE TABLE IF NOT EXISTS matching.match_quest_workflows (
  match_id UUID PRIMARY KEY REFERENCES matching.matches(id) ON DELETE CASCADE,
  template_id TEXT,
  unlock_state TEXT NOT NULL DEFAULT 'matched',
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','approved','rejected','cooldown')),
  submitter_user_id UUID REFERENCES user_management.users(id) ON DELETE SET NULL,
  reviewer_user_id UUID REFERENCES user_management.users(id) ON DELETE SET NULL,
  response_text TEXT,
  review_reason TEXT,
  submitted_at TIMESTAMPTZ,
  reviewed_at TIMESTAMPTZ,
  cooldown_until TIMESTAMPTZ,
  attempt_count INTEGER NOT NULL DEFAULT 0,
  window_started_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS matching.match_gestures (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  match_id UUID NOT NULL REFERENCES matching.matches(id) ON DELETE CASCADE,
  sender_user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  receiver_user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  gesture_type TEXT NOT NULL,
  content_text TEXT,
  tone TEXT,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','approved','rejected')),
  decision_reason TEXT,
  decided_by UUID REFERENCES user_management.users(id) ON DELETE SET NULL,
  decided_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_match_gestures_match ON matching.match_gestures(match_id, created_at DESC);

CREATE TABLE IF NOT EXISTS matching.gift_catalog (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  gif_url TEXT,
  icon_key TEXT,
  tier TEXT NOT NULL,
  price_coins INTEGER NOT NULL CHECK (price_coins >= 0),
  is_limited BOOLEAN NOT NULL DEFAULT FALSE,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  sort_order INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS matching.user_wallets (
  user_id UUID PRIMARY KEY REFERENCES user_management.users(id) ON DELETE CASCADE,
  coin_balance INTEGER NOT NULL DEFAULT 0 CHECK (coin_balance >= 0),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS matching.match_gift_sends (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  match_id UUID NOT NULL REFERENCES matching.matches(id) ON DELETE CASCADE,
  sender_user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  receiver_user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  gift_id TEXT NOT NULL REFERENCES matching.gift_catalog(id),
  quantity INTEGER NOT NULL DEFAULT 1 CHECK (quantity > 0),
  total_cost_coins INTEGER NOT NULL CHECK (total_cost_coins >= 0),
  idempotency_key TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'sent' CHECK (status IN ('sent','failed','refunded')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(match_id, sender_user_id, idempotency_key)
);

CREATE INDEX IF NOT EXISTS idx_match_gift_sends_sender ON matching.match_gift_sends(sender_user_id, created_at DESC);

CREATE TABLE IF NOT EXISTS matching.gift_spend_activities (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  match_id UUID NOT NULL REFERENCES matching.matches(id) ON DELETE CASCADE,
  sender_user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  receiver_user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  gift_id TEXT NOT NULL REFERENCES matching.gift_catalog(id),
  action TEXT NOT NULL,
  status TEXT NOT NULL,
  amount_coins INTEGER NOT NULL CHECK (amount_coins >= 0),
  metadata JSONB NOT NULL DEFAULT '{}'::JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_gift_spend_sender ON matching.gift_spend_activities(sender_user_id, created_at DESC);

CREATE TABLE IF NOT EXISTS matching.user_trust_filter_preferences (
  user_id UUID PRIMARY KEY REFERENCES user_management.users(id) ON DELETE CASCADE,
  trust_only_mode BOOLEAN NOT NULL DEFAULT FALSE,
  required_badge_codes TEXT[] NOT NULL DEFAULT ARRAY[]::TEXT[],
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_trust_filter_badges ON matching.user_trust_filter_preferences USING GIN(required_badge_codes);

CREATE TABLE IF NOT EXISTS matching.user_trust_badges (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  badge_code TEXT NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('active','inactive','revoked')),
  score INTEGER,
  awarded_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, badge_code)
);

CREATE TABLE IF NOT EXISTS matching.user_trust_badge_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  badge_code TEXT NOT NULL,
  action TEXT NOT NULL,
  reason TEXT,
  happened_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  metadata JSONB NOT NULL DEFAULT '{}'::JSONB
);

CREATE INDEX IF NOT EXISTS idx_badge_history_user_time ON matching.user_trust_badge_history(user_id, happened_at DESC);

CREATE TABLE IF NOT EXISTS matching.trust_milestones (
  user_id UUID PRIMARY KEY REFERENCES user_management.users(id) ON DELETE CASCADE,
  milestone_code TEXT NOT NULL,
  milestone_value INTEGER,
  signal_breakdown JSONB NOT NULL DEFAULT '{}'::JSONB,
  computed_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS matching.conversation_rooms (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  room_type TEXT NOT NULL,
  topic TEXT,
  city TEXT,
  starts_at TIMESTAMPTZ,
  ends_at TIMESTAMPTZ,
  lifecycle_state TEXT NOT NULL DEFAULT 'scheduled' CHECK (lifecycle_state IN ('scheduled','active','closed','cancelled')),
  created_by_user_id UUID REFERENCES user_management.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS matching.conversation_room_participants (
  room_id UUID NOT NULL REFERENCES matching.conversation_rooms(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'joined' CHECK (status IN ('joined','left','removed','blocked')),
  joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  left_at TIMESTAMPTZ,
  PRIMARY KEY (room_id, user_id)
);

CREATE TABLE IF NOT EXISTS matching.conversation_room_moderation_actions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id UUID NOT NULL REFERENCES matching.conversation_rooms(id) ON DELETE CASCADE,
  actor_user_id UUID REFERENCES user_management.users(id) ON DELETE SET NULL,
  target_user_id UUID REFERENCES user_management.users(id) ON DELETE SET NULL,
  action TEXT NOT NULL,
  reason TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  metadata JSONB NOT NULL DEFAULT '{}'::JSONB
);

CREATE TABLE IF NOT EXISTS matching.conversation_room_blocks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id UUID NOT NULL REFERENCES matching.conversation_rooms(id) ON DELETE CASCADE,
  blocked_user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  blocked_by_user_id UUID REFERENCES user_management.users(id) ON DELETE SET NULL,
  reason TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMPTZ,
  UNIQUE(room_id, blocked_user_id)
);

CREATE TABLE IF NOT EXISTS matching.activity_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  match_id UUID NOT NULL REFERENCES matching.matches(id) ON DELETE CASCADE,
  activity_type TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active','completed','timed_out','partial_timeout','cancelled')),
  initiator_user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  participant_user_ids UUID[] NOT NULL,
  metadata JSONB NOT NULL DEFAULT '{}'::JSONB,
  started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS matching.activity_session_responses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID NOT NULL REFERENCES matching.activity_sessions(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  question_id TEXT,
  response_text TEXT,
  submitted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(session_id, user_id, question_id)
);

CREATE TABLE IF NOT EXISTS matching.daily_prompts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  prompt_date DATE NOT NULL UNIQUE,
  prompt_text TEXT NOT NULL,
  domain TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS matching.prompt_answers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  prompt_id UUID NOT NULL REFERENCES matching.daily_prompts(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  answer_date DATE NOT NULL,
  answer_text TEXT NOT NULL,
  normalized_answer TEXT,
  is_edited BOOLEAN NOT NULL DEFAULT FALSE,
  edit_window_until TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(prompt_id, user_id)
);

CREATE TABLE IF NOT EXISTS matching.user_streaks (
  user_id UUID PRIMARY KEY REFERENCES user_management.users(id) ON DELETE CASCADE,
  streak_type TEXT NOT NULL DEFAULT 'daily_prompt',
  current_streak INTEGER NOT NULL DEFAULT 0,
  best_streak INTEGER NOT NULL DEFAULT 0,
  last_activity_date DATE,
  milestone_reached INTEGER,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS matching.match_nudges (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  match_id UUID NOT NULL REFERENCES matching.matches(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  counterparty_user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  nudge_type TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'sent' CHECK (status IN ('sent','clicked','dismissed','expired')),
  clicked_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  metadata JSONB NOT NULL DEFAULT '{}'::JSONB
);

CREATE INDEX IF NOT EXISTS idx_match_nudges_match ON matching.match_nudges(match_id, created_at DESC);

CREATE TABLE IF NOT EXISTS matching.conversation_resumes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  match_id UUID NOT NULL REFERENCES matching.matches(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  trigger_nudge_id UUID REFERENCES matching.match_nudges(id) ON DELETE SET NULL,
  resumed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  metadata JSONB NOT NULL DEFAULT '{}'::JSONB
);

CREATE TABLE IF NOT EXISTS matching.circle_memberships (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  circle_id TEXT NOT NULL,
  user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  role TEXT NOT NULL DEFAULT 'member' CHECK (role IN ('member','owner','moderator')),
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active','left','removed')),
  joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(circle_id, user_id)
);

CREATE TABLE IF NOT EXISTS matching.circle_challenge_entries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  circle_id TEXT NOT NULL,
  user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  challenge_date DATE NOT NULL,
  submission_text TEXT,
  media_url TEXT,
  status TEXT NOT NULL DEFAULT 'submitted' CHECK (status IN ('submitted','approved','rejected')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(circle_id, user_id, challenge_date)
);

CREATE TABLE IF NOT EXISTS matching.voice_icebreakers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  match_id UUID NOT NULL REFERENCES matching.matches(id) ON DELETE CASCADE,
  sender_user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  receiver_user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  prompt_id TEXT,
  transcript TEXT,
  duration_seconds INTEGER CHECK (duration_seconds >= 0),
  status TEXT NOT NULL DEFAULT 'started' CHECK (status IN ('started','sent','played','expired')),
  sent_at TIMESTAMPTZ,
  played_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS matching.group_coffee_polls (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open','finalized','expired','cancelled')),
  deadline_at TIMESTAMPTZ,
  selected_option_id UUID,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS matching.group_coffee_poll_options (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  poll_id UUID NOT NULL REFERENCES matching.group_coffee_polls(id) ON DELETE CASCADE,
  option_text TEXT NOT NULL,
  sort_order INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(poll_id, sort_order)
);

ALTER TABLE matching.group_coffee_polls
  ADD CONSTRAINT fk_group_coffee_selected_option
  FOREIGN KEY (selected_option_id) REFERENCES matching.group_coffee_poll_options(id) ON DELETE SET NULL;

CREATE TABLE IF NOT EXISTS matching.group_coffee_poll_votes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  poll_id UUID NOT NULL REFERENCES matching.group_coffee_polls(id) ON DELETE CASCADE,
  option_id UUID NOT NULL REFERENCES matching.group_coffee_poll_options(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(poll_id, user_id)
);

CREATE TABLE IF NOT EXISTS matching.community_groups (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  city TEXT NOT NULL,
  topic TEXT NOT NULL,
  description TEXT,
  created_by_user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_community_groups_city_topic ON matching.community_groups(city, topic, created_at DESC);

CREATE TABLE IF NOT EXISTS matching.community_group_members (
  group_id UUID NOT NULL REFERENCES matching.community_groups(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active','left','removed')),
  role TEXT NOT NULL DEFAULT 'member' CHECK (role IN ('member','owner','moderator')),
  joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (group_id, user_id)
);

CREATE TABLE IF NOT EXISTS matching.community_group_invites (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID NOT NULL REFERENCES matching.community_groups(id) ON DELETE CASCADE,
  inviter_user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  invitee_user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','accepted','declined','expired')),
  invited_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  responded_at TIMESTAMPTZ,
  UNIQUE(group_id, invitee_user_id)
);

CREATE TABLE IF NOT EXISTS matching.spotlight_daily_user_counters (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  counter_date DATE NOT NULL,
  user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  exposure_count INTEGER NOT NULL DEFAULT 0,
  like_count INTEGER NOT NULL DEFAULT 0,
  match_count INTEGER NOT NULL DEFAULT 0,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(counter_date, user_id)
);

CREATE TABLE IF NOT EXISTS matching.spotlight_daily_tier_counters (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  counter_date DATE NOT NULL,
  tier TEXT NOT NULL,
  exposure_count INTEGER NOT NULL DEFAULT 0,
  like_count INTEGER NOT NULL DEFAULT 0,
  match_count INTEGER NOT NULL DEFAULT 0,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(counter_date, tier)
);

CREATE TABLE IF NOT EXISTS matching.spotlight_eligibility (
  user_id UUID PRIMARY KEY REFERENCES user_management.users(id) ON DELETE CASCADE,
  tier TEXT NOT NULL,
  eligible BOOLEAN NOT NULL DEFAULT TRUE,
  reason TEXT,
  effective_from TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  effective_to TIMESTAMPTZ,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS matching.video_call_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  match_id UUID NOT NULL REFERENCES matching.matches(id) ON DELETE CASCADE,
  initiator_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  recipient_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'started' CHECK (status IN ('started','ended','missed','rejected','failed')),
  started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  ended_at TIMESTAMPTZ,
  ended_by UUID REFERENCES user_management.users(id) ON DELETE SET NULL,
  metadata JSONB NOT NULL DEFAULT '{}'::JSONB
);

CREATE INDEX IF NOT EXISTS idx_video_calls_match_time ON matching.video_call_sessions(match_id, started_at DESC);

CREATE TABLE IF NOT EXISTS matching.billing_subscriptions_runtime (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  plan_code TEXT NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('active','cancelled','expired','paused')),
  billing_cycle TEXT NOT NULL CHECK (billing_cycle IN ('monthly','yearly')),
  start_date TIMESTAMPTZ NOT NULL,
  end_date TIMESTAMPTZ,
  next_billing_date TIMESTAMPTZ,
  auto_renew BOOLEAN NOT NULL DEFAULT TRUE,
  provider_subscription_id TEXT,
  lock_version INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_billing_subscriptions_user ON matching.billing_subscriptions_runtime(user_id, created_at DESC);

CREATE TABLE IF NOT EXISTS matching.billing_payments_runtime (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  subscription_id UUID REFERENCES matching.billing_subscriptions_runtime(id) ON DELETE SET NULL,
  amount_paise BIGINT NOT NULL CHECK (amount_paise >= 0),
  currency TEXT NOT NULL DEFAULT 'INR',
  status TEXT NOT NULL CHECK (status IN ('created','success','failed','refunded')),
  provider_payment_id TEXT,
  provider_order_id TEXT,
  paid_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  metadata JSONB NOT NULL DEFAULT '{}'::JSONB
);

CREATE INDEX IF NOT EXISTS idx_billing_payments_user ON matching.billing_payments_runtime(user_id, created_at DESC);

CREATE TABLE IF NOT EXISTS matching.message_delete_audit (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  message_id UUID,
  deleted BOOLEAN NOT NULL,
  attempts_24h INTEGER NOT NULL DEFAULT 0,
  success_24h INTEGER NOT NULL DEFAULT 0,
  blocked_24h INTEGER NOT NULL DEFAULT 0,
  abuse_flagged BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_message_delete_audit_user ON matching.message_delete_audit(user_id, created_at DESC);

CREATE TABLE IF NOT EXISTS matching.activity_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_name TEXT NOT NULL,
  event_domain TEXT NOT NULL,
  event_version INTEGER NOT NULL DEFAULT 1,
  user_id UUID REFERENCES user_management.users(id) ON DELETE SET NULL,
  actor_user_id UUID REFERENCES user_management.users(id) ON DELETE SET NULL,
  match_id UUID REFERENCES matching.matches(id) ON DELETE SET NULL,
  entity_schema TEXT,
  entity_table TEXT,
  entity_id TEXT,
  idempotency_key TEXT,
  correlation_id TEXT,
  request_id TEXT,
  source_service TEXT,
  source_platform TEXT,
  source_device_id TEXT,
  ip_address INET,
  geo_country TEXT,
  geo_state TEXT,
  geo_city TEXT,
  geo_latitude NUMERIC(10,7),
  geo_longitude NUMERIC(10,7),
  payload JSONB NOT NULL DEFAULT '{}'::JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_activity_events_user_time ON matching.activity_events(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_activity_events_name_time ON matching.activity_events(event_name, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_activity_events_domain_time ON matching.activity_events(event_domain, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_activity_events_corr ON matching.activity_events(correlation_id);

CREATE TABLE IF NOT EXISTS matching.reporting_refresh_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  report_name TEXT NOT NULL,
  refresh_type TEXT NOT NULL CHECK (refresh_type IN ('materialized_view','etl','adhoc')),
  status TEXT NOT NULL CHECK (status IN ('started','success','failed')),
  started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  completed_at TIMESTAMPTZ,
  duration_ms BIGINT,
  records_processed BIGINT,
  initiated_by TEXT,
  error_text TEXT,
  metadata JSONB NOT NULL DEFAULT '{}'::JSONB
);

CREATE INDEX IF NOT EXISTS idx_reporting_refresh_report_time ON matching.reporting_refresh_log(report_name, started_at DESC);

-- ============================================================================
-- AUDIT + ACTIVITY INFRA (ALL TABLES)
-- ============================================================================

CREATE TABLE IF NOT EXISTS audit.change_log (
  id BIGSERIAL PRIMARY KEY,
  changed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  txid BIGINT NOT NULL DEFAULT txid_current(),
  operation TEXT NOT NULL CHECK (operation IN ('INSERT','UPDATE','DELETE')),
  table_schema TEXT NOT NULL,
  table_name TEXT NOT NULL,
  row_identity JSONB,
  old_data JSONB,
  new_data JSONB,
  modified_by TEXT,
  correlation_id TEXT,
  request_id TEXT,
  source_device_id TEXT,
  ip_address INET,
  geo_country TEXT,
  geo_state TEXT,
  geo_city TEXT,
  geo_latitude NUMERIC(10,7),
  geo_longitude NUMERIC(10,7)
);

CREATE INDEX IF NOT EXISTS idx_change_log_table_time ON audit.change_log(table_schema, table_name, changed_at DESC);
CREATE INDEX IF NOT EXISTS idx_change_log_txid ON audit.change_log(txid);

CREATE TABLE IF NOT EXISTS audit.activity_log (
  id BIGSERIAL PRIMARY KEY,
  occurred_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  txid BIGINT NOT NULL DEFAULT txid_current(),
  event_type TEXT NOT NULL,
  event_schema TEXT,
  event_table TEXT,
  event_row_identity JSONB,
  actor_user_id TEXT,
  actor_role TEXT,
  device_id TEXT,
  platform TEXT,
  ip_address INET,
  user_agent TEXT,
  geo_country TEXT,
  geo_state TEXT,
  geo_city TEXT,
  geo_latitude NUMERIC(10,7),
  geo_longitude NUMERIC(10,7),
  correlation_id TEXT,
  request_id TEXT,
  payload JSONB NOT NULL DEFAULT '{}'::JSONB
);

CREATE INDEX IF NOT EXISTS idx_activity_log_time ON audit.activity_log(occurred_at DESC);
CREATE INDEX IF NOT EXISTS idx_activity_log_actor ON audit.activity_log(actor_user_id, occurred_at DESC);
CREATE INDEX IF NOT EXISTS idx_activity_log_ip ON audit.activity_log(ip_address, occurred_at DESC);

CREATE OR REPLACE FUNCTION audit.capture_row_change()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  actor_user TEXT := NULLIF(current_setting('app.current_user_id', true), '');
  actor_role TEXT := NULLIF(current_setting('app.current_role', true), '');
  corr_id TEXT := NULLIF(current_setting('app.correlation_id', true), '');
  req_id TEXT := NULLIF(current_setting('app.request_id', true), '');
  device_id TEXT := NULLIF(current_setting('app.device_id', true), '');
  platform TEXT := NULLIF(current_setting('app.platform', true), '');
  user_agent TEXT := NULLIF(current_setting('app.user_agent', true), '');
  ip_text TEXT := NULLIF(current_setting('app.ip_address', true), '');
  g_country TEXT := NULLIF(current_setting('app.geo_country', true), '');
  g_state TEXT := NULLIF(current_setting('app.geo_state', true), '');
  g_city TEXT := NULLIF(current_setting('app.geo_city', true), '');
  g_lat TEXT := NULLIF(current_setting('app.geo_latitude', true), '');
  g_lon TEXT := NULLIF(current_setting('app.geo_longitude', true), '');
  row_ident JSONB;
  old_row JSONB;
  new_row JSONB;
BEGIN
  IF TG_OP = 'INSERT' THEN
    new_row := to_jsonb(NEW);
    old_row := NULL;
    row_ident := jsonb_build_object('id', COALESCE(new_row->'id', 'null'::JSONB));
  ELSIF TG_OP = 'UPDATE' THEN
    new_row := to_jsonb(NEW);
    old_row := to_jsonb(OLD);
    row_ident := jsonb_build_object('id', COALESCE(new_row->'id', old_row->'id', 'null'::JSONB));
  ELSE
    new_row := NULL;
    old_row := to_jsonb(OLD);
    row_ident := jsonb_build_object('id', COALESCE(old_row->'id', 'null'::JSONB));
  END IF;

  INSERT INTO audit.change_log (
    operation, table_schema, table_name, row_identity, old_data, new_data,
    modified_by, correlation_id, request_id, source_device_id, ip_address,
    geo_country, geo_state, geo_city, geo_latitude, geo_longitude
  ) VALUES (
    TG_OP, TG_TABLE_SCHEMA, TG_TABLE_NAME, row_ident, old_row, new_row,
    COALESCE(actor_user, SESSION_USER), corr_id, req_id, device_id,
    CASE WHEN ip_text IS NULL THEN NULL ELSE ip_text::INET END,
    g_country, g_state, g_city,
    CASE WHEN g_lat IS NULL THEN NULL ELSE g_lat::NUMERIC(10,7) END,
    CASE WHEN g_lon IS NULL THEN NULL ELSE g_lon::NUMERIC(10,7) END
  );

  INSERT INTO audit.activity_log (
    event_type, event_schema, event_table, event_row_identity, actor_user_id,
    actor_role, device_id, platform, ip_address, user_agent,
    geo_country, geo_state, geo_city, geo_latitude, geo_longitude,
    correlation_id, request_id, payload
  ) VALUES (
    'DML_' || TG_OP,
    TG_TABLE_SCHEMA,
    TG_TABLE_NAME,
    row_ident,
    COALESCE(actor_user, SESSION_USER),
    actor_role,
    device_id,
    platform,
    CASE WHEN ip_text IS NULL THEN NULL ELSE ip_text::INET END,
    user_agent,
    g_country,
    g_state,
    g_city,
    CASE WHEN g_lat IS NULL THEN NULL ELSE g_lat::NUMERIC(10,7) END,
    CASE WHEN g_lon IS NULL THEN NULL ELSE g_lon::NUMERIC(10,7) END,
    corr_id,
    req_id,
    jsonb_build_object(
      'operation', TG_OP,
      'table_schema', TG_TABLE_SCHEMA,
      'table_name', TG_TABLE_NAME
    )
  );

  IF TG_OP = 'DELETE' THEN
    RETURN OLD;
  END IF;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION audit.attach_audit_triggers(p_schema TEXT)
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
  rec RECORD;
BEGIN
  FOR rec IN
    SELECT table_schema, table_name
    FROM information_schema.tables
    WHERE table_type = 'BASE TABLE'
      AND table_schema = p_schema
  LOOP
    EXECUTE format('DROP TRIGGER IF EXISTS trg_audit_row_change ON %I.%I', rec.table_schema, rec.table_name);
    EXECUTE format(
      'CREATE TRIGGER trg_audit_row_change AFTER INSERT OR UPDATE OR DELETE ON %I.%I FOR EACH ROW EXECUTE FUNCTION audit.capture_row_change()',
      rec.table_schema, rec.table_name
    );
  END LOOP;
END;
$$;

-- Attach to all master/transaction tables in app schemas.
SELECT audit.attach_audit_triggers('user_management');
SELECT audit.attach_audit_triggers('matching');

COMMIT;
