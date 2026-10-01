-- Optional plan details shared by the two participants, never copied to contacts.
BEGIN;
ALTER TABLE matching.match_date_plans
 ADD COLUMN IF NOT EXISTS atmosphere_preferences TEXT[] NOT NULL DEFAULT '{}'
   CHECK(cardinality(atmosphere_preferences)<=3 AND atmosphere_preferences <@ ARRAY['quiet','relaxed','lively','outdoors','indoors']::text[]),
 ADD COLUMN IF NOT EXISTS accessibility_preferences TEXT[] NOT NULL DEFAULT '{}'
   CHECK(cardinality(accessibility_preferences)<=6 AND accessibility_preferences <@ ARRAY['step_free','accessible_toilet','seating','low_noise','nearby_transit','captions']::text[]);
-- The existing date_plan aggregate and field-names-only event trigger cover
-- these columns. Notification/feed payloads retain their explicit allowlists.
COMMIT;
