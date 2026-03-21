-- Rose gifts model-alignment migration:
-- - add icon_key support to catalog/send tables
-- - add durable idempotency_key support for send replay protection
-- Safe to run repeatedly on Supabase/Postgres.

ALTER TABLE IF EXISTS matching.gift_catalog
  ADD COLUMN IF NOT EXISTS icon_key TEXT NOT NULL DEFAULT '';

UPDATE matching.gift_catalog
SET icon_key = CASE
  WHEN id ILIKE '%gold%' OR name ILIKE '%gold%' THEN 'rose_gold'
  WHEN id ILIKE '%crystal%' OR name ILIKE '%crystal%' THEN 'rose_crystal'
  WHEN id ILIKE '%black%' OR name ILIKE '%black%' THEN 'rose_black'
  WHEN id ILIKE '%blue%' OR name ILIKE '%blue%' THEN 'rose_blue'
  WHEN id ILIKE '%white%' OR name ILIKE '%white%' THEN 'rose_white'
  WHEN id ILIKE '%yellow%' OR name ILIKE '%yellow%' THEN 'rose_yellow'
  WHEN id ILIKE '%pink%' OR name ILIKE '%pink%' THEN 'rose_pink'
  WHEN id ILIKE '%lavender%' OR name ILIKE '%lavender%' THEN 'rose_lavender'
  WHEN id ILIKE '%sparkle%' OR name ILIKE '%sparkle%' THEN 'rose_sparkle'
  WHEN id ILIKE '%neon%' OR name ILIKE '%neon%' THEN 'rose_neon'
  WHEN id ILIKE '%heart%' OR name ILIKE '%heart%' THEN 'rose_heart'
  WHEN id ILIKE '%burning%' OR name ILIKE '%burning%' THEN 'rose_burning'
  WHEN id ILIKE '%bouquet%' OR name ILIKE '%bouquet%' THEN 'rose_bouquet'
  WHEN id ILIKE '%seasonal%' OR name ILIKE '%seasonal%' THEN 'rose_seasonal'
  WHEN id ILIKE '%rain%' OR name ILIKE '%rain%' THEN 'rose_rain'
  ELSE 'rose_red'
END,
updated_at = NOW()
WHERE icon_key IS NULL OR icon_key = '';

ALTER TABLE IF EXISTS matching.match_gift_sends
  ADD COLUMN IF NOT EXISTS icon_key TEXT NOT NULL DEFAULT '';

ALTER TABLE IF EXISTS matching.match_gift_sends
  ADD COLUMN IF NOT EXISTS idempotency_key TEXT;

UPDATE matching.match_gift_sends AS sends
SET icon_key = COALESCE(NULLIF(gc.icon_key, ''), 'rose_red')
FROM matching.gift_catalog AS gc
WHERE sends.gift_id = gc.id
  AND (sends.icon_key IS NULL OR sends.icon_key = '');

UPDATE matching.match_gift_sends
SET icon_key = 'rose_red'
WHERE icon_key IS NULL OR icon_key = '';

CREATE INDEX IF NOT EXISTS idx_match_gift_sends_match_sender_created
  ON matching.match_gift_sends(match_id, sender_user_id, created_at DESC);

CREATE UNIQUE INDEX IF NOT EXISTS idx_match_gift_sends_idempotency
  ON matching.match_gift_sends(match_id, sender_user_id, idempotency_key)
  WHERE idempotency_key IS NOT NULL AND idempotency_key <> '';
