-- ═══════════════════════════════════════════════════════════════════════════
-- Migration 047: Coin-package extras + billing_plans durable table
--                + gift_catalog missing columns
-- Applies: matching.coin_packages ADD bonus_percent, description
--          matching.billing_plans  CREATE (durable subscription plans)
--          matching.gift_catalog   ADD icon_emoji, description
-- ═══════════════════════════════════════════════════════════════════════════

-- ─── 1) Add bonus_percent and description to coin_packages ───────────────
ALTER TABLE matching.coin_packages
    ADD COLUMN IF NOT EXISTS bonus_percent NUMERIC(5,2) NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS description   TEXT         NOT NULL DEFAULT '';

-- ─── 1b) Add icon_emoji and description to gift_catalog ──────────────────
ALTER TABLE matching.gift_catalog
    ADD COLUMN IF NOT EXISTS icon_emoji  TEXT NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS description TEXT NOT NULL DEFAULT '';

-- ─── 2) Durable subscription plans table ─────────────────────────────────
-- Covers: Bronze → Diamond tiers with monthly/yearly pricing
-- Replaces in-memory subscriptionPlan struct for admin management
CREATE TABLE IF NOT EXISTS matching.billing_plans (
    id              UUID          NOT NULL DEFAULT gen_random_uuid(),
    name            TEXT          NOT NULL,
    monthly_price   NUMERIC(8,2) NOT NULL DEFAULT 0,
    yearly_price    NUMERIC(8,2) NOT NULL DEFAULT 0,
    likes_per_day   INT          NOT NULL DEFAULT 10,
    messages_per_day INT         NOT NULL DEFAULT 10,
    features        JSONB        NOT NULL DEFAULT '[]'::jsonb,
    is_active       BOOLEAN      NOT NULL DEFAULT TRUE,
    sort_order      INT          NOT NULL DEFAULT 0,
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    CONSTRAINT billing_plans_pkey PRIMARY KEY (id),
    CONSTRAINT billing_plans_name_uniq UNIQUE (name)
);

-- Seed default plans matching the in-memory tiers
INSERT INTO matching.billing_plans (name, monthly_price, yearly_price, likes_per_day, messages_per_day, features, is_active, sort_order) VALUES
  ('Free',     0,     0,     10, 5,  '["basic_matching"]'::jsonb,                                     TRUE, 1),
  ('Bronze',   4.99,  49.99, 25, 15, '["advanced_filters","read_receipts"]'::jsonb,                   TRUE, 2),
  ('Silver',   9.99,  99.99, 50, 30, '["advanced_filters","read_receipts","profile_boost"]'::jsonb,   TRUE, 3),
  ('Gold',    19.99, 199.99, -1, -1, '["advanced_filters","read_receipts","profile_boost","spotlight","unlimited_likes"]'::jsonb, TRUE, 4),
  ('Emerald', 29.99, 299.99, -1, -1, '["advanced_filters","read_receipts","profile_boost","spotlight","unlimited_likes","priority_support","incognito"]'::jsonb, TRUE, 5),
  ('Diamond', 49.99, 499.99, -1, -1, '["advanced_filters","read_receipts","profile_boost","spotlight","unlimited_likes","priority_support","incognito","super_swipes","travel_mode"]'::jsonb, TRUE, 6)
ON CONFLICT (name) DO NOTHING;

-- ─── 3) Index for admin list queries ────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_billing_plans_active_sort
    ON matching.billing_plans (is_active, sort_order);
