# BRD: Gift Catalog Expansion & Engagement Activities
**Document ID:** BRD-GIFT-002  
**Date:** 2026-04-11  
**Status:** Approved for Implementation  
**Author:** Product / BA  
**Scope:** Backend (Go BFF), Flutter App, PostgreSQL / Supabase  

---

## 1. Executive Summary

The current gift catalog is limited to 17 rose variants. This document defines the requirements to expand into 4 additional gift categories (Themed Packs, Animated Reactions, Virtual Experiences, Seasonal), introduce a new `exclusive` tier (≥ 15 coins), add daily free-gift entitlements, and wire 6 engagement loops (dormant nudge, milestone system gifts, coin upsell, social proof, re-engagement, and daily habits). All catalog items must be configurable in the database — no hardcoded mock data.

---

## 2. Goals

| # | Goal | KPI |
|---|---|---|
| G1 | Expand gift catalog from 17 → 40+ items across 5 categories | Catalog item count |
| G2 | Increase daily active gift senders by 30% via daily free entitlement | DAU gift_send events |
| G3 | Drive 20% lift in premium coin purchases via exclusive tier upsell | wallet.coins.purchase events |
| G4 | Re-engage dormant matches (>48h no chat) via gift nudge | conversation_resumed events |
| G5 | Zero hardcoded catalog — 100% DB-driven | All items in gift_catalog table |

---

## 3. Scope

### 3.1 In Scope
- DB schema changes: `gift_catalog` (add `category`, `max_per_match_per_day`, `start_date`, `end_date`)
- DB schema changes: `match_gift_sends` (add `is_system`, `message`)
- New DB tables: `gift_daily_entitlements`, `admirer_gift_escrow`
- New catalog seed: themed packs, reactions, experiences, seasonal + exclusive tier
- Go BFF: struct/model updates, category response, daily entitlement enforcement
- Flutter: `RoseGift` model category field, catalog items, category-tabbed gift tray

### 3.2 Out of Scope (Phase 2)
- Real-time gift animations (Lottie overlays)
- Pre-match admirer escrow full flow (DB table created; API P2)
- Push notification integration for gift received events
- Custom e-card composer UI

---

## 4. Gift Categories

| Category | DB Value | Description |
|---|---|---|
| Roses | `roses` | Existing 17-variant rose collection |
| Themed Packs | `themed_pack` | Chocolate, Teddy Bear, Jewellery, Champagne, Balloon |
| Animated Reactions | `reaction` | Heart explosion, Confetti, Fireworks, Sparkle, Rainbow |
| Virtual Experiences | `experience` | Coffee invite, Movie night, Date card, Picnic, Sunset walk |
| Seasonal | `seasonal` | Valentine's, Christmas, Diwali (time-limited, start/end dates) |

---

## 5. Tier Model

| Tier | Price | Limit |
|---|---|---|
| `free` | 0 coins | 1/day via daily entitlement (or unlimited for paid coin users) |
| `premium_common` | 1 coin | Unlimited |
| `premium_rare` | 3 coins | Unlimited |
| `premium_epic` | 5 coins | Unlimited |
| `premium_legendary` | 8–10 coins | Unlimited |
| `seasonal_limited` | 6 coins | Active during start/end window only |
| `exclusive` | 15–25 coins | `max_per_match_per_day = 1` |

---

## 6. Acceptance Criteria

**AC-1 — DB-driven catalog**  
Every `GET /v1/chat/gifts` item originates from `matching.gift_catalog`. No hardcoded fallback items may be returned when the DB is reachable. Items must include a `category` field.

**AC-2 — Category grouping in API response**  
`GET /v1/chat/gifts` returns `gifts` (flat list, ordered by `sort_order`) and `categories` (set of distinct active category values). Client-side may group by category for tabbed display.

**AC-3 — New catalog items seeded**  
After running migration 045, the DB must contain ≥ 40 active gift items spanning all 5 categories.

**AC-4 — Exclusive tier daily limit**  
Sending a second `exclusive` gift to the same match within 24h returns HTTP 429 with `error: exclusive_gift_daily_limit_exceeded`.

**AC-5 — Daily free entitlement**  
A user may send 1 free-tier gift per UTC day regardless of wallet balance. After use, free gifts show a disabled state until midnight UTC reset. Tracked in `gift_daily_entitlements`.

**AC-6 — System milestone gift**  
When a conversation is unlocked (`conversation_unlocked` state), a system gift bubble is auto-inserted into the chat with `is_system = true` and `sender_user_id = null`.

**AC-7 — Seasonal item auto-expiry**  
A gift with `end_date < NOW()` is treated as `is_active = false` and excluded from catalog responses.

**AC-8 — match_gift_sends persists is_system + message**  
When a system gift is dispatched, the row in `match_gift_sends` must have `is_system = true`. E-card gifts may include a non-empty `message` (1–500 chars).

**AC-9 — No mock data in DB-connected mode**  
When `RequireDurableEngagementStore = true`, the memory-store catalog fallback must never be used.

**AC-10 — icon_key always resolved**  
Every catalog item returned from the API must have a non-empty `icon_key`.

---

## 7. Edge Cases

| # | Edge Case | Expected Behaviour |
|---|---|---|
| EC-1 | Gift deactivated between panel open and send | HTTP 422 `gift_no_longer_available` |
| EC-2 | Exclusive gift double-tap (same second, diff idempotency keys) | DB unique partial index prevents double debit |
| EC-3 | Free gift on midnight UTC boundary | Entitlement date in UTC, not local time |
| EC-4 | Seasonal gift sent after `end_date` | Treated as inactive; 422 response |
| EC-5 | User has no wallet row, sends free gift | Wallet auto-created with 12 coins; send succeeds |
| EC-6 | System milestone gift in paginated chat | Appears in correct chronological position on all pages |
| EC-7 | Same send with identical idempotency key from two devices | Idempotent replay; single debit |
| EC-8 | E-card message > 500 chars | HTTP 422 `message_too_long` |
| EC-9 | Gift panel opened offline | Show cached catalog; disable send until reconnected |
| EC-10 | Admin deactivates all items in a category | Category disappears from `categories` list in response |

---

## 8. Test Scenarios

| # | Scenario | Expected Result |
|---|---|---|
| TS-1 | Fetch catalog: 40+ items with category field | 200, `gifts.length ≥ 40`, each has `category` |
| TS-2 | Send themed_pack chocolate_box (0 coins, first of day) | 201, `gift_daily_entitlements` row created |
| TS-3 | Send themed_pack chocolate_box twice same day | Second send returns 429 `daily_free_limit_exceeded` |
| TS-4 | Send exclusive_diamond_ring (20 coins) twice same match same day | Second send 429 `exclusive_gift_daily_limit_exceeded` |
| TS-5 | Send fireworks_burst (3 coins), wallet debited | Wallet balance decreases by 3 |
| TS-6 | Wallet balance < gift price | HTTP 402 with `required` and `current_balance` fields |
| TS-7 | Conversation unlocked → system gift appears | Chat message with `is_system: true` |
| TS-8 | Seasonal gift after end_date | 422 `gift_no_longer_available` |
| TS-9 | Idempotent repeat send (same Idempotency-Key header) | 201 same response, no double debit |
| TS-10 | Catalog filtered by is_active=false item | Item not in response |

---

## 9. DB Schema Changes

### 9.1 gift_catalog (alter)
```sql
ALTER TABLE matching.gift_catalog
  ADD COLUMN IF NOT EXISTS category TEXT NOT NULL DEFAULT 'roses',
  ADD COLUMN IF NOT EXISTS max_per_match_per_day INT DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS start_date TIMESTAMPTZ DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS end_date TIMESTAMPTZ DEFAULT NULL;
```

### 9.2 match_gift_sends (alter)
```sql
ALTER TABLE matching.match_gift_sends
  ADD COLUMN IF NOT EXISTS is_system BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS message TEXT;
```

### 9.3 gift_daily_entitlements (new)
```sql
CREATE TABLE IF NOT EXISTS matching.gift_daily_entitlements (
  user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  used_date DATE NOT NULL,
  used_count INTEGER NOT NULL DEFAULT 0 CHECK (used_count >= 0),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (user_id, used_date)
);
```

### 9.4 admirer_gift_escrow (new)
```sql
CREATE TABLE IF NOT EXISTS matching.admirer_gift_escrow (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sender_user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  candidate_user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  gift_id TEXT NOT NULL REFERENCES matching.gift_catalog(id),
  gift_name TEXT NOT NULL,
  price_coins INTEGER NOT NULL DEFAULT 0 CHECK (price_coins >= 0),
  status TEXT NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'delivered', 'refunded', 'cancelled')),
  idempotency_key TEXT,
  escrow_expires_at TIMESTAMPTZ NOT NULL,
  delivered_at TIMESTAMPTZ,
  refunded_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

---

## 10. API Changes

### Existing endpoints (updated response shape)
- `GET /v1/chat/gifts` — adds `category` field per item and `categories` array in root

### No new endpoints in Phase 1

---

## 11. Implementation Files

| Layer | File | Change |
|---|---|---|
| DB | `backend/scripts/045_gift_catalog_expansion.sql` | New migration |
| Go | `backend/internal/bff/mobile/gifts.go` | Add Category, MaxPerMatchPerDay to struct; update defaults |
| Go | `backend/internal/bff/mobile/gifts_repository.go` | mapRoseGiftCatalogRow reads category; daily entitlement check |
| Go | `backend/internal/platform/config/config.go` | Add GiftDailyEntitlementsTable, AdmirerGiftEscrowTable |
| Flutter | `app/lib/features/messaging/models/rose_gift.dart` | Add category field + new items |
| Flutter | `app/lib/features/messaging/screens/chat_screen.dart` | Gift tray category tabs |
| Flutter | `app/lib/features/messaging/providers/message_provider.dart` | Map category from API |

---

## 12. Definition of Done

- [ ] Migration 045 applies cleanly to local and remote DB
- [ ] `GET /v1/chat/gifts` returns ≥ 40 items all with non-empty `category`
- [ ] Daily entitlement enforced end-to-end (free gift, second attempt blocked)
- [ ] Exclusive tier daily limit enforced
- [ ] Flutter gift tray shows category tabs and all new items
- [ ] All unit tests pass: `go test ./...` and `flutter test`
- [ ] `flutter analyze` reports no new errors
