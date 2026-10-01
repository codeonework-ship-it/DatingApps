-- ─────────────────────────────────────────────────────────────────────────────
-- 085: Register money and trust aggregates in the ownership registry (PEN-24)
--
-- 078 registered identity, photos, matches, messages, notifications, XP and
-- SOS. Billing, wallet and gift state — the aggregates where a lost or
-- duplicated write costs money — were missing. The health view now also
-- reports required aggregates that are not registered, and the BFF's /readyz
-- reads it.
-- Safe to run repeatedly.
-- ─────────────────────────────────────────────────────────────────────────────

INSERT INTO platform.aggregate_ownership(
  aggregate_type, owner_component, source_schema, source_table, transaction_boundary, recovery_strategy
) VALUES
  ('billing.subscription', 'billing', 'matching', 'billing_subscriptions_runtime',
   'webhook ledger transaction', 'provider event replay with webhook dedupe'),
  ('billing.payment', 'billing', 'matching', 'billing_payments_runtime',
   'webhook ledger transaction', 'provider event replay and reconciliation'),
  ('billing.webhook_event', 'billing', 'matching', 'billing_webhook_events',
   'insert-once ledger', 'failed-event retry'),
  ('billing.checkout', 'billing', 'matching', 'billing_checkout_sessions',
   'single PostgreSQL transaction', 'idempotency key replay and expiry sweep'),
  ('wallet.balance', 'wallet', 'matching', 'user_wallets',
   'row lock inside gift, credit and reversal transactions', 'ledger reconciliation (credits - spends - debits)'),
  ('wallet.credit', 'wallet', 'matching', 'wallet_coin_purchases',
   'same transaction as the balance change', 'idempotency key replay'),
  ('wallet.debit', 'wallet', 'matching', 'wallet_coin_debits',
   'same transaction as the balance change', 'recomputed from payment refund state'),
  ('gifts.send', 'gifts', 'matching', 'match_gift_sends',
   'single transaction with debit and chat message', 'idempotency key replay under wallet lock'),
  ('trust.account_recovery', 'trust_safety', 'user_management', 'account_recovery_requests',
   'single PostgreSQL transaction', 'operator review queue'),
  ('trust.legal_hold', 'trust_safety', 'platform', 'legal_holds',
   'single PostgreSQL transaction', 'append with release columns')
ON CONFLICT (aggregate_type) DO UPDATE SET
  owner_component = EXCLUDED.owner_component,
  source_schema = EXCLUDED.source_schema,
  source_table = EXCLUDED.source_table,
  transaction_boundary = EXCLUDED.transaction_boundary,
  recovery_strategy = EXCLUDED.recovery_strategy,
  updated_at = NOW();

CREATE TABLE IF NOT EXISTS platform.required_aggregates (
  aggregate_type TEXT PRIMARY KEY
);

INSERT INTO platform.required_aggregates(aggregate_type) VALUES
  ('identity.user'), ('profile.photo'), ('matching.match'), ('messaging.message'),
  ('notifications.delivery'), ('progression.xp'), ('safety.sos'),
  ('billing.subscription'), ('billing.payment'), ('billing.webhook_event'), ('billing.checkout'),
  ('wallet.balance'), ('wallet.credit'), ('wallet.debit'), ('gifts.send')
ON CONFLICT DO NOTHING;

DROP VIEW IF EXISTS platform.aggregate_ownership_health;
CREATE VIEW platform.aggregate_ownership_health AS
SELECT
  (SELECT COUNT(*) FROM platform.aggregate_ownership) AS declared_aggregates,
  (SELECT COUNT(*) FROM platform.aggregate_ownership o
     LEFT JOIN pg_namespace n ON n.nspname = o.source_schema
     LEFT JOIN pg_class c ON c.relnamespace = n.oid AND c.relname = o.source_table AND c.relkind IN ('r','p')
    WHERE c.oid IS NULL) AS missing_relations,
  COALESCE((SELECT array_agg(o.aggregate_type ORDER BY o.aggregate_type)
     FROM platform.aggregate_ownership o
     LEFT JOIN pg_namespace n ON n.nspname = o.source_schema
     LEFT JOIN pg_class c ON c.relnamespace = n.oid AND c.relname = o.source_table AND c.relkind IN ('r','p')
    WHERE c.oid IS NULL), '{}'::TEXT[]) AS invalid_aggregates,
  COALESCE((SELECT array_agg(r.aggregate_type ORDER BY r.aggregate_type)
     FROM platform.required_aggregates r
     LEFT JOIN platform.aggregate_ownership o ON o.aggregate_type = r.aggregate_type
    WHERE o.aggregate_type IS NULL), '{}'::TEXT[]) AS unregistered_required;
