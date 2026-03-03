-- Lifestyle master tables and seed data for dropdown-backed preferences
-- Run after 023_india_master_data_and_hookup_filter.sql

ALTER TABLE matching.user_profile_tag_filters
  ADD COLUMN IF NOT EXISTS diet_preference TEXT;

CREATE INDEX IF NOT EXISTS idx_profile_tag_filters_diet_preference
  ON matching.user_profile_tag_filters(diet_preference);

CREATE TABLE IF NOT EXISTS matching.master_languages (
  id BIGSERIAL PRIMARY KEY,
  code TEXT UNIQUE,
  name TEXT UNIQUE NOT NULL,
  sort_order INTEGER NOT NULL DEFAULT 0,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS matching.master_workout_frequencies (
  id BIGSERIAL PRIMARY KEY,
  name TEXT UNIQUE NOT NULL,
  sort_order INTEGER NOT NULL DEFAULT 0,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS matching.master_diet_preferences (
  id BIGSERIAL PRIMARY KEY,
  name TEXT UNIQUE NOT NULL,
  sort_order INTEGER NOT NULL DEFAULT 0,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS matching.master_diet_types (
  id BIGSERIAL PRIMARY KEY,
  name TEXT UNIQUE NOT NULL,
  sort_order INTEGER NOT NULL DEFAULT 0,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS matching.master_sleep_schedules (
  id BIGSERIAL PRIMARY KEY,
  name TEXT UNIQUE NOT NULL,
  sort_order INTEGER NOT NULL DEFAULT 0,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS matching.master_travel_styles (
  id BIGSERIAL PRIMARY KEY,
  name TEXT UNIQUE NOT NULL,
  sort_order INTEGER NOT NULL DEFAULT 0,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS matching.master_political_comfort_ranges (
  id BIGSERIAL PRIMARY KEY,
  name TEXT UNIQUE NOT NULL,
  sort_order INTEGER NOT NULL DEFAULT 0,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO matching.master_languages (code, name, sort_order) VALUES
('en', 'English', 10),
('hi', 'Hindi', 20),
('ta', 'Tamil', 30),
('te', 'Telugu', 40),
('kn', 'Kannada', 50),
('ml', 'Malayalam', 60),
('mr', 'Marathi', 70),
('gu', 'Gujarati', 80),
('pa', 'Punjabi', 90),
('bn', 'Bengali', 100),
('or', 'Odia', 110),
('ur', 'Urdu', 120),
('as', 'Assamese', 130),
('kok', 'Konkani', 140),
('ks', 'Kashmiri', 150),
('ne', 'Nepali', 160),
('sa', 'Sanskrit', 170)
ON CONFLICT (name) DO UPDATE SET
  code = EXCLUDED.code,
  sort_order = EXCLUDED.sort_order;

INSERT INTO matching.master_workout_frequencies (name, sort_order) VALUES
('Never', 10),
('1-2 times a week', 20),
('3-4 times a week', 30),
('5+ times a week', 40),
('Daily', 50)
ON CONFLICT (name) DO UPDATE SET sort_order = EXCLUDED.sort_order;

INSERT INTO matching.master_diet_preferences (name, sort_order) VALUES
('No preference', 10),
('Vegetarian', 20),
('Eggetarian', 30),
('Non-vegetarian', 40),
('Vegan', 50),
('Jain', 60)
ON CONFLICT (name) DO UPDATE SET sort_order = EXCLUDED.sort_order;

INSERT INTO matching.master_diet_types (name, sort_order) VALUES
('Balanced', 10),
('High Protein', 20),
('Low Carb', 30),
('Keto', 40),
('Mediterranean', 50),
('Intermittent Fasting', 60)
ON CONFLICT (name) DO UPDATE SET sort_order = EXCLUDED.sort_order;

INSERT INTO matching.master_sleep_schedules (name, sort_order) VALUES
('Early bird', 10),
('Night owl', 20),
('Flexible', 30),
('Shift based', 40)
ON CONFLICT (name) DO UPDATE SET sort_order = EXCLUDED.sort_order;

INSERT INTO matching.master_travel_styles (name, sort_order) VALUES
('Homebody', 10),
('Occasional traveler', 20),
('Frequent traveler', 30),
('Adventure seeker', 40),
('Luxury traveler', 50),
('Backpacker', 60)
ON CONFLICT (name) DO UPDATE SET sort_order = EXCLUDED.sort_order;

INSERT INTO matching.master_political_comfort_ranges (name, sort_order) VALUES
('Similar views only', 10),
('Open to differences', 20),
('Prefer not to discuss', 30),
('No strong preference', 40)
ON CONFLICT (name) DO UPDATE SET sort_order = EXCLUDED.sort_order;
