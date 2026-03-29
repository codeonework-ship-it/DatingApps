# Rose GIF Gifts Economy — Agile Product & Sprint Plan (19 Mar 2026)

## 1) Product Goal
Build a chat-adjacent Rose GIF gifting experience that improves:
- Conversation depth
- Daily retention
- Monetization via coins/wallet

## 2) Problem Statement
Users currently have text-first chat with limited emotional expression and no lightweight virtual gifting. We need an expressive layer that does not feel paywalled while introducing a healthy in-app economy.

## 3) Success Criteria (North Star + Guardrails)
### North Star
- Increase D7 retention for users who open chat gift panel by >= 8% vs control.

### Business + UX guardrails
- Keep free catalog share between 30% and 40%.
- Maintain gift-send completion rate >= 90% after opening confirm sheet.
- Keep abuse/fraud incidents below threshold (to be defined by Trust & Safety).

## 4) User Personas & Jobs-To-Be-Done
1. Casual Chatter (new users)
- Wants easy, low-friction ways to show interest.
- Needs at least a few free gifts to avoid friction.

2. Engaged Matcher (active chat users)
- Wants richer emotional signals and social status.
- Will use premium/limited roses if value is clear.

3. Collector/Status User
- Motivated by rarity, limited drops, and profile badges.
- Most likely to purchase coin packs.

## 5) MVP Scope (Phase A)
### In scope
- Inline Rose GIF tray above message composer.
- Free + paid rose catalog with coin prices.
- Wallet balance in chat gift panel.
- Confirm-before-send flow for paid gifts.
- Send gift as a chat event message.
- Manual coin top-up (internal/admin-assisted or simple debug endpoint for MVP).

### Out of scope (Phase B+)
- Full payment gateway + subscriptions bundles.
- Dynamic recommendation engine.
- Marketplace/trade economy.

## 6) Catalog v1.1
## Free
- Single Red Rose
- Pink Rose
- White Rose
- Yellow Rose
- Lavender Rose

## Paid
- Premium Common (1 coin): Blue, Black
- Premium Rare (3 coins): Sparkle, Heart-Petal, Neon
- Premium Epic (5 coins): Rose Rain, Burning
- Premium Legendary (8–10 coins): Golden, Crystal, Bouquet 12/24
- Seasonal Limited: weekly rotating paid rose

## 7) Coin & Wallet Mechanics (Draft)
### Earning
- Daily streak: 1, 2, 3, 5, 8 coins (reset on missed day)
- Session reward: every active X minutes, capped per day
- Engagement reward: first meaningful chat reply/day
- Social reward: first gift/day gives small coin rebate

### Spending
- Spend coins to unlock/send paid roses.
- One wallet balance for all gift actions.
- Optional starter pack and bundles in later sprint.

### Economy safeguards
- Daily earn cap (example: 40 free coins/day)
- Anti-idle checks (tap/scroll/message activity required)
- Cooldowns on repetitive reward actions

## 8) Agile Epic Structure
- EPIC RG-1: Gifting UX in chat
- EPIC RG-2: Catalog + wallet backend
- EPIC RG-3: Coin earning loops
- EPIC RG-4: Monetization packs + offers
- EPIC RG-5: Trust, anti-abuse, telemetry, experimentation

## 9) Jira-Ready User Stories (Draft)

### RG-101 — Show inline rose tray in chat
As a chatting user,
I want a rose gift tray beside the message composer,
so that I can quickly choose and send a rose gift without leaving chat.

Acceptance Criteria:
- Given I am in chat, when I tap gift entry, then inline tray opens above composer.
- Given tray is open, when I tap close, then tray collapses without losing typed text.
- Given chat lock state is active, gift controls are disabled.

Story Points: 5
Priority: High

---

### RG-102 — Free/Paid gift cards with wallet balance
As a user,
I want to see free vs paid roses and my coin balance,
so that I know what I can send now.

Acceptance Criteria:
- Gift cards clearly show Free or X coins.
- Wallet balance is visible in tray and near send action.
- Paid gifts become disabled when balance is insufficient.

Story Points: 5
Priority: High

---

### RG-103 — Preview and confirm before sending paid gift
As a user,
I want a preview+confirm flow,
so that I avoid accidental coin spending.

Acceptance Criteria:
- Tapping any gift opens preview sheet.
- Paid gift requires explicit confirm to send.
- Free gift supports one-tap send from preview.

Story Points: 3
Priority: High

---

### RG-104 — Persist gift sends as chat events
As a recipient/sender,
I want gift sends to appear in chat history,
so that gift context stays inside the conversation timeline.

Acceptance Criteria:
- Gift sends are retrievable from chat message list.
- Gift bubble shows GIF/image, name, and free/price metadata.
- Legacy text messages remain unchanged.

Story Points: 8
Priority: High

---

### RG-105 — Catalog API (DB-backed)
As a mobile client,
I want to fetch gifts from backend,
so that catalog can evolve without app release.

Acceptance Criteria:
- Endpoint returns active catalog entries with price/tier/limited metadata.
- DB schema supports free and paid gifts.
- API contract documented in OpenAPI.

Story Points: 8
Priority: High

---

### RG-106 — Send gift API with wallet debit
As a user,
I want premium gift sends to deduct wallet coins atomically,
so that balance and gift send are consistent.

Acceptance Criteria:
- Request validates sender, receiver, match context.
- Paid send fails with clear error on insufficient coins.
- Wallet debit + gift send are transactional/consistent.
- Idempotency prevents duplicate debits on retries.

Story Points: 13
Priority: High

---

### RG-107 — Wallet read/top-up API (MVP)
As a user,
I want to see wallet balance and receive controlled top-ups,
so that I can test and use premium gifts.

Acceptance Criteria:
- Wallet endpoint returns current balance.
- MVP top-up endpoint exists for controlled environments.
- All balance changes are audit-logged.

Story Points: 8
Priority: Medium

---

### RG-108 — Daily login streak coins
As a returning user,
I want streak-based coin rewards,
so that I am motivated to return every day.

Acceptance Criteria:
- First login each day grants streak reward.
- Missed day resets streak.
- Daily cap is enforced.

Story Points: 8
Priority: Medium

---

### RG-109 — Active session coin rewards with anti-idle
As an active user,
I want to earn small coin rewards for real activity,
so that app engagement feels rewarding.

Acceptance Criteria:
- Reward only when active interactions occur.
- Idle/background time does not grant rewards.
- Daily cap and cooldown are enforced.

Story Points: 13
Priority: Medium

---

### RG-110 — Gift telemetry + dashboards
As product/analytics,
I want gift funnel metrics,
so that we can tune pricing and reward economics.

Acceptance Criteria:
- Track panel open, preview open, send success/failure, insufficient coins.
- Track coins earned/spent, gift tier distribution.
- Admin analytics surface key KPIs.

Story Points: 8
Priority: High

---

### RG-111 — Weekly limited rose drop
As a status-driven user,
I want weekly limited rose drops,
so that gifting feels fresh and collectible.

Acceptance Criteria:
- One weekly limited gift is flagged active.
- Expired limited gifts are hidden/disabled.
- Drop schedule configurable without app release.

Story Points: 5
Priority: Medium

---

### RG-112 — Abuse and fraud controls
As trust & safety,
I want safeguards against reward farming and suspicious velocity,
so that the economy remains fair.

Acceptance Criteria:
- Velocity/rule checks for earn/send anomalies.
- Alert events for suspicious patterns.
- Feature-flagged response actions (warn, throttle, temporary lock).

Story Points: 8
Priority: High

## 10) Sprint Plan (2-week cadence)

## Sprint 1 (Foundation + MVP UX)
Goal: Ship basic catalog + gifting UI with stable send flow.
Stories:
- RG-101, RG-102, RG-103, RG-104, RG-105
Target points: 29
Deliverable: End-to-end free + paid rose sends visible in chat (manual wallet seed acceptable).

## Sprint 2 (Wallet + transactional safety)
Goal: Make economy consistent and production-safe.
Stories:
- RG-106, RG-107, RG-110
Target points: 29
Deliverable: Wallet APIs, atomic debits, telemetry baseline dashboards.

## Sprint 3 (Retention loops)
Goal: Add engagement-driven coin earning loops.
Stories:
- RG-108, RG-109, RG-112
Target points: 29
Deliverable: daily streak + session rewards with anti-idle and anti-abuse guardrails.

## Sprint 4 (Monetization acceleration)
Goal: Increase conversion and novelty.
Stories:
- RG-111 + bundle offers + starter pack follow-ups
Target points: 20-26
Deliverable: limited drops and offer mechanics with experiment toggles.

## 11) Definition of Ready (DoR)
- Story has measurable acceptance criteria.
- API schema and payload examples included.
- Feature flag strategy defined.
- Analytics events and owners named.
- QA scenario list attached.

## 12) Definition of Done (DoD)
- Unit + integration tests pass.
- OpenAPI updated where applicable.
- Feature behind flag for staged rollout.
- Error handling and idempotency verified.
- Tracking events visible in analytics.

## 13) Risks and Mitigations
1. Economy inflation risk
- Mitigation: daily caps, weekly tuning, anomaly checks.

2. Paywall perception risk
- Mitigation: maintain 30-40% free catalog and daily earn paths.

3. Duplicate debit risk on retries
- Mitigation: idempotency key + transactional debit/send.

4. GIF moderation/content risk
- Mitigation: curated catalog only; no user-uploaded GIF in MVP.

## 14) New Features to Consider (Brainstorm Backlog)
- Relationship milestone roses (e.g., first week chatting badge gift).
- Personalized gift recommendations by conversation tone.
- Gift combo effects (send 3 compatible roses -> special animation).
- Friend-to-friend gifting marketplace (non-transferable first).
- Event-themed drops (festivals, Valentine week, regional events).
- Creator roses (partner with artists for limited editions).
- “Gift quests” (send/receive milestones unlock profile cosmetics).
- Shared couple wallet challenges for co-op rewards.

## 15) Suggested First Sprint Kickoff Board Setup
Columns:
- Backlog
- Ready
- In Progress
- Code Review
- QA Validation
- Done

Ceremonies:
- Sprint planning: 90 min
- Daily standup: 15 min
- Mid-sprint risk review: 30 min
- Sprint review + retro: 60 min each

Owners:
- PM: catalog economics + prioritization
- Backend lead: wallet/catalog/send APIs
- Flutter lead: tray + preview + message rendering
- Data lead: telemetry taxonomy + dashboards
- Trust lead: abuse policy + controls
