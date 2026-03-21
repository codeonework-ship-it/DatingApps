-- Durable gift-spend activity ledger for spend reporting and user-level audits.
-- Safe to run repeatedly on Supabase/Postgres.

CREATE TABLE IF NOT EXISTS matching.gift_spend_activities (
  id UUID PRIMARY KEY,
  match_id UUID NOT NULL REFERENCES matching.matches(id) ON DELETE CASCADE,
  sender_user_id UUID NOT NULL,
  receiver_user_id UUID NOT NULL,
  gift_id TEXT NOT NULL,
  action TEXT NOT NULL,
  status TEXT NOT NULL,
  price_coins INTEGER NOT NULL DEFAULT 0 CHECK (price_coins >= 0),
  wallet_balance_after INTEGER CHECK (wallet_balance_after >= 0),
  idempotency_key TEXT,
  error_code TEXT,
  error_message TEXT,
  details JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_gift_spend_activities_sender_created
  ON matching.gift_spend_activities(sender_user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_gift_spend_activities_match_created
  ON matching.gift_spend_activities(match_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_gift_spend_activities_action_status_created
  ON matching.gift_spend_activities(action, status, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_gift_spend_activities_gift_created
  ON matching.gift_spend_activities(gift_id, created_at DESC);