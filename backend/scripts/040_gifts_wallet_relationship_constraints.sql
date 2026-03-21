-- Enforce relational integrity for gift + wallet economy tables.
-- Uses NOT VALID constraints so existing legacy data does not block migration.

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'fk_user_wallets_user'
      AND conrelid = 'matching.user_wallets'::regclass
  ) THEN
    ALTER TABLE matching.user_wallets
      ADD CONSTRAINT fk_user_wallets_user
      FOREIGN KEY (user_id)
      REFERENCES user_management.users(id)
      ON DELETE CASCADE
      NOT VALID;
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'fk_match_gift_sends_sender_user'
      AND conrelid = 'matching.match_gift_sends'::regclass
  ) THEN
    ALTER TABLE matching.match_gift_sends
      ADD CONSTRAINT fk_match_gift_sends_sender_user
      FOREIGN KEY (sender_user_id)
      REFERENCES user_management.users(id)
      ON DELETE CASCADE
      NOT VALID;
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'fk_match_gift_sends_receiver_user'
      AND conrelid = 'matching.match_gift_sends'::regclass
  ) THEN
    ALTER TABLE matching.match_gift_sends
      ADD CONSTRAINT fk_match_gift_sends_receiver_user
      FOREIGN KEY (receiver_user_id)
      REFERENCES user_management.users(id)
      ON DELETE CASCADE
      NOT VALID;
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'fk_gift_spend_activities_sender_user'
      AND conrelid = 'matching.gift_spend_activities'::regclass
  ) THEN
    ALTER TABLE matching.gift_spend_activities
      ADD CONSTRAINT fk_gift_spend_activities_sender_user
      FOREIGN KEY (sender_user_id)
      REFERENCES user_management.users(id)
      ON DELETE CASCADE
      NOT VALID;
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'fk_gift_spend_activities_receiver_user'
      AND conrelid = 'matching.gift_spend_activities'::regclass
  ) THEN
    ALTER TABLE matching.gift_spend_activities
      ADD CONSTRAINT fk_gift_spend_activities_receiver_user
      FOREIGN KEY (receiver_user_id)
      REFERENCES user_management.users(id)
      ON DELETE CASCADE
      NOT VALID;
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'fk_gift_spend_activities_gift'
      AND conrelid = 'matching.gift_spend_activities'::regclass
  ) THEN
    ALTER TABLE matching.gift_spend_activities
      ADD CONSTRAINT fk_gift_spend_activities_gift
      FOREIGN KEY (gift_id)
      REFERENCES matching.gift_catalog(id)
      ON DELETE RESTRICT
      NOT VALID;
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'fk_wallet_coin_purchases_wallet'
      AND conrelid = 'matching.wallet_coin_purchases'::regclass
  ) THEN
    ALTER TABLE matching.wallet_coin_purchases
      ADD CONSTRAINT fk_wallet_coin_purchases_wallet
      FOREIGN KEY (user_id)
      REFERENCES matching.user_wallets(user_id)
      ON DELETE CASCADE
      NOT VALID;
  END IF;
END
$$;

CREATE INDEX IF NOT EXISTS idx_match_gift_sends_receiver_created
  ON matching.match_gift_sends(receiver_user_id, created_at DESC);
