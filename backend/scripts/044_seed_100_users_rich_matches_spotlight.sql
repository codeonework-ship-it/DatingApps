-- =============================================================================
-- SEED 044: 100 Rich Users — Regular Matches + Spotlight Matches
-- =============================================================================
-- Groups:
--   A (i=1..25)   → 25 MALES   — regular discovery candidates
--   B (i=26..50)  → 25 FEMALES — regular discovery candidates
--   C (i=51..75)  → 25 MALES   — spotlight-eligible candidates
--   D (i=76..100) → 25 FEMALES — spotlight-eligible candidates
--
-- Match pairs:
--   A ↔ B  (25 regular matches, pair i_a with i_b = i_a + 25)
--   C ↔ D  (25 spotlight matches, pair i_c with i_d = i_c + 25)
--
-- Each user:
--   ✓ 3 photos (picsum seeds)
--   ✓ Full rich users row (bio, height, education, profession, lifestyle)
--   ✓ preferences row
--   ✓ user_settings row
--   ✓ 500-coin wallet entry
--
-- UUID generation prefix: 'seed44-user-N'
-- Photo UUID prefix:       'seed44-photo-N-J' (J = 1,2,3)
-- =============================================================================

-- ── Reference arrays for varied but deterministic data ──────────────────────
DO $$
DECLARE
  -- Index variables
  i   INTEGER;
  j   INTEGER;
  idx INTEGER;

  -- UUID helpers
  user_uuid  UUID;
  photo_uuid UUID;
  match_uuid UUID;


  -- Gender-specific name banks
  male_names   TEXT[] := ARRAY[
    'Arjun','Karan','Neil','Rohan','Aman','Dev','Varun','Siddharth','Rahul','Aditya',
    'Kabir','Vikram','Nikhil','Prateek','Anshul','Dhruv','Rishi','Kartik','Mihir','Tarun',
    'Yash','Shivam','Ashwin','Pranav','Neel'
  ];
  female_names TEXT[] := ARRAY[
    'Anya','Rhea','Mira','Ira','Tara','Naina','Priya','Kavya','Shreya','Meera',
    'Divya','Kritika','Aditi','Sneha','Pooja','Ananya','Riya','Tanvi','Simran','Aisha',
    'Natasha','Sara','Kiara','Nandita','Pallavi'
  ];

  -- City / state / country pools
  cities  TEXT[] := ARRAY['Bengaluru','Pune','Mumbai','Hyderabad','Delhi','Chennai','Kolkata','Ahmedabad'];
  states  TEXT[] := ARRAY['Karnataka','Maharashtra','Maharashtra','Telangana','Delhi','Tamil Nadu','West Bengal','Gujarat'];
  country TEXT := 'India';

  -- Education pool
  educations TEXT[] := ARRAY['B.Tech','MBA','M.Tech','B.Com','BCA','BA','B.Sc','CA'];
  -- Profession pool
  male_professions   TEXT[] := ARRAY[
    'Software Engineer','Data Scientist','Product Manager','Finance Analyst','UX Designer',
    'Machine Learning Engineer','Business Developer','Solutions Architect','Backend Engineer','DevOps Engineer',
    'Investment Banker','Marketing Lead','Startup Founder','Research Analyst','Consultant',
    'Blockchain Developer','Architect','Doctor','Content Strategist','Operations Manager',
    'Sales Manager','HR Lead','Cloud Engineer','Data Analyst','Full Stack Developer'
  ];
  female_professions TEXT[] := ARRAY[
    'Product Designer','Content Creator','Marketing Lead','HR Specialist','Doctor',
    'Graphic Designer','Brand Manager','Software Developer','Financial Analyst','Educator',
    'Social Media Manager','Photographer','Journalist','Entrepreneur','Data Analyst',
    'Fashion Designer','Interior Designer','Operations Lead','Event Planner','Consultant',
    'UX Researcher','Public Relations Manager','Nutritionist','Lawyer','Business Analyst'
  ];

  -- Lifestyle pools
  drinks TEXT[] := ARRAY['No','Occasionally','Socially','Regularly'];
  smokes TEXT[] := ARRAY['No','No','No','Occasionally'];
  religions TEXT[] := ARRAY['Hindu','Spiritual','Christian','Not Religious','Sikh','Muslim','Jain','Buddhist'];
  tongues TEXT[] := ARRAY['Hindi','English','Kannada','Telugu','Marathi','Tamil','Gujarati','Bengali'];
  rel_statuses TEXT[] := ARRAY['Single','Single','Single','Divorced','Never Married'];
  personalities TEXT[] := ARRAY['Introvert','Ambivert','Extrovert','Ambivert'];

  -- Lifestyle preferences
  pets   TEXT[] := ARRAY['Dogs','Cats','No Preference','No Pets'];
  diets  TEXT[] := ARRAY['Vegetarian','Non-Vegetarian','Vegan','Flexitarian'];
  workouts TEXT[] := ARRAY['Daily','3-4x/week','Weekends','Rarely'];
  sleeps TEXT[] := ARRAY['Early Bird','Night Owl','Flexible','Late Riser'];
  travels TEXT[] := ARRAY['Adventure','Luxury','Solo','Group','Backpacker'];

  -- Hobby banks
  male_hobbies TEXT[][] := ARRAY[
    ARRAY['Coding','Gaming','Hiking'],
    ARRAY['Cricket','Reading','Cycling'],
    ARRAY['Fitness','Photography','Cooking'],
    ARRAY['Music','Travel','Chess'],
    ARRAY['Running','Swimming','Blogging']
  ];
  female_hobbies TEXT[][] := ARRAY[
    ARRAY['Yoga','Painting','Reading'],
    ARRAY['Dancing','Travel','Cooking'],
    ARRAY['Running','Photography','Music'],
    ARRAY['Movie nights','Gardening','Sketching'],
    ARRAY['Hiking','Journaling','Theatre']
  ];

  songs TEXT[] := ARRAY['Golden Hour','Ilahi','Kesariya','Lover','Blinding Lights',
                         'A Sky Full of Stars','Tum Hi Ho','Roja','Shape of You','Raataan Lambiyan'];
  books TEXT[] := ARRAY['Atomic Habits','Deep Work','The Almanack of Naval','Zero to One',
                         'Thinking Fast and Slow','Sapiens','The Psychology of Money','Ikigai'];
  novels TEXT[] := ARRAY['The Alchemist','Normal People','The Kite Runner','Norwegian Wood',
                          'The Night Circus','Educated','Dune','1984'];
  activities TEXT[] := ARRAY['Community volunteering','Marathon group','Book club',
                               'Startup meetups','Animal shelter volunteer'];
  intent_tags TEXT[] := ARRAY['long_term','marriage','serious_only'];

  -- Height ranges
  male_height_min INTEGER := 168;
  female_height_min INTEGER := 155;

  -- Temporary working vars
  uname     TEXT;
  ubio      TEXT;
  udob      DATE;
  ugender   TEXT;
  uprof     TEXT;
  uedu      TEXT;
  ucity     TEXT;
  ustate    TEXT;
  udrink    TEXT;
  usmoke    TEXT;
  urel      TEXT;
  upers     TEXT;
  ulang     TEXT;
  uheight   INTEGER;
  udiet     TEXT;
  upet      TEXT;
  uwkout    TEXT;
  usleep    TEXT;
  utravel   TEXT;
  uhobby1   TEXT;
  uhobby2   TEXT;
  uhobby3   TEXT;
  usong     TEXT;
  ubook     TEXT;
  unovel    TEXT;
  uactivity TEXT;
  uintent   TEXT;
  photo1    TEXT;
  photo2    TEXT;
  photo3    TEXT;
  photo_seed1 TEXT;
  photo_seed2 TEXT;
  photo_seed3 TEXT;
  seeking   TEXT;

  -- Match pair vars
  user_a_uuid UUID;
  user_b_uuid UUID;

BEGIN

-- ────────────────────────────────────────────────────────────────────────────
-- GROUP A (i=1..25): Males — Regular Discovery Candidates
-- GROUP B (i=26..50): Females — Regular Discovery Candidates
-- GROUP C (i=51..75): Males — Spotlight
-- GROUP D (i=76..100): Females — Spotlight
-- ────────────────────────────────────────────────────────────────────────────

FOR i IN 1..100 LOOP
  -- Compute deterministic UUID
  user_uuid := md5('seed44-user-' || i::TEXT)::UUID;

  -- Determine gender and group
  IF i <= 25 THEN
    ugender := 'male';
    idx     := i;
    uname   := male_names[idx];
    uprof   := male_professions[idx];
    seeking := 'female';
    uheight := male_height_min + (i % 15);
    ubio    := uname || ' is a ' || uprof || ' based in ' ||
               cities[1 + ((i - 1) % array_length(cities, 1))] || '. ' ||
               'Loves good conversations, weekend hikes, and filter coffee. Looking for something real.';
  ELSIF i <= 50 THEN
    ugender := 'female';
    idx     := i - 25;
    uname   := female_names[idx];
    uprof   := female_professions[idx];
    seeking := 'male';
    uheight := female_height_min + (i % 13);
    ubio    := uname || ' is a ' || uprof || ' who believes in kindness and consistency. ' ||
               'You''ll find her reading in a café or exploring new trails. Looking for substance.';
  ELSIF i <= 75 THEN
    ugender := 'male';
    idx     := i - 50;
    uname   := male_names[idx];
    uprof   := male_professions[idx];
    seeking := 'female';
    uheight := male_height_min + (i % 15);
    ubio    := uname || ' is a ' || uprof || '. ' ||
               'Spotlight member who values emotional depth, shared ambitions, and long hikes. ' ||
               'Looking for a genuine connection beyond swipes.';
  ELSE
    ugender := 'female';
    idx     := i - 75;
    uname   := female_names[idx];
    uprof   := female_professions[idx];
    seeking := 'male';
    uheight := female_height_min + (i % 13);
    ubio    := uname || ' (Spotlight) — passionate ' || uprof || '. ' ||
               'Adventure seeker, dog lover, and big on intellectual conversations. ' ||
               'Looking for someone who shows up consistently.';
  END IF;

  -- Shared lifestyle fields (deterministic by i)
  uedu      := educations[1 + ((i - 1) % array_length(educations, 1))];
  ucity     := cities[1 + ((i - 1) % array_length(cities, 1))];
  ustate    := states[1 + ((i - 1) % array_length(states, 1))];
  udrink    := drinks[1 + ((i - 1) % array_length(drinks, 1))];
  usmoke    := smokes[1 + ((i - 1) % 4)];
  urel      := religions[1 + ((i - 1) % array_length(religions, 1))];
  ulang     := tongues[1 + ((i - 1) % array_length(tongues, 1))];
  upers     := personalities[1 + ((i - 1) % 4)];
  udiet     := diets[1 + ((i - 1) % array_length(diets, 1))];
  upet      := pets[1 + ((i - 1) % array_length(pets, 1))];
  uwkout    := workouts[1 + ((i - 1) % array_length(workouts, 1))];
  usleep    := sleeps[1 + ((i - 1) % array_length(sleeps, 1))];
  utravel   := travels[1 + ((i - 1) % array_length(travels, 1))];
  usong     := songs[1 + ((i - 1) % array_length(songs, 1))];
  ubook     := books[1 + ((i - 1) % array_length(books, 1))];
  unovel    := novels[1 + ((i - 1) % array_length(novels, 1))];
  uactivity := activities[1 + ((i - 1) % array_length(activities, 1))];
  uintent   := intent_tags[1 + ((i - 1) % 3)];

  -- Hobbies (gender-specific bank)
  IF ugender = 'male' THEN
    uhobby1 := male_hobbies[1 + ((i - 1) % 5)][1];
    uhobby2 := male_hobbies[1 + ((i - 1) % 5)][2];
    uhobby3 := male_hobbies[1 + ((i - 1) % 5)][3];
  ELSE
    uhobby1 := female_hobbies[1 + ((i - 1) % 5)][1];
    uhobby2 := female_hobbies[1 + ((i - 1) % 5)][2];
    uhobby3 := female_hobbies[1 + ((i - 1) % 5)][3];
  END IF;

  -- Date of birth: ages 23–35
  udob := (CURRENT_DATE - INTERVAL '1 year' * (23 + (i % 13)))::DATE;

  -- Photo picsum seeds (3 per user)
  photo_seed1 := replace(user_uuid::TEXT, '-', '') || 'a';
  photo_seed2 := replace(user_uuid::TEXT, '-', '') || 'b';
  photo_seed3 := replace(user_uuid::TEXT, '-', '') || 'c';
  photo1      := 'https://picsum.photos/seed/' || photo_seed1 || '/640/960';
  photo2      := 'https://picsum.photos/seed/' || photo_seed2 || '/640/960';
  photo3      := 'https://picsum.photos/seed/' || photo_seed3 || '/640/960';

  -- ── 1. user_management.users ─────────────────────────────────────────────
  INSERT INTO user_management.users (
    id, name, phone_number, date_of_birth, gender,
    bio, height_cm, education, profession,
    drinking, smoking, religion, mother_tongue,
    relationship_status, personality_type,
    country, state, city,
    profile_completion, is_verified, is_active,
    created_at, updated_at
  ) VALUES (
    user_uuid,
    uname,
    '+91900000' || lpad(i::TEXT, 4, '0'),
    udob,
    ugender,
    ubio,
    uheight,
    uedu,
    uprof,
    udrink,
    usmoke,
    urel,
    ulang,
    'Single',
    upers,
    country,
    ustate,
    ucity,
    100,
    (i % 3 != 0),   -- verified except every 3rd
    TRUE,
    now() - INTERVAL '1 day' * (100 - i),
    now() - INTERVAL '1 hour' * i
  )
  ON CONFLICT (id) DO UPDATE SET
    name                = EXCLUDED.name,
    bio                 = EXCLUDED.bio,
    height_cm           = EXCLUDED.height_cm,
    education           = EXCLUDED.education,
    profession          = EXCLUDED.profession,
    drinking            = EXCLUDED.drinking,
    smoking             = EXCLUDED.smoking,
    religion            = EXCLUDED.religion,
    mother_tongue       = EXCLUDED.mother_tongue,
    relationship_status = EXCLUDED.relationship_status,
    personality_type    = EXCLUDED.personality_type,
    country             = EXCLUDED.country,
    state               = EXCLUDED.state,
    city                = EXCLUDED.city,
    profile_completion  = EXCLUDED.profile_completion,
    is_verified         = EXCLUDED.is_verified,
    updated_at          = EXCLUDED.updated_at;

  -- ── 2. user_management.photos (3 per user) ───────────────────────────────
  FOR j IN 1..3 LOOP
    photo_uuid := md5('seed44-photo-' || i::TEXT || '-' || j::TEXT)::UUID;

    INSERT INTO user_management.photos (id, user_id, photo_url, ordering, storage_path)
    VALUES (
      photo_uuid,
      user_uuid,
      CASE j
        WHEN 1 THEN photo1
        WHEN 2 THEN photo2
        ELSE        photo3
      END,
      j,
      'seed/picsum/' || j::TEXT
    )
    ON CONFLICT (id) DO NOTHING;
  END LOOP;

  -- ── 3. user_management.profile_drafts ────────────────────────────────────
  INSERT INTO user_management.profile_drafts (
    user_id, draft_payload, lock_version, created_at, updated_at
  ) VALUES (
    user_uuid,
    jsonb_build_object(
      'bio',                    ubio,
      'name',                   uname,
      'height_cm',              uheight,
      'education',              uedu,
      'profession',             uprof,
      'drinking',               udrink,
      'smoking',                usmoke,
      'religion',               urel,
      'mother_tongue',          ulang,
      'relationship_status',    'Single',
      'personality_type',       upers,
      'country',                country,
      'state',                  ustate,
      'city',                   ucity,
      'pet_preference',         upet,
      'diet_preference',        udiet,
      'workout_frequency',      uwkout,
      'sleep_schedule',         usleep,
      'travel_style',           utravel,
      'party_lover',            (i % 5 = 0),
      'hobbies',                jsonb_build_array(uhobby1, uhobby2, uhobby3),
      'favorite_songs',         jsonb_build_array(usong),
      'favorite_books',         jsonb_build_array(ubook),
      'favorite_novels',        jsonb_build_array(unovel),
      'extra_curriculars',      jsonb_build_array(uactivity),
      'intent_tags',            jsonb_build_array(uintent),
      'language_tags',          jsonb_build_array('English', ulang),
      'profile_completion',     100,
      'seeking_genders',        jsonb_build_array(seeking),
      'photos',                 jsonb_build_array(
        jsonb_build_object('id', md5('seed44-photo-' || i::TEXT || '-1')::UUID, 'photo_url', photo1, 'ordering', 1),
        jsonb_build_object('id', md5('seed44-photo-' || i::TEXT || '-2')::UUID, 'photo_url', photo2, 'ordering', 2),
        jsonb_build_object('id', md5('seed44-photo-' || i::TEXT || '-3')::UUID, 'photo_url', photo3, 'ordering', 3)
      )
    ),
    0,
    now(),
    now()
  )
  ON CONFLICT (user_id) DO UPDATE SET
    draft_payload = EXCLUDED.draft_payload,
    updated_at    = EXCLUDED.updated_at;

  -- ── 4. user_management.preferences ───────────────────────────────────────
  INSERT INTO user_management.preferences (
    id, user_id, seeking_genders,
    min_age_years, max_age_years, max_distance_km,
    serious_only, verified_only,
    intent_tags, language_tags, deal_breaker_tags,
    updated_at
  ) VALUES (
    md5('seed44-pref-' || i::TEXT)::UUID,
    user_uuid,
    ARRAY[seeking],
    22, 36, 75,
    TRUE, FALSE,
    ARRAY[uintent],
    ARRAY['English', ulang],
    ARRAY[]::TEXT[],
    now()
  )
  ON CONFLICT (user_id) DO UPDATE SET
    seeking_genders = EXCLUDED.seeking_genders,
    updated_at      = EXCLUDED.updated_at;

  -- ── 5. user_management.user_settings ─────────────────────────────────────
  INSERT INTO user_management.user_settings (
    user_id, show_age, show_exact_distance, show_online_status,
    notify_new_match, notify_new_message, notify_likes,
    theme, lock_version, updated_at
  ) VALUES (
    user_uuid,
    TRUE, FALSE, TRUE,
    TRUE, TRUE, TRUE,
    'auto', 0, now()
  )
  ON CONFLICT (user_id) DO NOTHING;

  -- ── 6. matching.user_wallets ──────────────────────────────────────────────
  INSERT INTO matching.user_wallets (user_id, coin_balance, updated_at)
  VALUES (
    user_uuid,
    750,
    now()
  )
  ON CONFLICT (user_id) DO NOTHING;

END LOOP; -- end 100-user loop


-- ────────────────────────────────────────────────────────────────────────────
-- MATCH PAIRS: Group A (i=1..25) ↔ Group B (i=26..50) — Regular
-- ────────────────────────────────────────────────────────────────────────────
FOR i IN 1..25 LOOP
  user_a_uuid := md5('seed44-user-' || i::TEXT)::UUID;        -- male  (Group A)
  user_b_uuid := md5('seed44-user-' || (i + 25)::TEXT)::UUID; -- female (Group B)

  match_uuid  := md5('seed44-match-ab-' || i::TEXT)::UUID;

  INSERT INTO matching.matches (
    id,
    user_id_1, user_id_2,
    user_1_status, user_2_status,
    created_at
  ) VALUES (
    match_uuid,
    LEAST(user_a_uuid, user_b_uuid),
    GREATEST(user_a_uuid, user_b_uuid),
    'active', 'active',
    now() - INTERVAL '1 hour' * (25 - i)
  )
  ON CONFLICT (user_id_1, user_id_2) DO NOTHING;

  INSERT INTO matching.match_unlock_states (
    match_id, unlock_state, updated_at
  ) VALUES (
    (SELECT id FROM matching.matches
      WHERE user_id_1 = LEAST(user_a_uuid, user_b_uuid)
        AND user_id_2 = GREATEST(user_a_uuid, user_b_uuid)
      LIMIT 1),
    'matched',
    now()
  )
  ON CONFLICT (match_id) DO NOTHING;

  -- Activity events for both sides
  INSERT INTO matching.activity_events (
    id, user_id, event_name, event_domain,
    match_id, correlation_id, payload, created_at
  ) VALUES
  (
    md5('seed44-evt-ab-a-' || i::TEXT)::UUID,
    user_a_uuid,
    'match.created', 'matching',
    match_uuid,
    'seed44-corr-ab-' || i::TEXT,
    jsonb_build_object('partner_id', user_b_uuid),
    now() - INTERVAL '1 hour' * (25 - i)
  ),
  (
    md5('seed44-evt-ab-b-' || i::TEXT)::UUID,
    user_b_uuid,
    'match.created', 'matching',
    match_uuid,
    'seed44-corr-ab-' || i::TEXT,
    jsonb_build_object('partner_id', user_a_uuid),
    now() - INTERVAL '1 hour' * (25 - i)
  )
  ON CONFLICT (id) DO NOTHING;

END LOOP;


-- ────────────────────────────────────────────────────────────────────────────
-- SPOTLIGHT ELIGIBILITY: Group C (i=51..75) and Group D (i=76..100)
-- ────────────────────────────────────────────────────────────────────────────
FOR i IN 51..100 LOOP
  user_uuid := md5('seed44-user-' || i::TEXT)::UUID;

  INSERT INTO matching.spotlight_eligibility (
    user_id, tier, eligible, reason, effective_from, effective_to, updated_at
  ) VALUES (
    user_uuid,
    CASE WHEN i <= 75 THEN 'spotlight' ELSE 'spotlight' END,
    TRUE,
    'Seed 044 — spotlight user',
    now(),
    NULL,
    now()
  )
  ON CONFLICT (user_id) DO UPDATE SET
    eligible   = EXCLUDED.eligible,
    tier       = EXCLUDED.tier,
    updated_at = EXCLUDED.updated_at;

END LOOP;


-- ────────────────────────────────────────────────────────────────────────────
-- MATCH PAIRS: Group C (i=51..75) ↔ Group D (i=76..100) — Spotlight
-- ────────────────────────────────────────────────────────────────────────────
FOR i IN 1..25 LOOP
  user_a_uuid := md5('seed44-user-' || (i + 50)::TEXT)::UUID; -- male  (Group C)
  user_b_uuid := md5('seed44-user-' || (i + 75)::TEXT)::UUID; -- female (Group D)

  match_uuid  := md5('seed44-match-cd-' || i::TEXT)::UUID;

  INSERT INTO matching.matches (
    id,
    user_id_1, user_id_2,
    user_1_status, user_2_status,
    created_at
  ) VALUES (
    match_uuid,
    LEAST(user_a_uuid, user_b_uuid),
    GREATEST(user_a_uuid, user_b_uuid),
    'active', 'active',
    now() - INTERVAL '30 minutes' * (25 - i)
  )
  ON CONFLICT (user_id_1, user_id_2) DO NOTHING;

  INSERT INTO matching.match_unlock_states (
    match_id, unlock_state, updated_at
  ) VALUES (
    (SELECT id FROM matching.matches
      WHERE user_id_1 = LEAST(user_a_uuid, user_b_uuid)
        AND user_id_2 = GREATEST(user_a_uuid, user_b_uuid)
      LIMIT 1),
    'matched',
    now()
  )
  ON CONFLICT (match_id) DO NOTHING;

  -- Activity events (spotlight)
  INSERT INTO matching.activity_events (
    id, user_id, event_name, event_domain,
    match_id, correlation_id, payload, created_at
  ) VALUES
  (
    md5('seed44-evt-cd-a-' || i::TEXT)::UUID,
    user_a_uuid,
    'match.created', 'matching',
    match_uuid,
    'seed44-corr-cd-' || i::TEXT,
    jsonb_build_object('partner_id', user_b_uuid, 'spotlight', true),
    now() - INTERVAL '30 minutes' * (25 - i)
  ),
  (
    md5('seed44-evt-cd-b-' || i::TEXT)::UUID,
    user_b_uuid,
    'match.created', 'matching',
    match_uuid,
    'seed44-corr-cd-' || i::TEXT,
    jsonb_build_object('partner_id', user_a_uuid, 'spotlight', true),
    now() - INTERVAL '30 minutes' * (25 - i)
  )
  ON CONFLICT (id) DO NOTHING;

END LOOP;

END $$;

-- =============================================================================
-- VERIFICATION QUERIES (run manually to confirm seed applied correctly)
-- =============================================================================
-- SELECT COUNT(*) FROM user_management.users WHERE id IN (SELECT md5('seed44-user-' || generate_series(1,100)::TEXT)::UUID);
-- -- Expected: 100
--
-- SELECT COUNT(*) FROM user_management.photos WHERE user_id IN (SELECT md5('seed44-user-' || generate_series(1,100)::TEXT)::UUID);
-- -- Expected: 300 (3 per user)
--
-- SELECT COUNT(*) FROM matching.matches WHERE id IN (
--   SELECT md5('seed44-match-ab-' || generate_series(1,25)::TEXT)::UUID
--   UNION ALL
--   SELECT md5('seed44-match-cd-' || generate_series(1,25)::TEXT)::UUID
-- );
-- -- Expected: 50
--
-- SELECT COUNT(*) FROM matching.spotlight_eligibility WHERE user_id IN (
--   SELECT md5('seed44-user-' || generate_series(51,100)::TEXT)::UUID
-- );
-- -- Expected: 50
--
-- SELECT COUNT(DISTINCT bio) FROM user_management.users WHERE id IN (
--   SELECT md5('seed44-user-' || generate_series(1,100)::TEXT)::UUID
-- );
-- -- Expected: 100 (all unique bios)
