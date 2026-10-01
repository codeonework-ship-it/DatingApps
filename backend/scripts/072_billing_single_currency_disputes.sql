-- 072_billing_single_currency_disputes.sql
--
-- One currency contract, disputes, plan changes and card replacement.
--
-- Currency: every price the member can be charged is in PAYMENTS_CURRENCY
-- (INR). Plans were already INR; coin packages carried a USD column and a
-- USD default, so a member saw ₹ for plans and $ for coins. Coin packages
-- are repriced here in INR. The amounts are placeholders derived from the
-- old USD list (≈ ×83, rounded to a marketing price); product owns the
-- final list (DEC-007 / BILL-003). Startup refuses catalog rows whose
-- currency differs from PAYMENTS_CURRENCY.
BEGIN;

ALTER TABLE matching.coin_packages
  ADD COLUMN IF NOT EXISTS price NUMERIC(10,2);
UPDATE matching.coin_packages
SET price = CASE
      WHEN currency = 'USD' THEN
        CASE coin_amount
          WHEN 100  THEN 79
          WHEN 500  THEN 329
          WHEN 1200 THEN 649
          WHEN 3000 THEN 1499
          WHEN 7500 THEN 3299
          ELSE ROUND(price_usd * 83)
        END
      ELSE price_usd
    END,
    currency = 'INR'
WHERE price IS NULL;
ALTER TABLE matching.coin_packages ALTER COLUMN price SET NOT NULL;
ALTER TABLE matching.coin_packages ALTER COLUMN price SET DEFAULT 0;
ALTER TABLE matching.coin_packages ALTER COLUMN currency SET DEFAULT 'INR';

-- Checkout kinds: card replacement.
ALTER TABLE matching.billing_checkout_sessions
  DROP CONSTRAINT IF EXISTS billing_checkout_sessions_kind_check;
ALTER TABLE matching.billing_checkout_sessions
  ADD CONSTRAINT billing_checkout_sessions_kind_check CHECK (kind IN ('subscription','coin_package','card_update'));
ALTER TABLE matching.billing_checkout_sessions
  ADD COLUMN IF NOT EXISTS subscription_ref TEXT;

-- Payment statuses: disputes.
ALTER TABLE matching.billing_payments_runtime
  DROP CONSTRAINT IF EXISTS billing_payments_runtime_status_check;
ALTER TABLE matching.billing_payments_runtime
  ADD CONSTRAINT billing_payments_runtime_status_check
  CHECK (status IN ('created','pending','success','failed','refunded','partially_refunded','disputed','chargeback'));
ALTER TABLE matching.billing_payments_runtime
  ADD COLUMN IF NOT EXISTS dispute_id TEXT,
  ADD COLUMN IF NOT EXISTS dispute_status TEXT,
  ADD COLUMN IF NOT EXISTS dispute_reason TEXT,
  ADD COLUMN IF NOT EXISTS disputed_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS dispute_closed_at TIMESTAMPTZ;
CREATE INDEX IF NOT EXISTS idx_billing_payments_dispute
  ON matching.billing_payments_runtime (dispute_id) WHERE dispute_id IS NOT NULL;

-- Plan history on the subscription for reconciliation of plan changes.
ALTER TABLE matching.billing_subscriptions_runtime
  ADD COLUMN IF NOT EXISTS previous_plan_code TEXT,
  ADD COLUMN IF NOT EXISTS plan_changed_at TIMESTAMPTZ;

COMMIT;
