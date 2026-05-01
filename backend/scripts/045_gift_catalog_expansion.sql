-- ─────────────────────────────────────────────────────────────────────────────
-- 045: Gift Catalog Expansion
--   • Adds category, max_per_match_per_day, start_date, end_date to gift_catalog
--   • Adds is_system, message to match_gift_sends
--   • Creates gift_daily_entitlements table
--   • Creates admirer_gift_escrow table
--   • Seeds 23 new catalog items across themed_pack, reaction, experience,
--     seasonal, and exclusive categories (all DB-driven, no hardcoded fallback)
-- Safe to run repeatedly on Supabase/Postgres.
-- ─────────────────────────────────────────────────────────────────────────────

-- ── 1. Extend gift_catalog ────────────────────────────────────────────────────

ALTER TABLE matching.gift_catalog
  ADD COLUMN IF NOT EXISTS category           TEXT NOT NULL DEFAULT 'roses',
  ADD COLUMN IF NOT EXISTS max_per_match_per_day INT DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS start_date        TIMESTAMPTZ DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS end_date          TIMESTAMPTZ DEFAULT NULL;

CREATE INDEX IF NOT EXISTS idx_gift_catalog_category_active
  ON matching.gift_catalog(category, is_active, sort_order ASC);

-- Back-fill existing rows
UPDATE matching.gift_catalog
  SET category = 'roses'
  WHERE category IS NULL OR category = '';

-- ── 2. Extend match_gift_sends ────────────────────────────────────────────────

ALTER TABLE matching.match_gift_sends
  ADD COLUMN IF NOT EXISTS is_system BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS message   TEXT    DEFAULT NULL;

-- Message length constraint (1–500 chars when supplied)
ALTER TABLE matching.match_gift_sends
  DROP CONSTRAINT IF EXISTS chk_gift_message_length;

ALTER TABLE matching.match_gift_sends
  ADD CONSTRAINT chk_gift_message_length
  CHECK (message IS NULL OR (char_length(message) BETWEEN 1 AND 500));

-- ── 3. gift_daily_entitlements ────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS matching.gift_daily_entitlements (
  user_id    UUID   NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  used_date  DATE   NOT NULL,
  used_count INTEGER NOT NULL DEFAULT 0 CHECK (used_count >= 0),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (user_id, used_date)
);

CREATE INDEX IF NOT EXISTS idx_gift_daily_entitlements_user_date
  ON matching.gift_daily_entitlements(user_id, used_date DESC);

-- ── 4. admirer_gift_escrow ────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS matching.admirer_gift_escrow (
  id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sender_user_id     UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  candidate_user_id  UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  gift_id            TEXT NOT NULL REFERENCES matching.gift_catalog(id),
  gift_name          TEXT NOT NULL,
  price_coins        INTEGER NOT NULL DEFAULT 0 CHECK (price_coins >= 0),
  status             TEXT NOT NULL DEFAULT 'pending'
                       CHECK (status IN ('pending','delivered','refunded','cancelled')),
  idempotency_key    TEXT DEFAULT NULL,
  escrow_expires_at  TIMESTAMPTZ NOT NULL,
  delivered_at       TIMESTAMPTZ DEFAULT NULL,
  refunded_at        TIMESTAMPTZ DEFAULT NULL,
  created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_admirer_gift_escrow_sender
  ON matching.admirer_gift_escrow(sender_user_id, status, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_admirer_gift_escrow_candidate
  ON matching.admirer_gift_escrow(candidate_user_id, status);

CREATE INDEX IF NOT EXISTS idx_admirer_gift_escrow_expires
  ON matching.admirer_gift_escrow(escrow_expires_at) WHERE status = 'pending';

-- ── 5. Seed: New catalog items ─────────────────────────────────────────────────
-- All items are fully DB-driven; no hardcoded runtime fallback when DB is live.
-- icon_key values map to Flutter asset resolution and glyph renderer.

INSERT INTO matching.gift_catalog
  (id, name, gif_url, icon_key, tier, category, price_coins, is_limited, is_active, sort_order, max_per_match_per_day)
VALUES

  -- ── Themed Packs ────────────────────────────────────────────────────────────
  ('chocolate_box',
   'Chocolate Box',
   'https://media.giphy.com/media/l0HlvtIPzPdt2usKs/giphy.gif',
   'chocolate_box',
   'free', 'themed_pack', 0, FALSE, TRUE, 200, NULL),

  ('teddy_bear',
   'Teddy Bear',
   'https://media.giphy.com/media/3oEdv2mgehGvnT4Bna/giphy.gif',
   'teddy_bear',
   'premium_common', 'themed_pack', 2, FALSE, TRUE, 210, NULL),

  ('flower_bouquet',
   'Flower Bouquet',
   'https://media.giphy.com/media/26FmQJf4HFwF4KZIS/giphy.gif',
   'flower_bouquet',
   'premium_rare', 'themed_pack', 3, FALSE, TRUE, 220, NULL),

  ('jewellery_box',
   'Jewellery Box',
   'https://media.giphy.com/media/l0HlGCLXV4oMBv1i0/giphy.gif',
   'jewellery_box',
   'premium_epic', 'themed_pack', 5, FALSE, TRUE, 230, NULL),

  ('champagne_toast',
   'Champagne Toast',
   'https://media.giphy.com/media/26BRQaiZM26IjjOZq/giphy.gif',
   'champagne_toast',
   'premium_legendary', 'themed_pack', 8, FALSE, TRUE, 240, NULL),

  ('heart_balloon',
   'Heart Balloon',
   'https://media.giphy.com/media/3o7TKwmnDgQb5jemjK/giphy.gif',
   'heart_balloon',
   'premium_common', 'themed_pack', 1, FALSE, TRUE, 250, NULL),

  -- ── Animated Reactions ───────────────────────────────────────────────────────
  ('heart_explosion',
   'Heart Explosion',
   'https://media.giphy.com/media/l0MYt5jPR6QX5pnqM/giphy.gif',
   'heart_explosion',
   'free', 'reaction', 0, FALSE, TRUE, 300, NULL),

  ('confetti_shower',
   'Confetti Shower',
   'https://media.giphy.com/media/26tOZ42Mg6pbTUPHW/giphy.gif',
   'confetti_shower',
   'premium_common', 'reaction', 1, FALSE, TRUE, 310, NULL),

  ('fireworks_burst',
   'Fireworks Burst',
   'https://media.giphy.com/media/3o7TKtnuHOHHUjR38Y/giphy.gif',
   'fireworks_burst',
   'premium_rare', 'reaction', 3, FALSE, TRUE, 320, NULL),

  ('golden_sparkle',
   'Golden Sparkle',
   'https://media.giphy.com/media/l0HlJDPyl3x5QVBDO/giphy.gif',
   'golden_sparkle',
   'premium_epic', 'reaction', 5, FALSE, TRUE, 330, NULL),

  ('rainbow_wave',
   'Rainbow Wave',
   'https://media.giphy.com/media/l0Iyl55kTeh71nTXy/giphy.gif',
   'rainbow_wave',
   'premium_legendary', 'reaction', 8, FALSE, TRUE, 340, NULL),

  ('star_shower',
   'Star Shower',
   'https://media.giphy.com/media/3oriO13KTkzPwTykp2/giphy.gif',
   'star_shower',
   'premium_rare', 'reaction', 3, FALSE, TRUE, 350, NULL),

  -- ── Virtual Experiences ─────────────────────────────────────────────────────
  ('coffee_date_invite',
   'Coffee Date Invite',
   'https://media.giphy.com/media/3o7TKtnuHOHHUjR38Y/giphy.gif',
   'coffee_date',
   'premium_rare', 'experience', 3, FALSE, TRUE, 400, NULL),

  ('picnic_invite',
   'Picnic Invite',
   'https://media.giphy.com/media/26BRv0ThflsHCqDrG/giphy.gif',
   'picnic_invite',
   'premium_rare', 'experience', 3, FALSE, TRUE, 410, NULL),

  ('movie_night_invite',
   'Movie Night Invite',
   'https://media.giphy.com/media/3o7TKtnuHOHHUjR38Y/giphy.gif',
   'movie_night',
   'premium_epic', 'experience', 5, FALSE, TRUE, 420, NULL),

  ('sunset_walk_invite',
   'Sunset Walk Invite',
   'https://media.giphy.com/media/26xBwdIuRJiAIqHwA/giphy.gif',
   'sunset_walk',
   'premium_epic', 'experience', 5, FALSE, TRUE, 430, NULL),

  ('date_night_card',
   'Date Night Card',
   'https://media.giphy.com/media/l0HlBO7eyXzSZkJri/giphy.gif',
   'date_night',
   'premium_legendary', 'experience', 8, FALSE, TRUE, 440, NULL),

  -- ── Seasonal ────────────────────────────────────────────────────────────────
  ('valentine_surprise',
   'Valentine''s Surprise',
   'https://media.giphy.com/media/l41YvpiA9uMWw5AMU/giphy.gif',
   'valentine_surprise',
   'seasonal_limited', 'seasonal', 6, TRUE, TRUE, 500,  NULL),

  ('christmas_gift',
   'Christmas Gift',
   'https://media.giphy.com/media/26xBydxfjxsRQggh2/giphy.gif',
   'christmas_gift',
   'seasonal_limited', 'seasonal', 6, TRUE, FALSE, 510, NULL),

  ('diwali_cracker',
   'Diwali Cracker',
   'https://media.giphy.com/media/3o7TKtnuHOHHUjR38Y/giphy.gif',
   'diwali_cracker',
   'seasonal_limited', 'seasonal', 6, TRUE, FALSE, 520, NULL),

  ('new_year_fireworks',
   'New Year Fireworks',
   'https://media.giphy.com/media/3oriO13KTkzPwTykp2/giphy.gif',
   'new_year_fireworks',
   'seasonal_limited', 'seasonal', 6, TRUE, FALSE, 530, NULL),

  -- ── Exclusive tier ──────────────────────────────────────────────────────────
  ('exclusive_diamond_ring',
   'Diamond Ring',
   'https://media.giphy.com/media/3o7aD2saalBwwftBIY/giphy.gif',
   'diamond_ring',
   'exclusive', 'themed_pack', 20, TRUE, TRUE, 600, 1),

  ('exclusive_luxury_date',
   'Luxury Date Experience',
   'https://media.giphy.com/media/l0HlBO7eyXzSZkJri/giphy.gif',
   'luxury_date',
   'exclusive', 'experience', 20, TRUE, TRUE, 610, 1)

ON CONFLICT (id) DO UPDATE SET
  name                = EXCLUDED.name,
  gif_url             = EXCLUDED.gif_url,
  icon_key            = EXCLUDED.icon_key,
  tier                = EXCLUDED.tier,
  category            = EXCLUDED.category,
  price_coins         = EXCLUDED.price_coins,
  is_limited          = EXCLUDED.is_limited,
  is_active           = EXCLUDED.is_active,
  sort_order          = EXCLUDED.sort_order,
  max_per_match_per_day = EXCLUDED.max_per_match_per_day,
  updated_at          = NOW();

-- ── 6. Verify ────────────────────────────────────────────────────────────────

DO $$
DECLARE
  total_count INTEGER;
  cat_count   INTEGER;
BEGIN
  SELECT COUNT(*) INTO total_count FROM matching.gift_catalog WHERE is_active = TRUE;
  SELECT COUNT(DISTINCT category) INTO cat_count FROM matching.gift_catalog WHERE is_active = TRUE;
  IF total_count < 30 THEN
    RAISE EXCEPTION 'gift_catalog has fewer active items than expected: %', total_count;
  END IF;
  RAISE NOTICE 'gift_catalog: % active items across % categories', total_count, cat_count;
END $$;
