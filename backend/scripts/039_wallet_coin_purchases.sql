-- Durable wallet coin purchase ledger for coin-buy flows and controlled top-ups.

CREATE TABLE IF NOT EXISTS matching.wallet_coin_purchases (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL,
  package_id TEXT NOT NULL,
  source TEXT NOT NULL,
  provider TEXT NOT NULL DEFAULT 'internal',
  purchase_ref TEXT,
  idempotency_key TEXT,
  coins INTEGER NOT NULL CHECK (coins > 0),
  amount_minor INTEGER NOT NULL DEFAULT 0 CHECK (amount_minor >= 0),
  currency TEXT NOT NULL DEFAULT 'coins',
  wallet_balance_after INTEGER NOT NULL CHECK (wallet_balance_after >= 0),
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT wallet_coin_purchases_source_check CHECK (source IN ('buy', 'admin_topup', 'promo')),
  CONSTRAINT wallet_coin_purchases_provider_check CHECK (provider IN ('internal', 'stripe', 'razorpay', 'apple_iap', 'google_play', 'promo')),
  CONSTRAINT wallet_coin_purchases_currency_check CHECK (char_length(currency) > 0)
);

CREATE INDEX IF NOT EXISTS idx_wallet_coin_purchases_user_created
  ON matching.wallet_coin_purchases(user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_wallet_coin_purchases_source_created
  ON matching.wallet_coin_purchases(source, created_at DESC);

CREATE UNIQUE INDEX IF NOT EXISTS idx_wallet_coin_purchases_user_idem
  ON matching.wallet_coin_purchases(user_id, idempotency_key)
  WHERE idempotency_key IS NOT NULL AND btrim(idempotency_key) <> '';
