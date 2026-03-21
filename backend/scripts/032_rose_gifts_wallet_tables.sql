-- Rose gifts catalog, wallet balance, and gift send persistence tables.
-- Safe to run repeatedly on Supabase/Postgres.

CREATE TABLE IF NOT EXISTS matching.gift_catalog (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  gif_url TEXT NOT NULL,
  tier TEXT NOT NULL,
  price_coins INTEGER NOT NULL DEFAULT 0 CHECK (price_coins >= 0),
  is_limited BOOLEAN NOT NULL DEFAULT FALSE,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  sort_order INTEGER NOT NULL DEFAULT 100,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_gift_catalog_active_sort
  ON matching.gift_catalog(is_active, sort_order ASC, id ASC);

INSERT INTO matching.gift_catalog (id, name, gif_url, tier, price_coins, is_limited, is_active, sort_order)
VALUES
  ('rose_red_single', 'Single Red Rose', 'https://media.giphy.com/media/26xBwdIuRJiAIqHwA/giphy.gif', 'free', 0, FALSE, TRUE, 10),
  ('rose_pink_soft', 'Pink Rose', 'https://media.giphy.com/media/fVtcfEXWQJQUbsF1sH/giphy.gif', 'free', 0, FALSE, TRUE, 20),
  ('rose_white_pure', 'White Rose', 'https://media.giphy.com/media/xT1XGzAnABSXy8DPCU/giphy.gif', 'free', 0, FALSE, TRUE, 30),
  ('rose_yellow_friendship', 'Yellow Rose', 'https://media.giphy.com/media/l0Iy5tjhyfU1xL9wQ/giphy.gif', 'free', 0, FALSE, TRUE, 40),
  ('rose_lavender_crush', 'Lavender Rose', 'https://media.giphy.com/media/26xBukhL8Y5H9P9VS/giphy.gif', 'free', 0, FALSE, TRUE, 50),
  ('rose_blue_rare', 'Blue Rose', 'https://media.giphy.com/media/3oz8xAFtqoOUUrsh7W/giphy.gif', 'premium_common', 1, FALSE, TRUE, 60),
  ('rose_black_mystery', 'Black Rose', 'https://media.giphy.com/media/l0ExncehJzexFpRHq/giphy.gif', 'premium_common', 1, FALSE, TRUE, 70),
  ('rose_sparkle', 'Sparkle Rose', 'https://media.giphy.com/media/3o7TKz9b9NQwQ2N8hW/giphy.gif', 'premium_rare', 3, FALSE, TRUE, 80),
  ('rose_heart_petal', 'Heart-Petal Rose', 'https://media.giphy.com/media/l41YvpiA9uMWw5AMU/giphy.gif', 'premium_rare', 3, FALSE, TRUE, 90),
  ('rose_neon_glow', 'Neon Rose', 'https://media.giphy.com/media/l0Ex7d6Q5V3sz9N16/giphy.gif', 'premium_rare', 3, FALSE, TRUE, 95),
  ('rose_rain', 'Rose Rain', 'https://media.giphy.com/media/l41YB9N3dM2P8xTzG/giphy.gif', 'premium_epic', 5, FALSE, TRUE, 100),
  ('rose_burning_flame', 'Burning Rose', 'https://media.giphy.com/media/3o6Zt481isNVuQI1l6/giphy.gif', 'premium_epic', 5, FALSE, TRUE, 105),
  ('rose_golden', 'Golden Rose', 'https://media.giphy.com/media/l0HlBO7eyXzSZkJri/giphy.gif', 'premium_legendary', 8, TRUE, TRUE, 110),
  ('rose_crystal', 'Crystal Rose', 'https://media.giphy.com/media/3o7aD2saalBwwftBIY/giphy.gif', 'premium_legendary', 10, TRUE, TRUE, 120),
  ('rose_bouquet_12', 'Rose Bouquet (12)', 'https://media.giphy.com/media/xTiTnMhJTwNHChdTZS/giphy.gif', 'premium_legendary', 8, TRUE, TRUE, 125),
  ('rose_bouquet_24', 'Rose Bouquet (24)', 'https://media.giphy.com/media/26xBydxfjxsRQggh2/giphy.gif', 'premium_legendary', 10, TRUE, TRUE, 130),
  ('rose_seasonal_weekly', 'Seasonal Limited Rose', 'https://media.giphy.com/media/l0MYAs5E2oIDCq9So/giphy.gif', 'seasonal_limited', 6, TRUE, TRUE, 140)
ON CONFLICT (id) DO UPDATE
SET
  name = EXCLUDED.name,
  gif_url = EXCLUDED.gif_url,
  tier = EXCLUDED.tier,
  price_coins = EXCLUDED.price_coins,
  is_limited = EXCLUDED.is_limited,
  is_active = EXCLUDED.is_active,
  sort_order = EXCLUDED.sort_order,
  updated_at = NOW();

CREATE TABLE IF NOT EXISTS matching.user_wallets (
  user_id UUID PRIMARY KEY,
  coin_balance INTEGER NOT NULL DEFAULT 12 CHECK (coin_balance >= 0),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_user_wallets_balance
  ON matching.user_wallets(coin_balance DESC, updated_at DESC);

CREATE TABLE IF NOT EXISTS matching.match_gift_sends (
  id UUID PRIMARY KEY,
  match_id UUID NOT NULL REFERENCES matching.matches(id) ON DELETE CASCADE,
  sender_user_id UUID NOT NULL,
  receiver_user_id UUID NOT NULL,
  gift_id TEXT NOT NULL REFERENCES matching.gift_catalog(id),
  gift_name TEXT NOT NULL,
  gif_url TEXT NOT NULL,
  price_coins INTEGER NOT NULL DEFAULT 0 CHECK (price_coins >= 0),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_match_gift_sends_match_created
  ON matching.match_gift_sends(match_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_match_gift_sends_sender_created
  ON matching.match_gift_sends(sender_user_id, created_at DESC);
