-- ─────────────────────────────────────────────────────────────────────────────
-- 090: Remove implicit starter coins and repair historical credit provenance
--
-- New wallets start empty. Every positive balance must be explained by an
-- explicit purchase, operator grant, promotion, refund or historical opening
-- balance entry. Existing unexplained positive balances are preserved and
-- attributed once; negative discrepancies remain visible for operator review.
-- Safe to run repeatedly.
-- ─────────────────────────────────────────────────────────────────────────────

BEGIN;

ALTER TABLE matching.user_wallets
  ALTER COLUMN coin_balance SET DEFAULT 0;

ALTER TABLE matching.wallet_coin_debits
  DROP CONSTRAINT IF EXISTS wallet_coin_debits_source_check;
ALTER TABLE matching.wallet_coin_debits
  ADD CONSTRAINT wallet_coin_debits_source_check CHECK (
    source IN ('purchase_refund','purchase_chargeback','debt_collection','opening_balance_adjustment')
  );

WITH ledger AS (
  SELECT w.user_id, w.coin_balance,
         COALESCE((SELECT SUM(p.coins)
                   FROM matching.wallet_coin_purchases p
                   WHERE p.user_id=w.user_id),0)
       - COALESCE((SELECT SUM(s.total_cost_coins)
                   FROM matching.match_gift_sends s
                   WHERE s.sender_user_id=w.user_id),0)
       - COALESCE((SELECT SUM(d.coins_debited)
                   FROM matching.wallet_coin_debits d
                   WHERE d.user_id=w.user_id),0) AS explained_balance
  FROM matching.user_wallets w
), missing_credit AS (
  SELECT user_id, coin_balance, coin_balance-explained_balance AS missing_coins
  FROM ledger
  WHERE coin_balance > explained_balance
)
INSERT INTO matching.wallet_coin_purchases
  (id,user_id,package_id,source,provider,idempotency_key,coins,amount_minor,
   currency,wallet_balance_after,metadata,created_at)
SELECT gen_random_uuid(),user_id,'opening_balance','opening_balance','internal',
       'opening_balance_repair:090:'||user_id::text,missing_coins,0,'coins',
       coin_balance,
       jsonb_build_object(
         'backfilled_by','090_zero_default_wallets_and_ledger_repair',
         'reason','historical_positive_balance_without_credit_provenance'
       ),NOW()
FROM missing_credit
ON CONFLICT (user_id,idempotency_key)
  WHERE idempotency_key IS NOT NULL AND BTRIM(idempotency_key)<>''
DO NOTHING;

-- Preserve a historical balance that is lower than its known credits too.
-- This is provenance repair, not a new debit: the wallet value is unchanged.
WITH ledger AS (
  SELECT w.user_id, w.coin_balance,
         COALESCE((SELECT SUM(p.coins)
                   FROM matching.wallet_coin_purchases p
                   WHERE p.user_id=w.user_id),0)
       - COALESCE((SELECT SUM(s.total_cost_coins)
                   FROM matching.match_gift_sends s
                   WHERE s.sender_user_id=w.user_id),0)
       - COALESCE((SELECT SUM(d.coins_debited)
                   FROM matching.wallet_coin_debits d
                   WHERE d.user_id=w.user_id),0) AS explained_balance
  FROM matching.user_wallets w
), missing_debit AS (
  SELECT user_id,coin_balance,explained_balance-coin_balance AS missing_coins
  FROM ledger
  WHERE coin_balance < explained_balance
)
INSERT INTO matching.wallet_coin_debits
  (id,user_id,source,coins_requested,coins_debited,coins_shortfall,
   wallet_balance_after,provider,provider_event_id,note,created_at)
SELECT gen_random_uuid(),user_id,'opening_balance_adjustment',missing_coins,
       missing_coins,0,coin_balance,'internal',
       'opening-balance-repair:090:'||user_id::text,
       'Historical balance below known credits; provenance repaired by migration 090.',NOW()
FROM missing_debit
ON CONFLICT (provider,provider_event_id)
  WHERE provider_event_id IS NOT NULL
DO NOTHING;

INSERT INTO public.schema_migrations(version)
VALUES ('090_zero_default_wallets_and_ledger_repair')
ON CONFLICT (version) DO UPDATE SET applied_at=EXCLUDED.applied_at;

COMMIT;
