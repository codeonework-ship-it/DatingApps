-- Business development / commercial reports (2026-10-01).
--
-- Adds what the money and market-launch reports under /v1/admin/business/...
-- need that the product tables do not already hold:
--
--   * the `finance` operator role: reads billing and business reports and
--     records marketing spend; it cannot moderate, grant coins or change
--     product configuration (see documents/BUSINESS_REPORTS_2026-10-01.md);
--   * business.marketing_spend: operator-entered spend per month, channel,
--     market and currency so CAC and payback can be computed. Amounts are
--     stored in minor units of the stated currency and are never summed
--     across currencies;
--   * business.launch_markets: the city launch gates from the pricing and
--     go-to-market strategy (section 5.1). Targets are assumptions the owner
--     replaces with decisions; aliases map free-text member cities onto a
--     market (for example "bangalore" onto "bengaluru");
--   * reporting indexes so windowed aggregates do not scan whole tables.
--
-- Reports only read product tables. Nothing here changes billing behaviour.
BEGIN;

-- ── finance operator role ────────────────────────────────────────────────────
ALTER TABLE user_management.auth_account_roles
  DROP CONSTRAINT IF EXISTS auth_account_roles_role_check;
ALTER TABLE user_management.auth_account_roles
  ADD CONSTRAINT auth_account_roles_role_check
  CHECK (role IN ('user','moderator','admin','ops_admin','trust_safety','analyst','finance'));

CREATE OR REPLACE VIEW audit.operator_action_log AS
SELECT id, occurred_at, txid, event_type, actor_user_id, actor_role,
       subject_user_id, resource_type, resource_id, correlation_id, payload
FROM audit.security_events
WHERE actor_role IN ('admin','ops_admin','trust_safety','moderator','analyst','finance')
ORDER BY occurred_at DESC, id DESC;

CREATE SCHEMA IF NOT EXISTS business;

-- ── marketing spend ─────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS business.marketing_spend (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  month DATE NOT NULL CHECK (EXTRACT(DAY FROM month) = 1),
  channel TEXT NOT NULL CHECK (channel IN (
    'paid_social','search','influencer','events','referral_rewards',
    'partnerships','pr','content','app_store','other')),
  -- 'all' or a business.launch_markets.city_key.
  market TEXT NOT NULL DEFAULT 'all' CHECK (market ~ '^[a-z0-9][a-z0-9_-]{0,63}$'),
  currency TEXT NOT NULL CHECK (currency ~ '^[A-Z]{3}$'),
  amount_minor BIGINT NOT NULL CHECK (amount_minor >= 0 AND amount_minor <= 100000000000),
  -- Optional: members the channel itself attributes to this spend. CAC uses
  -- all new members unless the owner chooses attributed CAC.
  attributed_members INTEGER CHECK (attributed_members IS NULL OR attributed_members >= 0),
  note TEXT CHECK (note IS NULL OR char_length(note) <= 500),
  created_by UUID,
  updated_by UUID,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (month, channel, market, currency)
);
CREATE INDEX IF NOT EXISTS idx_marketing_spend_month ON business.marketing_spend(month, market);

-- ── launch markets and gates ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS business.launch_markets (
  city_key TEXT PRIMARY KEY CHECK (city_key ~ '^[a-z0-9][a-z0-9_-]{0,63}$'),
  display_name TEXT NOT NULL CHECK (char_length(display_name) BETWEEN 2 AND 100),
  country TEXT NOT NULL CHECK (char_length(country) BETWEEN 2 AND 100),
  currency TEXT NOT NULL CHECK (currency ~ '^[A-Z]{3}$'),
  aliases TEXT[] NOT NULL DEFAULT '{}' CHECK (cardinality(aliases) <= 20),
  verified_target INTEGER NOT NULL DEFAULT 3000 CHECK (verified_target BETWEEN 1 AND 10000000),
  max_gender_share NUMERIC(4,3) NOT NULL DEFAULT 0.600 CHECK (max_gender_share > 0.5 AND max_gender_share <= 1),
  plans_kept_target NUMERIC(6,4) NOT NULL DEFAULT 0.0800 CHECK (plans_kept_target >= 0 AND plans_kept_target <= 10),
  approaching_share NUMERIC(4,3) NOT NULL DEFAULT 0.500 CHECK (approaching_share > 0 AND approaching_share < 1),
  launch_order INTEGER CHECK (launch_order IS NULL OR launch_order BETWEEN 1 AND 1000),
  active BOOLEAN NOT NULL DEFAULT TRUE,
  notes TEXT CHECK (notes IS NULL OR char_length(notes) <= 500),
  updated_by UUID,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Launch order from PRICING_AND_GO_TO_MARKET_STRATEGY_2026-09-27.md 5.1. The
-- second Indian metro is undecided and therefore not seeded.
INSERT INTO business.launch_markets(city_key, display_name, country, currency, aliases, launch_order, notes) VALUES
  ('bengaluru','Bengaluru','India','INR','{bangalore,"bengaluru urban"}',1,'Densest test cohort'),
  ('london','London','United Kingdom','GBP','{}',3,NULL),
  ('dublin','Dublin','Ireland','EUR','{}',4,NULL),
  ('berlin','Berlin','Germany','EUR','{}',5,NULL),
  ('vienna','Vienna','Austria','EUR','{wien}',6,NULL),
  ('zurich','Zurich','Switzerland','CHF','{zürich,zuerich}',7,'CHF prices not yet set in the pricing strategy'),
  ('paris','Paris','France','EUR','{}',8,NULL),
  ('amsterdam','Amsterdam','Netherlands','EUR','{}',9,NULL),
  ('warsaw','Warsaw','Poland','PLN','{warszawa}',10,NULL),
  ('madrid','Madrid','Spain','EUR','{}',11,NULL),
  ('milan','Milan','Italy','EUR','{milano}',12,NULL),
  ('lisbon','Lisbon','Portugal','EUR','{lisboa}',13,NULL)
ON CONFLICT (city_key) DO NOTHING;

DROP TRIGGER IF EXISTS trg_audit_row_change ON business.marketing_spend;
CREATE TRIGGER trg_audit_row_change AFTER INSERT OR DELETE OR UPDATE ON business.marketing_spend
  FOR EACH ROW EXECUTE FUNCTION audit.capture_row_change();
DROP TRIGGER IF EXISTS trg_audit_row_change ON business.launch_markets;
CREATE TRIGGER trg_audit_row_change AFTER INSERT OR DELETE OR UPDATE ON business.launch_markets
  FOR EACH ROW EXECUTE FUNCTION audit.capture_row_change();

-- ── reporting indexes ───────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_billing_payments_created
  ON matching.billing_payments_runtime(created_at);
CREATE INDEX IF NOT EXISTS idx_billing_payments_period
  ON matching.billing_payments_runtime(subscription_id, period_start, period_end)
  WHERE subscription_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_billing_payments_checkout
  ON matching.billing_payments_runtime(checkout_id) WHERE checkout_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_billing_checkout_sessions_created
  ON matching.billing_checkout_sessions(created_at);
CREATE INDEX IF NOT EXISTS idx_wallet_coin_purchases_created
  ON matching.wallet_coin_purchases(created_at, source);
CREATE INDEX IF NOT EXISTS idx_match_gift_sends_created
  ON matching.match_gift_sends(created_at);
CREATE INDEX IF NOT EXISTS idx_users_created_at
  ON user_management.users(created_at);
CREATE INDEX IF NOT EXISTS idx_referral_redemptions_created
  ON growth.referral_redemptions(created_at);

INSERT INTO public.schema_migrations(version)
VALUES ('124_business_reports')
ON CONFLICT (version) DO UPDATE SET applied_at=EXCLUDED.applied_at;

COMMIT;
