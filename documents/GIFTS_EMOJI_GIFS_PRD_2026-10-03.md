# Gifts, emoji and GIFs: product requirements

Status: **proposal for founder decision, 2026-10-03.** Requested as "Tango or Chamet style gifts, more emoticons and GIF icons". Coin numbers are starting points. Replace them with measured data after the first 60 days.

## 1. The problem today

- **Gifts look and feel small.** There are 40 catalog gifts priced from 0 to 20 coins, shown as a static card strip above the composer (White Rose, Yellow Rose, Lavender…). A gift lands as a chat card with no moment of delight. Even the most expensive gift (20 coins) feels the same as a free rose.
- **Emoji are minimal.** The chat emoji button opens a short fixed row (`_quickEmojis` in `chat_screen.dart`). There is no search, recents, skin tones, reactions on messages, animated emoji or stickers.
- **There are no GIFs.** Members paste nothing richer than text.

What already exists, so nothing below starts from zero:
- A transactional gift ledger (`gift_send_ledger.go`, migration 074).
- One free gift per UTC day.
- Paid-gift confirmation.
- Operator gift reversal.
- Coin fraud and velocity controls (migration 089).
- Receiver controls (hide or report a gift).
- Seasonal and limited windows on the catalog (`start_date`, `end_date`, `is_limited`).
- A console gift catalog.

## 2. What we take from Tango and Chamet, and what we don't

Tango and Chamet are **live-streaming and video-chat apps whose business is the gift economy**. Hosts earn "diamonds" from gifts and cash them out. Three of their mechanics make gifting fun, and we want those:

| Take | Why it works |
|---|---|
| **A gift is an event.** Animated effects scale with value, up to a full-screen moment (car, yacht, castle, fireworks), with optional sound. | The sender is seen; the receiver feels celebrated. |
| **A wide price ladder.** Tiny gifts to luxury gifts, with rarity styling. | Everyone can play, and there is room to splurge on a special occasion. |
| **Combos.** Tapping the same gift again within a few seconds counts up "x2, x3…" with an escalating effect. | Playful, social, memorable. |
| Seasonal and limited drops, a gift wall on the profile, and gifts during calls. | Novelty, status, and a reason to come back. |

One thing we deliberately **don't** take at launch: **receivers cashing out gifts for money.** In a dating product that turns conversations into a revenue stream for the receiver. It is the classic setup for romance-scam and pay-to-chat exploitation, and it pushes vulnerable members toward compulsive spending. It also brings KYC, tax, anti-money-laundering and store-policy work, which our trust positioning (verified members, Shows Up, Graduation Refund) cannot carry. Receivers get recognition instead (section 3.5). Revisit only with a separate legal and safety review. **This is founder decision D1.**

## 3. Gifts

### 3.1 Price ladder (starting points; validate against the approved coin-package catalogue)

| Tier (existing `tier` values kept) | Coins | Effect level | Examples to add |
|---|---|---|---|
| Free (1 a day, unchanged) | 0 | Card + small burst | Rose, wave, coffee |
| Common | 1–9 | Bubble animation in chat | Heart, chocolate, cupcake, sunflower, high-five |
| Rare | 10–49 | Bubble + short overlay | Bouquet, teddy bear, perfume, concert tickets, picnic basket |
| Epic | 50–199 | Full-screen effect (3–4 s) | Hot-air balloon, starry sky, rose rain, beach sunset, love letter |
| Legendary | 200–999 | Full-screen effect with camera move (5–6 s) | Sports car, yacht, ring box, castle, fireworks over the city |
| Exclusive / seasonal | Any | Signature effect, limited window | Diwali lamps, Valentine's carousel, New Year fireworks, look-themed gifts (Snow, Gothic, Blue Rose) |

That's about 40 new gifts on top of the 40 we have, rebalanced so the ladder isn't capped at 20 coins. Prices stay operator-tunable in the console.

### 3.2 The gift moment
- **In chat:** the gift card animates in. Epic and above play a full-screen overlay for both members: for the receiver when they open the chat, for the sender on send.
- **Skipping and accessibility:**
  - Tap to skip.
  - The Calm look and the system reduce-motion setting show a still card with a short haptic instead.
  - Sound is off by default.
  - Effects never cover the composer for more than 6 s.
- **"Thank you":** the receiver can reply with a free animated thank-you, one per gift. It feeds the reply-rate metric.
- **Gifts in voice and video calls:** a compact gift tray on the call screen, with effects overlaid on the call.

### 3.3 Combos
- **How it works:** sending the same gift again within 3 s increments a combo (x2…x99). Each step re-uses the ledger's per-send transaction, so there's one debit per tap and an idempotency key per tap.
- **Display:** the effect escalates at x5, x10 and x25. Both sides see one combo banner, not 25 cards.
- **Spending guardrails:**
  - A confirmation sheet appears when a combo crosses 200 coins.
  - The existing velocity rules (migration 089) apply per tap.
  - A daily spend cap per member is operator-tunable. The default is off for verified members and on for accounts under 7 days old.

### 3.4 Discovery and sending
- The current card strip becomes a **gift tray** that slides up from the composer:
  - Tabs: Popular, Romantic, Fun, Luxury, Seasonal, Owned.
  - A wallet balance with a "Get coins" entry.
  - A long-press preview that plays the effect before you buy.
- Gifts also go on profiles (existing admirer escrow) and in the Today wall.

### 3.5 What the receiver gets (instead of cash-out)
- **A gift wall** on the profile, shown only if the member opts in, using the same consent model as the profile showcase (migration 130). Senders are not public by default.
- **Progression XP** per gift received (the existing progression ledger), plus cosmetic badges ("Admired" tiers).
- **Optional "Pass it on":** convert a received gift into a free gift to send. No coin or cash value leaves the economy.

### 3.6 Data and backend changes
- **Catalog:** add `effect_level` (card | bubble | overlay | fullscreen), `animation_asset_id`, `sound_asset_id`, `preview_asset_id`, `combo_enabled`, `rarity_color`.
- **Assets:** stored in our media store (private bucket, signed reads, content hash) and uploaded through the console. The app caches them by hash. No third-party CDN.
- **`match_gift_sends`:** add `combo_id`, `combo_step` and `context` (chat | call | profile | wall).
- **New tables:** `gift_wall_settings` and `member_spend_caps`.
- **Events:** realtime events for combo banners, and a thank-you link to the gift send.
- **Console:** catalog editing with effect preview, tier/price history, a combo-cap and spend-cap screen, and a gift economy report (adds to the report server).

### 3.7 Animation assets
- **Format:** Lottie (the `lottie` Flutter package) for bubble and overlay effects. Rive is the alternative if we want interactive full-screen scenes. Decide in a one-day spike.
- **Budget:** 150 KB or less per bubble effect, 600 KB or less per full-screen effect. Downloaded on first use, not bundled.
- **Source:** commission an original set (recommended: distinctive, ownable, matches the couture looks) rather than generic marketplace packs, whose licences vary per file. **Decision D4.**

## 4. Emoji and reactions

- **Full emoji picker:**
  - Search in all 10 app languages (CLDR annotations bundled with the app).
  - Categories, recents, skin tones and the system emoji font, so there is no large font download.
  - Replaces the fixed row; the quick row stays as the first line of recents.
- **Message reactions:** long-press any message to react with one of 6 quick emoji or "+" for the picker. Reactions show under the bubble with counts in group and room chat. One reaction per member per message, changeable.
- **Animated emoji:** about 60 popular emoji play as small animations when sent alone. Google's Noto Animated Emoji are openly licensed (verify the current licence and attribution before use). Reduce-motion shows them still.
- **Sticker packs:**
  - Original packs drawn in the app's style.
  - One free starter pack, look-themed packs sold for coins (fits the existing theme-pack economy), and seasonal packs.
  - Stickers are images in our media store, sent as a message type.
- **Where:** dating chat, friend/room/group chat, comments, club discussions. The same surfaces as the font-styles work, so the composer is built once.

## 5. GIFs

- **Search and trending GIFs** in the composer, behind a GIF button next to emoji.
- **Provider:**
  - Recommended: **GIPHY through our own server proxy.** The app calls our backend, never the provider directly, so member IP addresses and search terms are not tied to identities. The server enforces the content rating, a blocklist and caching.
  - Alternatives to evaluate: KLIPY, or Tenor if its API remains available for new integrations. Check each provider's current terms, attribution rules and pricing before signing. **Decision D2.**
  - Second option: a curated in-house GIF and sticker library with no third party. Safer and fully moderated, but a smaller catalog.
- **Safety:**
  - Rating capped at PG-13 globally and at G in the first message to a new match.
  - Members can report a GIF; repeat reports block it platform-wide.
  - Receivers can turn off GIFs from people they haven't replied to.
- **Data:** a GIF message stores the provider's id, the dimensions and a still preview, not a hot-linked URL. If the provider removes the GIF, the chat shows the still.
- **Vendor tracking:** the provider goes into `THIRD_PARTY_INTEGRATIONS.md` (API key in managed secrets, attribution in the picker).

## 6. Rules for every new message type

- **Quota:** GIFs, stickers and animated emoji count toward the free member's daily message quota (5 a day today). Reactions and the free thank-you don't. **Decision D3.**
- **Moderation:** text alongside a gift or GIF goes through the existing message moderation. Stickers and gift animations are first-party, so they are pre-approved. Reports carry the message type.
- **Blocking:** blocking a member stops gifts, reactions and GIFs both ways and retracts unseen gift effects. (Related open safety bug: blocked pairs still appear in Matches. Fix it first.)
- **Notifications:** plain-text previews ("Priya sent you a Bouquet 💐", "Arlo sent a GIF") with no media in push payloads.
- **Older app versions:** each new message type has a plain-text fallback in `body`.

## 7. Phasing

| Phase | Scope | Est. |
|---|---|---|
| **1. Expression** | Full emoji picker with search, message reactions, a GIF picker via the server proxy (or curated library), the gift tray redesign, bubble and full-screen effects for the existing 40 gifts plus about 20 new ones, reduce-motion handling, console catalog fields and asset upload | 3–4 weeks |
| **2. Gift economy** | Price-ladder rebalance with about 40 more gifts, combos with spend guardrails, thank-you, gifts in calls, gift wall and "Admired" badges, seasonal drops, gift economy report | 3 weeks |
| **3. Collectibles** | Animated emoji, sticker packs (free starter plus coin packs), look-themed gifts and stickers, sticker/GIF moderation analytics | 2–3 weeks |

Each phase ships with tagged tests for QA Lab, l10n in all 10 languages, and console reports.

## 8. How we'll measure it

- **Gifting:**
  - Share of chats with at least one gift.
  - Paying-gifter conversion.
  - Coin ARPU (target from the pricing doc: India ₹12, Europe €0.40 per active per month).
  - Reply rate within 24 h after a gift, against no gift.
- **Expression:** reaction use per active, GIF and sticker sends per conversation, conversation length.
- **Health guardrails (must not get worse):**
  - Gift and GIF report rate.
  - Refund and chargeback rate.
  - Top-1% spender share of coin revenue (alert above 40%).
  - Spend-cap hits.
  - Blocks after gifts.

## 9. Decisions needed

| # | Decision | Recommendation |
|---|---|---|
| D1 | Can receivers cash out gifts? | **No** at launch. Recognition, XP and "Pass it on" instead. |
| D2 | GIF source | **GIPHY via our server proxy**, rating-capped (or a curated in-house library if no third party is wanted). |
| D3 | Do GIFs, stickers and animated emoji count toward the free message quota? | **Yes**. Reactions and thank-yous don't. |
| D4 | Gift animation assets | **Commission an original set** in Lottie. |
| D5 | Coin prices for the new ladder | Approve after the coin-package catalogue is signed off (BILLING acceptance item 3). |
