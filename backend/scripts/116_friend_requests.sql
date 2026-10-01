-- Friends: request source, decline cooldown and a daily request ledger.
--
-- A friend request is one pending row requester -> recipient in
-- matching.friend_connections; an accepted friendship is two accepted rows.
-- This migration records where a request started (search, match, profile,
-- room, group), remembers declines so the same requester waits 7 days before
-- asking again, and keeps a small ledger of sent requests so a member can send
-- at most 30 a day (sending and cancelling does not reset the count).
BEGIN;

ALTER TABLE matching.friend_connections ADD COLUMN IF NOT EXISTS source TEXT;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'friend_connections_source_check'
      AND conrelid = 'matching.friend_connections'::regclass
  ) THEN
    ALTER TABLE matching.friend_connections ADD CONSTRAINT friend_connections_source_check
      CHECK (source IS NULL OR source IN ('search','match','profile','room','group'));
  END IF;
END $$;

-- Repair pairs where an older build overwrote one side of an accepted
-- friendship with 'pending' when a request was sent again.
UPDATE matching.friend_connections f SET status='accepted', updated_at=NOW()
WHERE f.status='pending'
  AND EXISTS (SELECT 1 FROM matching.friend_connections r
              WHERE r.user_id=f.friend_user_id AND r.friend_user_id=f.user_id AND r.status='accepted');

-- The last decline of requester's request by recipient. Cleared when the two
-- become friends.
CREATE TABLE IF NOT EXISTS matching.friend_request_declines (
 requester_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
 recipient_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
 declined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
 PRIMARY KEY (requester_id, recipient_id),
 CHECK (requester_id <> recipient_id)
);

-- One row per request sent; read for the rolling 24-hour limit.
CREATE TABLE IF NOT EXISTS matching.friend_request_sends (
 id BIGSERIAL PRIMARY KEY,
 requester_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
 recipient_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
 source TEXT,
 created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS friend_request_sends_requester ON matching.friend_request_sends(requester_id, created_at DESC);

-- Member search for "Add friend": username and name prefixes.
CREATE INDEX IF NOT EXISTS idx_users_username_prefix ON user_management.users (lower(username) text_pattern_ops);
CREATE INDEX IF NOT EXISTS idx_users_name_prefix ON user_management.users (lower(name) text_pattern_ops);

COMMIT;
