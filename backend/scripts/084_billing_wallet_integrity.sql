-- ─────────────────────────────────────────────────────────────────────────────
-- 084: Billing and wallet integrity (PEN-02 / PEN-13 / BILL-004)
--
--   • Coin refunds and chargebacks take the coins back. What the balance cannot
--     cover is recorded as debt and the wallet is frozen (no spending) until an
--     operator reviews it. Balances never go negative.
--   • matching.wallet_coin_debits is the debit side of the coin ledger.
--   • The credit ledger gains 'bootstrap' (the starting balance a wallet is
--     created with), 'gift_refund' (operator gift reversal) and
--     'opening_balance' (backfill so existing balances reconcile).
--   • Gift sends record who reversed them and why.
-- Safe to run repeatedly.
-- ─────────────────────────────────────────────────────────────────────────────

ALTER TABLE matching.user_wallets
  ADD COLUMN IF NOT EXISTS frozen_at     TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS frozen_reason TEXT,
  ADD COLUMN IF NOT EXISTS debt_coins    INTEGER NOT NULL DEFAULT 0;

ALTER TABLE matching.user_wallets DROP CONSTRAINT IF EXISTS user_wallets_debt_coins_check;
ALTER TABLE matching.user_wallets
  ADD CONSTRAINT user_wallets_debt_coins_check CHECK (debt_coins >= 0);
-- Debt always comes with a freeze; an operator clears both together.
ALTER TABLE matching.user_wallets DROP CONSTRAINT IF EXISTS user_wallets_debt_requires_freeze;
ALTER TABLE matching.user_wallets
  ADD CONSTRAINT user_wallets_debt_requires_freeze CHECK (debt_coins = 0 OR frozen_at IS NOT NULL);

ALTER TABLE matching.wallet_coin_purchases DROP CONSTRAINT IF EXISTS wallet_coin_purchases_source_check;
ALTER TABLE matching.wallet_coin_purchases
  ADD CONSTRAINT wallet_coin_purchases_source_check
  CHECK (source IN ('buy','admin_topup','promo','bootstrap','gift_refund','opening_balance'));

CREATE TABLE IF NOT EXISTS matching.wallet_coin_debits (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id           UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  source            TEXT NOT NULL CHECK (source IN ('purchase_refund','purchase_chargeback','debt_collection')),
  payment_id        UUID REFERENCES matching.billing_payments_runtime(id) ON DELETE SET NULL,
  checkout_id       UUID,
  coins_requested   INTEGER NOT NULL CHECK (coins_requested > 0),
  coins_debited     INTEGER NOT NULL CHECK (coins_debited >= 0),
  coins_shortfall   INTEGER NOT NULL CHECK (coins_shortfall >= 0),
  wallet_balance_after INTEGER NOT NULL CHECK (wallet_balance_after >= 0),
  provider          TEXT,
  provider_event_id TEXT,
  actor_user_id     UUID,
  note              TEXT,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (coins_debited + coins_shortfall = coins_requested)
);

CREATE INDEX IF NOT EXISTS idx_wallet_coin_debits_payment
  ON matching.wallet_coin_debits(payment_id) WHERE payment_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_wallet_coin_debits_user
  ON matching.wallet_coin_debits(user_id, created_at DESC);
CREATE UNIQUE INDEX IF NOT EXISTS idx_wallet_coin_debits_event
  ON matching.wallet_coin_debits(provider, provider_event_id)
  WHERE provider_event_id IS NOT NULL;

-- Migration 075 registered every table that existed at that boundary. The
-- debit ledger is newer, so register it explicitly with the transactional
-- outbox used by the rest of the product.
SELECT platform.register_event_source('matching', 'wallet_coin_debits', 'wallet.debit');

ALTER TABLE matching.match_gift_sends
  ADD COLUMN IF NOT EXISTS refunded_at   TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS refunded_by   UUID,
  ADD COLUMN IF NOT EXISTS refund_reason TEXT;

ALTER TABLE matching.match_gift_sends DROP CONSTRAINT IF EXISTS match_gift_sends_refund_audit;
ALTER TABLE matching.match_gift_sends
  ADD CONSTRAINT match_gift_sends_refund_audit
  CHECK (status <> 'refunded' OR (refunded_at IS NOT NULL AND refunded_by IS NOT NULL
                                  AND char_length(BTRIM(COALESCE(refund_reason,''))) >= 3));

-- Opening balances: record, once, whatever part of each existing balance the
-- ledger cannot explain, so reconciliation starts from a known position. Rows
-- are marked as backfilled; a negative difference cannot be expressed here
-- and stays visible as a reconciliation anomaly.
WITH explained AS (
  SELECT w.user_id, w.coin_balance,
         COALESCE((SELECT SUM(p.coins) FROM matching.wallet_coin_purchases p WHERE p.user_id = w.user_id), 0)
       - COALESCE((SELECT SUM(s.total_cost_coins) FROM matching.match_gift_sends s WHERE s.sender_user_id = w.user_id), 0)
       - COALESCE((SELECT SUM(d.coins_debited) FROM matching.wallet_coin_debits d WHERE d.user_id = w.user_id), 0)
         AS ledger_balance
  FROM matching.user_wallets w
  WHERE NOT EXISTS (
    SELECT 1 FROM matching.wallet_coin_purchases p
    WHERE p.user_id = w.user_id AND p.source IN ('bootstrap','opening_balance')
  )
)
INSERT INTO matching.wallet_coin_purchases
  (id, user_id, package_id, source, provider, idempotency_key, coins, amount_minor, currency,
   wallet_balance_after, metadata)
SELECT gen_random_uuid(), user_id, 'opening_balance', 'opening_balance', 'internal', 'opening_balance:' || user_id::text,
       coin_balance - ledger_balance, 0, 'coins', coin_balance,
       jsonb_build_object('backfilled_by', '084_billing_wallet_integrity')
FROM explained
WHERE coin_balance - ledger_balance > 0;
