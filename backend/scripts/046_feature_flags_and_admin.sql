-- ============================================================
-- Migration 046: Platform Feature Flags + User Suspension Columns
-- Schemas: matching, user_management
-- ============================================================

-- ─── 1) Feature Flags ────────────────────────────────────────
CREATE TABLE IF NOT EXISTS matching.platform_feature_flags (
    key          TEXT        NOT NULL,
    value_bool   BOOLEAN     NOT NULL DEFAULT TRUE,
    description  TEXT,
    updated_by   TEXT        NOT NULL DEFAULT 'system',
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT platform_feature_flags_pkey PRIMARY KEY (key)
);

INSERT INTO matching.platform_feature_flags (key, value_bool, description) VALUES
  ('gifts_enabled',               TRUE,  'Show/hide gift tray in chat'),
  ('voice_icebreakers_enabled',   TRUE,  'Show/hide voice icebreaker CTA'),
  ('rooms_enabled',               TRUE,  'Show/hide conversation rooms tab'),
  ('calls_enabled',               TRUE,  'Show/hide video call button'),
  ('billing_enabled',             TRUE,  'Show/hide paywall and billing'),
  ('quest_workflow_v2_enabled',   TRUE,  'Use quest workflow v2'),
  ('circles_enabled',             TRUE,  'Enable community circles'),
  ('daily_prompts_enabled',       TRUE,  'Show daily engagement prompts'),
  ('group_coffee_polls_enabled',  TRUE,  'Show group coffee polls'),
  ('safety_sos_enabled',          TRUE,  'Enable SOS safety feature')
ON CONFLICT (key) DO NOTHING;

-- ─── 2) User Suspension Columns ──────────────────────────────
ALTER TABLE user_management.users
  ADD COLUMN IF NOT EXISTS suspended_at      TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS suspended_reason  TEXT,
  ADD COLUMN IF NOT EXISTS suspended_until   TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS is_banned         BOOLEAN NOT NULL DEFAULT FALSE;

-- ─── 3) Daily Prompts Admin Table ────────────────────────────
CREATE TABLE IF NOT EXISTS matching.admin_daily_prompts (
    id              UUID        NOT NULL DEFAULT gen_random_uuid(),
    question_text   TEXT        NOT NULL,
    category        TEXT        NOT NULL DEFAULT 'general',
    active_date     DATE,
    is_active       BOOLEAN     NOT NULL DEFAULT FALSE,
    response_count  INT         NOT NULL DEFAULT 0,
    created_by      TEXT        NOT NULL DEFAULT 'admin',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT admin_daily_prompts_pkey PRIMARY KEY (id)
);

-- Seed sample prompts
INSERT INTO matching.admin_daily_prompts (question_text, category, is_active, active_date) VALUES
  ('What is one thing you are grateful for today?', 'reflection', TRUE, CURRENT_DATE),
  ('Describe your perfect Sunday morning.', 'lifestyle', FALSE, NULL),
  ('What is the best travel experience you have had?', 'fun', FALSE, NULL),
  ('What quality do you value most in a partner?', 'deep', FALSE, NULL),
  ('What are you currently binge-watching or reading?', 'icebreaker', FALSE, NULL)
ON CONFLICT DO NOTHING;

-- ─── 4) Admin Coin Packages Table ────────────────────────────
CREATE TABLE IF NOT EXISTS matching.coin_packages (
    id              UUID        NOT NULL DEFAULT gen_random_uuid(),
    label           TEXT        NOT NULL,
    coin_amount     INT         NOT NULL,
    price_usd       NUMERIC(6,2) NOT NULL,
    is_active       BOOLEAN     NOT NULL DEFAULT TRUE,
    sort_order      INT         NOT NULL DEFAULT 0,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT coin_packages_pkey PRIMARY KEY (id)
);

INSERT INTO matching.coin_packages (label, coin_amount, price_usd, is_active, sort_order) VALUES
  ('Starter Pack',   100,  0.99, TRUE, 1),
  ('Popular',        500,  3.99, TRUE, 2),
  ('Best Value',    1200,  7.99, TRUE, 3),
  ('Premium',       3000, 17.99, TRUE, 4),
  ('Super Bundle',  7500, 39.99, TRUE, 5)
ON CONFLICT DO NOTHING;
