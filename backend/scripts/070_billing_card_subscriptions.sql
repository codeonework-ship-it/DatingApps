-- 070_billing_card_subscriptions.sql
--
-- Card checkout and auto-renewing subscriptions (PEN-01 / BILL-004).
--
-- Before this migration a subscription became "active" with a "success"
-- payment the moment the client asked for it; no money moved and nothing
-- could ever move it out of that state. This migration gives the billing
-- tables what a provider-driven lifecycle needs:
--
--   * a provider customer mapping so one member maps to one provider customer;
--   * checkout sessions, so the request to pay and the settled outcome are
--     separate records joined by the provider's session id;
--   * a webhook event ledger with a (provider, event_id) unique key, which is
--     the deduplication primitive for retried and re-ordered deliveries;
--   * richer subscription/payment state (past_due, cancel_at_period_end,
--     current period, card summary, refund amounts) and unique provider ids.
--
-- Additive: nothing is dropped and the existing local rows remain readable.
BEGIN;

-- ── Plans: code, currency and optional pre-created provider prices ─────────
ALTER TABLE matching.billing_plans
  ADD COLUMN IF NOT EXISTS code TEXT,
  ADD COLUMN IF NOT EXISTS currency TEXT NOT NULL DEFAULT 'INR',
  ADD COLUMN IF NOT EXISTS provider_price_ids JSONB NOT NULL DEFAULT '{}'::jsonb;

UPDATE matching.billing_plans SET code = LOWER(TRIM(name)) WHERE code IS NULL OR code = '';
ALTER TABLE matching.billing_plans ALTER COLUMN code SET NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS uq_billing_plans_code ON matching.billing_plans (code);

-- ── Subscriptions ───────────────────────────────────────────────────────────
ALTER TABLE matching.billing_subscriptions_runtime
  ADD COLUMN IF NOT EXISTS provider TEXT NOT NULL DEFAULT 'local',
  ADD COLUMN IF NOT EXISTS provider_customer_id TEXT,
  ADD COLUMN IF NOT EXISTS cancel_at_period_end BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS cancelled_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS current_period_start TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS current_period_end TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS amount_minor BIGINT,
  ADD COLUMN IF NOT EXISTS currency TEXT NOT NULL DEFAULT 'INR',
  ADD COLUMN IF NOT EXISTS payment_method_brand TEXT,
  ADD COLUMN IF NOT EXISTS payment_method_last4 TEXT,
  ADD COLUMN IF NOT EXISTS last_provider_event_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS metadata JSONB NOT NULL DEFAULT '{}'::jsonb;

ALTER TABLE matching.billing_subscriptions_runtime
  DROP CONSTRAINT IF EXISTS billing_subscriptions_runtime_status_check;
ALTER TABLE matching.billing_subscriptions_runtime
  ADD CONSTRAINT billing_subscriptions_runtime_status_check
  CHECK (status IN ('incomplete','active','past_due','cancelled','expired','paused'));

-- Existing local rows: derive the period from the dates they already carry.
UPDATE matching.billing_subscriptions_runtime
SET current_period_start = COALESCE(current_period_start, start_date),
    current_period_end   = COALESCE(current_period_end, next_billing_date)
WHERE current_period_start IS NULL OR current_period_end IS NULL;

-- One live subscription per member. Older duplicates (possible from seed
-- data) are superseded rather than deleted so history is kept.
WITH ranked AS (
  SELECT id, ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY updated_at DESC, created_at DESC) AS rn
  FROM matching.billing_subscriptions_runtime
  WHERE status IN ('incomplete','active','past_due')
)
UPDATE matching.billing_subscriptions_runtime s
SET status = 'cancelled', end_date = COALESCE(s.end_date, NOW()), updated_at = NOW()
FROM ranked r
WHERE s.id = r.id AND r.rn > 1;

CREATE UNIQUE INDEX IF NOT EXISTS uq_billing_subscriptions_one_live
  ON matching.billing_subscriptions_runtime (user_id)
  WHERE status IN ('incomplete','active','past_due');

CREATE UNIQUE INDEX IF NOT EXISTS uq_billing_subscriptions_provider_ref
  ON matching.billing_subscriptions_runtime (provider, provider_subscription_id)
  WHERE provider_subscription_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_billing_subscriptions_period_end
  ON matching.billing_subscriptions_runtime (current_period_end)
  WHERE status IN ('active','past_due');

-- ── Payments ────────────────────────────────────────────────────────────────
ALTER TABLE matching.billing_payments_runtime
  ADD COLUMN IF NOT EXISTS provider TEXT NOT NULL DEFAULT 'local',
  ADD COLUMN IF NOT EXISTS provider_invoice_id TEXT,
  ADD COLUMN IF NOT EXISTS provider_charge_id TEXT,
  ADD COLUMN IF NOT EXISTS provider_event_id TEXT,
  ADD COLUMN IF NOT EXISTS billing_reason TEXT,
  ADD COLUMN IF NOT EXISTS period_start TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS period_end TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS refunded_amount_paise BIGINT NOT NULL DEFAULT 0 CHECK (refunded_amount_paise >= 0),
  ADD COLUMN IF NOT EXISTS payment_method_brand TEXT,
  ADD COLUMN IF NOT EXISTS payment_method_last4 TEXT,
  ADD COLUMN IF NOT EXISTS failure_reason TEXT,
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

ALTER TABLE matching.billing_payments_runtime
  DROP CONSTRAINT IF EXISTS billing_payments_runtime_status_check;
ALTER TABLE matching.billing_payments_runtime
  ADD CONSTRAINT billing_payments_runtime_status_check
  CHECK (status IN ('created','pending','success','failed','refunded','partially_refunded'));

CREATE UNIQUE INDEX IF NOT EXISTS uq_billing_payments_provider_invoice
  ON matching.billing_payments_runtime (provider, provider_invoice_id)
  WHERE provider_invoice_id IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS uq_billing_payments_provider_payment
  ON matching.billing_payments_runtime (provider, provider_payment_id)
  WHERE provider_payment_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_billing_payments_subscription
  ON matching.billing_payments_runtime (subscription_id, created_at DESC);

-- ── Provider customers ──────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS matching.billing_provider_customers (
  user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  provider TEXT NOT NULL,
  provider_customer_id TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (user_id, provider),
  CONSTRAINT uq_billing_provider_customers_ref UNIQUE (provider, provider_customer_id)
);

-- ── Checkout sessions ───────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS matching.billing_checkout_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  plan_code TEXT NOT NULL,
  billing_cycle TEXT NOT NULL CHECK (billing_cycle IN ('monthly','yearly')),
  provider TEXT NOT NULL,
  provider_session_id TEXT,
  idempotency_key TEXT,
  status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open','completed','expired','abandoned')),
  amount_minor BIGINT NOT NULL CHECK (amount_minor >= 0),
  currency TEXT NOT NULL,
  checkout_url TEXT,
  subscription_id UUID REFERENCES matching.billing_subscriptions_runtime(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb
);
CREATE UNIQUE INDEX IF NOT EXISTS uq_billing_checkout_provider_session
  ON matching.billing_checkout_sessions (provider, provider_session_id)
  WHERE provider_session_id IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS uq_billing_checkout_idempotency
  ON matching.billing_checkout_sessions (user_id, idempotency_key)
  WHERE idempotency_key IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_billing_checkout_user
  ON matching.billing_checkout_sessions (user_id, created_at DESC);

-- ── Webhook event ledger (deduplication + audit) ────────────────────────────
CREATE TABLE IF NOT EXISTS matching.billing_webhook_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  provider TEXT NOT NULL,
  event_id TEXT NOT NULL,
  event_type TEXT NOT NULL,
  event_created_at TIMESTAMPTZ,
  received_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  processed_at TIMESTAMPTZ,
  status TEXT NOT NULL DEFAULT 'received' CHECK (status IN ('received','processed','ignored','failed')),
  error TEXT,
  payload JSONB NOT NULL,
  CONSTRAINT uq_billing_webhook_events_ref UNIQUE (provider, event_id)
);
CREATE INDEX IF NOT EXISTS idx_billing_webhook_events_received
  ON matching.billing_webhook_events (received_at DESC);

COMMIT;
