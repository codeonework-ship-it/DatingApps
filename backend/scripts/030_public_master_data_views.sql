-- Expose preference master data tables to PostgREST public schema consumers.
-- Run after 024_lifestyle_master_tables_seed.sql and 029_community_groups_tables.sql.

BEGIN;

CREATE OR REPLACE VIEW public.master_countries AS
SELECT
  id,
  code,
  name,
  is_active,
  created_at
FROM matching.master_countries;

CREATE OR REPLACE VIEW public.master_states AS
SELECT
  id,
  country_code,
  code,
  name,
  is_union_territory,
  is_active,
  created_at
FROM matching.master_states;

CREATE OR REPLACE VIEW public.master_cities AS
SELECT
  id,
  state_code,
  name,
  is_active,
  created_at
FROM matching.master_cities;

CREATE OR REPLACE VIEW public.master_religions AS
SELECT
  id,
  name,
  sort_order,
  is_active,
  created_at
FROM matching.master_religions;

CREATE OR REPLACE VIEW public.master_mother_tongues AS
SELECT
  id,
  name,
  sort_order,
  is_active,
  created_at
FROM matching.master_mother_tongues;

CREATE OR REPLACE VIEW public.master_languages AS
SELECT
  id,
  code,
  name,
  sort_order,
  is_active,
  created_at
FROM matching.master_languages;

CREATE OR REPLACE VIEW public.master_diet_preferences AS
SELECT
  id,
  name,
  sort_order,
  is_active,
  created_at
FROM matching.master_diet_preferences;

CREATE OR REPLACE VIEW public.master_workout_frequencies AS
SELECT
  id,
  name,
  sort_order,
  is_active,
  created_at
FROM matching.master_workout_frequencies;

CREATE OR REPLACE VIEW public.master_diet_types AS
SELECT
  id,
  name,
  sort_order,
  is_active,
  created_at
FROM matching.master_diet_types;

CREATE OR REPLACE VIEW public.master_sleep_schedules AS
SELECT
  id,
  name,
  sort_order,
  is_active,
  created_at
FROM matching.master_sleep_schedules;

CREATE OR REPLACE VIEW public.master_travel_styles AS
SELECT
  id,
  name,
  sort_order,
  is_active,
  created_at
FROM matching.master_travel_styles;

CREATE OR REPLACE VIEW public.master_political_comfort_ranges AS
SELECT
  id,
  name,
  sort_order,
  is_active,
  created_at
FROM matching.master_political_comfort_ranges;

GRANT USAGE ON SCHEMA public TO anon, authenticated;

GRANT SELECT ON TABLE
  public.master_countries,
  public.master_states,
  public.master_cities,
  public.master_religions,
  public.master_mother_tongues,
  public.master_languages,
  public.master_diet_preferences,
  public.master_workout_frequencies,
  public.master_diet_types,
  public.master_sleep_schedules,
  public.master_travel_styles,
  public.master_political_comfort_ranges
TO anon, authenticated;

COMMIT;
