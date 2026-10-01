-- 071_billing_coin_checkout.sql
--
-- Coin packages bought through the same card checkout pipeline as
-- subscriptions (PEN-01 follow-up, BILL-001/BILL-004).
--
-- Before this, POST /wallet/{id}/coins/buy credited whatever coins and amount
-- the client sent. Coin purchases now go through a provider checkout in
-- payment mode; the wallet is credited only when the provider's signed
-- checkout.session.completed event arrives, idempotently on the checkout id.
BEGIN;

ALTER TABLE matching.billing_checkout_sessions
  ADD COLUMN IF NOT EXISTS kind TEXT NOT NULL DEFAULT 'subscription',
  ADD COLUMN IF NOT EXISTS package_id TEXT,
  ADD COLUMN IF NOT EXISTS coins INTEGER,
  ADD COLUMN IF NOT EXISTS provider_payment_id TEXT;
ALTER TABLE matching.billing_checkout_sessions
  DROP CONSTRAINT IF EXISTS billing_checkout_sessions_kind_check;
ALTER TABLE matching.billing_checkout_sessions
  ADD CONSTRAINT billing_checkout_sessions_kind_check CHECK (kind IN ('subscription','coin_package'));
-- plan_code is meaningless for a coin purchase; relax it.
ALTER TABLE matching.billing_checkout_sessions ALTER COLUMN plan_code DROP NOT NULL;
ALTER TABLE matching.billing_checkout_sessions ALTER COLUMN billing_cycle DROP NOT NULL;

-- Coin packages carry their own currency; price_usd keeps its historical
-- name but the currency column is what is charged.
ALTER TABLE matching.coin_packages
  ADD COLUMN IF NOT EXISTS currency TEXT NOT NULL DEFAULT 'USD';

-- The sandbox provider records wallet credits too.
ALTER TABLE matching.wallet_coin_purchases
  DROP CONSTRAINT IF EXISTS wallet_coin_purchases_provider_check;
ALTER TABLE matching.wallet_coin_purchases
  ADD CONSTRAINT wallet_coin_purchases_provider_check
  CHECK (provider IN ('internal','stripe','sandbox','razorpay','apple_iap','google_play','promo'));

-- A settled coin payment is a payment row without a subscription.
ALTER TABLE matching.billing_payments_runtime
  ADD COLUMN IF NOT EXISTS checkout_id UUID REFERENCES matching.billing_checkout_sessions(id) ON DELETE SET NULL;

COMMIT;
