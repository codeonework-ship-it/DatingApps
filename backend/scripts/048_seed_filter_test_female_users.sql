-- =============================================================================
-- SEED 048: Filter QA female cohorts for Maharashtra discovery + chat testing
-- =============================================================================
-- Purpose:
--   - Make phone 8879885106 a Kalyan, Maharashtra, India viewer profile.
--   - Seed 125 female discovery candidates across city + age filter cohorts.
--   - Mark a deterministic subset as premium/spotlight eligible.
--   - Create a few unlocked matches + chat messages for chat testing.
--
-- Idempotent: safe to run repeatedly.
-- =============================================================================

DO $$
DECLARE
  viewer_uuid UUID;
  existing_viewer UUID;
  city_names TEXT[] := ARRAY['Thane', 'Panvel', 'Andheri', 'Bandra', 'Mumbai'];
  min_ages INTEGER[] := ARRAY[18, 26, 31, 37, 18];
  max_ages INTEGER[] := ARRAY[25, 30, 36, 42, 30];
  city_idx INTEGER;
  i INTEGER;
  global_idx INTEGER := 0;
  candidate_uuid UUID;
  candidate_age INTEGER;
  candidate_city TEXT;
  candidate_name TEXT;
  dob DATE;
  phone TEXT;
  photo_uuid UUID;
  match_uuid UUID;
  now_ts TIMESTAMPTZ := now();
  photo_url TEXT;
  spotlight_user BOOLEAN;
BEGIN
  SELECT id INTO existing_viewer
  FROM user_management.users
  WHERE regexp_replace(coalesce(phone_number, ''), '\D', '', 'g') IN ('8879885106', '918879885106')
  ORDER BY updated_at DESC NULLS LAST
  LIMIT 1;

  viewer_uuid := COALESCE(existing_viewer, md5('seed48-viewer-8879885106')::UUID);

  INSERT INTO user_management.users (
    id, phone_number, name, date_of_birth, gender,
    bio, height_cm, education, profession,
    drinking, smoking, religion, mother_tongue,
    relationship_status, personality_type,
    country, state, city,
    profile_completion, is_verified, is_active,
    created_at, updated_at
  ) VALUES (
    viewer_uuid,
    '+918879885106',
    'Kalyan Test Viewer',
    DATE '1996-01-15',
    'male',
    'Filter QA viewer based in Kalyan, testing Maharashtra discovery preferences.',
    176,
    'B.Tech',
    'Product Manager',
    'Socially',
    'No',
    'Hindu',
    'Marathi',
    'Single',
    'Ambivert',
    'India',
    'Maharashtra',
    'Kalyan',
    100,
    TRUE,
    TRUE,
    now_ts,
    now_ts
  )
  ON CONFLICT (id) DO UPDATE SET
    phone_number = EXCLUDED.phone_number,
    name = COALESCE(NULLIF(user_management.users.name, ''), EXCLUDED.name),
    country = 'India',
    state = 'Maharashtra',
    city = 'Kalyan',
    drinking = 'Never',
    smoking = 'Never',
    profile_completion = 100,
    is_verified = TRUE,
    is_active = TRUE,
    updated_at = now_ts;

  INSERT INTO user_management.preferences (
    id, user_id, seeking_genders,
    min_age_years, max_age_years, max_distance_km,
    serious_only, verified_only,
    intent_tags, language_tags, deal_breaker_tags,
    updated_at
  ) VALUES (
    md5('seed48-viewer-pref')::UUID,
    viewer_uuid,
    ARRAY['female'],
    18,
    42,
    150,
    TRUE,
    FALSE,
    ARRAY['long_term','marriage'],
    ARRAY['English','Marathi','Hindi'],
    ARRAY[]::TEXT[],
    now_ts
  )
  ON CONFLICT (user_id) DO UPDATE SET
    seeking_genders = ARRAY['female'],
    min_age_years = 18,
    max_age_years = 42,
    max_distance_km = 150,
    serious_only = TRUE,
    verified_only = FALSE,
    intent_tags = EXCLUDED.intent_tags,
    language_tags = EXCLUDED.language_tags,
    updated_at = now_ts;

  INSERT INTO user_management.profile_drafts (
    user_id, draft_payload, lock_version, created_at, updated_at, completed_at, completion_source
  ) VALUES (
    viewer_uuid,
    jsonb_build_object(
      'user_id', viewer_uuid,
      'phone_number', '+918879885106',
      'name', 'Kalyan Test Viewer',
      'date_of_birth', '1996-01-15',
      'gender', 'male',
      'bio', 'Filter QA viewer based in Kalyan, testing Maharashtra discovery preferences.',
      'country', 'India',
      'state', 'Maharashtra',
      'city', 'Kalyan',
      'profile_completion', 100,
      'seeking_genders', jsonb_build_array('female'),
      'min_age_years', 18,
      'max_age_years', 42,
      'max_distance_km', 150,
      'intent_tags', jsonb_build_array('long_term', 'marriage'),
      'language_tags', jsonb_build_array('English', 'Marathi', 'Hindi')
    ),
    0,
    now_ts,
    now_ts,
    now_ts,
    'seed_048_filter_qa'
  )
  ON CONFLICT (user_id) DO UPDATE SET
    draft_payload = EXCLUDED.draft_payload,
    updated_at = now_ts,
    completed_at = now_ts,
    completion_source = 'seed_048_filter_qa';

  INSERT INTO user_management.user_settings (
    user_id, show_age, show_exact_distance, show_online_status,
    notify_new_match, notify_new_message, notify_likes,
    theme, lock_version, updated_at
  ) VALUES (
    viewer_uuid, TRUE, FALSE, TRUE, TRUE, TRUE, TRUE, 'auto', 0, now_ts
  )
  ON CONFLICT (user_id) DO NOTHING;

  FOR city_idx IN 1..array_length(city_names, 1) LOOP
    FOR i IN 1..25 LOOP
      global_idx := global_idx + 1;
      candidate_city := city_names[city_idx];
      candidate_age := min_ages[city_idx] + ((i - 1) % (max_ages[city_idx] - min_ages[city_idx] + 1));
      dob := make_date(EXTRACT(YEAR FROM CURRENT_DATE)::INTEGER - candidate_age, 1, 15);
      candidate_uuid := md5('seed48-female-' || global_idx::TEXT)::UUID;
      candidate_name := candidate_city || ' QA ' || lpad(i::TEXT, 2, '0');
      phone := '+917748' || lpad(global_idx::TEXT, 6, '0');
      spotlight_user := (i <= 5);

      INSERT INTO user_management.users (
        id, phone_number, name, date_of_birth, gender,
        bio, height_cm, education, profession,
        drinking, smoking, religion, mother_tongue,
        relationship_status, personality_type,
        country, state, city,
        profile_completion, is_verified, is_active,
        created_at, updated_at
      ) VALUES (
        candidate_uuid,
        phone,
        candidate_name,
        dob,
        'female',
        candidate_name || ' is a verified Maharashtra filter QA profile in ' || candidate_city || ', age ' || candidate_age || '.',
        155 + (i % 13),
        CASE WHEN i % 4 = 0 THEN 'MBA' WHEN i % 4 = 1 THEN 'B.Tech' WHEN i % 4 = 2 THEN 'B.Com' ELSE 'B.Des' END,
        CASE WHEN i % 5 = 0 THEN 'Doctor' WHEN i % 5 = 1 THEN 'Product Designer' WHEN i % 5 = 2 THEN 'Software Developer' WHEN i % 5 = 3 THEN 'Marketing Lead' ELSE 'Entrepreneur' END,
        'Never',
        'Never',
        'Hindu',
        'Marathi',
        'Single',
        'Ambivert',
        'India',
        'Maharashtra',
        candidate_city,
        100,
        TRUE,
        TRUE,
        now_ts - ((125 - global_idx) || ' minutes')::INTERVAL,
        now_ts
      )
      ON CONFLICT (id) DO UPDATE SET
        phone_number = EXCLUDED.phone_number,
        name = EXCLUDED.name,
        date_of_birth = EXCLUDED.date_of_birth,
        gender = 'female',
        bio = EXCLUDED.bio,
        height_cm = EXCLUDED.height_cm,
        education = EXCLUDED.education,
        profession = EXCLUDED.profession,
        drinking = EXCLUDED.drinking,
        smoking = EXCLUDED.smoking,
        religion = EXCLUDED.religion,
        mother_tongue = EXCLUDED.mother_tongue,
        relationship_status = EXCLUDED.relationship_status,
        personality_type = EXCLUDED.personality_type,
        country = 'India',
        state = 'Maharashtra',
        city = EXCLUDED.city,
        profile_completion = 100,
        is_verified = TRUE,
        is_active = TRUE,
        updated_at = now_ts;

      INSERT INTO user_management.preferences (
        id, user_id, seeking_genders,
        min_age_years, max_age_years, max_distance_km,
        serious_only, verified_only,
        intent_tags, language_tags, deal_breaker_tags,
        updated_at
      ) VALUES (
        md5('seed48-pref-' || global_idx::TEXT)::UUID,
        candidate_uuid,
        ARRAY['male'],
        18,
        45,
        150,
        TRUE,
        FALSE,
        ARRAY['long_term','marriage'],
        ARRAY['English','Marathi','Hindi'],
        ARRAY[]::TEXT[],
        now_ts
      )
      ON CONFLICT (user_id) DO UPDATE SET
        seeking_genders = ARRAY['male'],
        min_age_years = 18,
        max_age_years = 45,
        max_distance_km = 150,
        serious_only = TRUE,
        verified_only = FALSE,
        intent_tags = EXCLUDED.intent_tags,
        language_tags = EXCLUDED.language_tags,
        updated_at = now_ts;

      DELETE FROM user_management.photos WHERE user_id = candidate_uuid;
      FOR photo_uuid IN
        SELECT md5('seed48-photo-' || global_idx::TEXT || '-1')::UUID
        UNION ALL SELECT md5('seed48-photo-' || global_idx::TEXT || '-2')::UUID
        UNION ALL SELECT md5('seed48-photo-' || global_idx::TEXT || '-3')::UUID
      LOOP
        photo_url := 'https://picsum.photos/seed/seed48-' || replace(candidate_city, ' ', '') || '-' || global_idx::TEXT || '-' || right(photo_uuid::TEXT, 2) || '/900/1200';
        INSERT INTO user_management.photos (id, user_id, photo_url, ordering, storage_path, uploaded_at, is_moderated, is_flagged)
        VALUES (
          photo_uuid,
          candidate_uuid,
          photo_url,
          (SELECT COUNT(*) + 1 FROM user_management.photos WHERE user_id = candidate_uuid),
          'seed48/' || global_idx::TEXT || '/' || right(photo_uuid::TEXT, 2),
          now_ts,
          TRUE,
          FALSE
        )
        ON CONFLICT (id) DO NOTHING;
      END LOOP;

      INSERT INTO user_management.profile_drafts (
        user_id, draft_payload, lock_version, created_at, updated_at, completed_at, completion_source
      ) VALUES (
        candidate_uuid,
        jsonb_build_object(
          'user_id', candidate_uuid,
          'phone_number', phone,
          'name', candidate_name,
          'date_of_birth', to_char(dob, 'YYYY-MM-DD'),
          'gender', 'female',
          'bio', candidate_name || ' is a verified Maharashtra filter QA profile in ' || candidate_city || ', age ' || candidate_age || '.',
          'height_cm', 155 + (i % 13),
          'education', CASE WHEN i % 4 = 0 THEN 'MBA' WHEN i % 4 = 1 THEN 'B.Tech' WHEN i % 4 = 2 THEN 'B.Com' ELSE 'B.Des' END,
          'profession', CASE WHEN i % 5 = 0 THEN 'Doctor' WHEN i % 5 = 1 THEN 'Product Designer' WHEN i % 5 = 2 THEN 'Software Developer' WHEN i % 5 = 3 THEN 'Marketing Lead' ELSE 'Entrepreneur' END,
          'drinking', 'Never',
          'smoking', 'Never',
          'religion', 'Hindu',
          'mother_tongue', 'Marathi',
          'relationship_status', 'Single',
          'personality_type', 'Ambivert',
          'country', 'India',
          'state', 'Maharashtra',
          'city', candidate_city,
          'profile_completion', 100,
          'seeking_genders', jsonb_build_array('male'),
          'min_age_years', 18,
          'max_age_years', 45,
          'max_distance_km', 150,
          'intent_tags', jsonb_build_array('long_term', 'marriage'),
          'language_tags', jsonb_build_array('English', 'Marathi', 'Hindi'),
          'hobbies', jsonb_build_array('Travel', 'Music', 'Coffee'),
          'favorite_songs', jsonb_build_array('Golden Hour'),
          'extra_curriculars', jsonb_build_array('Community volunteering'),
          'photos', (
            SELECT jsonb_agg(jsonb_build_object('id', p.id, 'photo_url', p.photo_url, 'ordering', p.ordering) ORDER BY p.ordering)
            FROM user_management.photos p
            WHERE p.user_id = candidate_uuid
          )
        ),
        0,
        now_ts,
        now_ts,
        now_ts,
        'seed_048_filter_qa'
      )
      ON CONFLICT (user_id) DO UPDATE SET
        draft_payload = EXCLUDED.draft_payload,
        updated_at = now_ts,
        completed_at = now_ts,
        completion_source = 'seed_048_filter_qa';

      INSERT INTO user_management.user_settings (
        user_id, show_age, show_exact_distance, show_online_status,
        notify_new_match, notify_new_message, notify_likes,
        theme, lock_version, updated_at
      ) VALUES (
        candidate_uuid, TRUE, FALSE, TRUE, TRUE, TRUE, TRUE, 'auto', 0, now_ts
      )
      ON CONFLICT (user_id) DO NOTHING;

      INSERT INTO matching.user_wallets (user_id, coin_balance, updated_at)
      VALUES (candidate_uuid, CASE WHEN spotlight_user THEN 2500 ELSE 750 END, now_ts)
      ON CONFLICT (user_id) DO UPDATE SET
        coin_balance = EXCLUDED.coin_balance,
        updated_at = now_ts;

      IF spotlight_user THEN
        INSERT INTO matching.spotlight_eligibility (
          user_id, tier, eligible, reason, effective_from, effective_to, updated_at
        ) VALUES (
          candidate_uuid, 'diamond', TRUE, 'Seed 048 premium spotlight QA user', now_ts, NULL, now_ts
        )
        ON CONFLICT (user_id) DO UPDATE SET
          tier = 'diamond',
          eligible = TRUE,
          reason = EXCLUDED.reason,
          effective_from = now_ts,
          effective_to = NULL,
          updated_at = now_ts;

        INSERT INTO matching.billing_subscriptions_runtime (
          id, user_id, plan_code, status, billing_cycle, start_date, end_date,
          next_billing_date, auto_renew, provider_subscription_id, lock_version,
          created_at, updated_at
        ) VALUES (
          md5('seed48-sub-' || global_idx::TEXT)::UUID,
          candidate_uuid,
          'diamond',
          'active',
          'monthly',
          now_ts - INTERVAL '2 days',
          NULL,
          now_ts + INTERVAL '28 days',
          TRUE,
          'seed48-sub-' || global_idx::TEXT,
          0,
          now_ts,
          now_ts
        )
        ON CONFLICT (id) DO UPDATE SET
          status = 'active',
          plan_code = 'diamond',
          next_billing_date = EXCLUDED.next_billing_date,
          updated_at = now_ts;

        INSERT INTO matching.user_trust_badges (id, user_id, badge_code, status, score, awarded_at, updated_at)
        VALUES
          (md5('seed48-badge-phone-' || global_idx::TEXT)::UUID, candidate_uuid, 'phone_verified', 'active', 100, now_ts, now_ts),
          (md5('seed48-badge-photo-' || global_idx::TEXT)::UUID, candidate_uuid, 'photo_verified', 'active', 100, now_ts, now_ts),
          (md5('seed48-badge-profile-' || global_idx::TEXT)::UUID, candidate_uuid, 'profile_complete', 'active', 100, now_ts, now_ts)
        ON CONFLICT (user_id, badge_code) DO UPDATE SET
          status = 'active',
          score = EXCLUDED.score,
          updated_at = now_ts;
      END IF;

      IF global_idx <= 10 THEN
        match_uuid := md5('seed48-chat-match-' || global_idx::TEXT)::UUID;
        INSERT INTO matching.matches (
          id, user_id_1, user_id_2, user_1_status, user_2_status, chat_count, last_message_at, created_at
        ) VALUES (
          match_uuid,
          LEAST(viewer_uuid, candidate_uuid),
          GREATEST(viewer_uuid, candidate_uuid),
          'active',
          'active',
          2,
          now_ts - ((10 - global_idx) || ' minutes')::INTERVAL,
          now_ts - ((20 - global_idx) || ' minutes')::INTERVAL
        )
        ON CONFLICT (user_id_1, user_id_2) DO UPDATE SET
          user_1_status = 'active',
          user_2_status = 'active',
          chat_count = 2,
          last_message_at = EXCLUDED.last_message_at;

        SELECT id INTO match_uuid
        FROM matching.matches
        WHERE user_id_1 = LEAST(viewer_uuid, candidate_uuid)
          AND user_id_2 = GREATEST(viewer_uuid, candidate_uuid);

        INSERT INTO matching.match_unlock_states (match_id, unlock_state, updated_at)
        VALUES (match_uuid, 'conversation_unlocked', now_ts)
        ON CONFLICT (match_id) DO UPDATE SET
          unlock_state = 'conversation_unlocked',
          updated_at = now_ts;

        INSERT INTO matching.messages (id, match_id, sender_id, text, created_at, delivered_at, read_at, is_deleted)
        VALUES
          (md5('seed48-msg-a-' || global_idx::TEXT)::UUID, match_uuid, candidate_uuid, 'Hi from ' || candidate_name || ' — this is a seeded chat for QA.', now_ts - INTERVAL '5 minutes', now_ts - INTERVAL '4 minutes', NULL, FALSE),
          (md5('seed48-msg-b-' || global_idx::TEXT)::UUID, match_uuid, viewer_uuid, 'Thanks! Testing chat flow and read receipts.', now_ts - INTERVAL '3 minutes', now_ts - INTERVAL '2 minutes', NULL, FALSE)
        ON CONFLICT (id) DO UPDATE SET
          text = EXCLUDED.text,
          created_at = EXCLUDED.created_at,
          delivered_at = EXCLUDED.delivered_at,
          read_at = EXCLUDED.read_at,
          is_deleted = FALSE;
      END IF;
    END LOOP;
  END LOOP;

  RAISE NOTICE 'Seed 048 complete. viewer_user_id=%; female_candidates=125; spotlight_candidates=25; chat_matches=10', viewer_uuid;
END $$;

-- Verification helpers:
-- SELECT city, MIN(EXTRACT(YEAR FROM age(CURRENT_DATE, date_of_birth))) AS min_age,
--        MAX(EXTRACT(YEAR FROM age(CURRENT_DATE, date_of_birth))) AS max_age,
--        COUNT(*)
-- FROM user_management.users
-- WHERE id IN (SELECT md5('seed48-female-' || generate_series(1,125)::TEXT)::UUID)
-- GROUP BY city
-- ORDER BY city;
