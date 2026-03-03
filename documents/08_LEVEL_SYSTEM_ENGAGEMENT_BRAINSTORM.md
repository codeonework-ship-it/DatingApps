# Level System Engagement Brainstorm

Date: 2026-03-01

## Problem Statement and Goals

### Problem
Current engagement loops increase activity, but they do not yet provide a unified long-term progression system that rewards consistent, high-quality behavior across prompts, mini activities, circles, and voice interactions.

### Goals
- Create an activity-first level progression system that improves D7/D30 retention and meaningful interactions.
- Reward quality and trust signals over raw volume.
- Support optional paid acceleration without pay-to-win dynamics.
- Keep trust/safety controls non-bypassable by payment.
- Align with current engagement directions in:
  - `04_ENGAGEMENT_RETENTION_BRAINSTORM.md`
  - `07_USER_ENGAGEMENT_ACTIVITY_BLUEPRINT.md`
  - `06_10M_CONCURRENT_REQUESTS_BLUEPRINT.md`

---

## Level Philosophy
- Quality over quantity: meaningful completion and healthy interactions earn more than repeated low-value actions.
- Safety-first progression: report risk, abuse signals, and moderation outcomes can reduce multipliers or freeze advancement.
- No pay-to-win: money can save time but cannot unlock trust-gated capabilities by itself.
- Multi-path progress: users can level up through different activity styles (chat-centric, circle-centric, voice-centric).
- Predictable fairness: every level has transparent requirements and visible reward criteria.

---

## Level Ladder (L1-L10)

| Level | Theme | Core Requirement Snapshot | Primary Reward Snapshot |
|---|---|---|---|
| L1 | Onboarded | Profile completion + 1 guided activity | Base discovery visibility enabled |
| L2 | Active Starter | 3 days of activity + 1 mini activity | Basic streak badge + 1 profile accent |
| L3 | Reliable Participant | 5 quality completions in 7 days | Weekly visibility micro-boost |
| L4 | Conversation Builder | 3 meaningful interaction sessions | Advanced icebreaker suggestions |
| L5 | Trust Builder | Stable report ratio + consistency streak | Priority in compatible prompt surfaces |
| L6 | Circle Contributor | 2 circle challenge submissions | Circle highlight eligibility |
| L7 | Voice Confident | 3 successful voice icebreakers played | Voice-first prompt pack |
| L8 | Social Connector | Cross-feature activity consistency | Expanded social feature toggles |
| L9 | High-Quality Regular | 30-day quality score threshold | Stronger visibility scheduling tools |
| L10 | Community Anchor | Sustained quality + trust milestone | Prestige cosmetics + mentor-style badge |

Notes:
- “Quality completion” requires low-friction anti-spam checks and completion integrity.
- Trust-gated milestones (L5+) require behavior thresholds that cannot be bought.

---

## XP Model

### XP Sources
- Activity XP
  - Daily prompt submitted: +20
  - Mini activity completed: +30
  - Circle challenge submitted: +35
  - Voice icebreaker sent and played: +40
- Streak XP
  - 3-day streak: +20 bonus
  - 7-day streak: +60 bonus
  - 14-day streak: +140 bonus
- Quality multipliers
  - High completion quality score: up to 1.25x
  - Verified profile with healthy behavior: +10% multiplier cap
- Trust-linked adjustments
  - Low report ratio over rolling window: +5% to +15%
  - Moderation-risk or repeated unsafe behavior: multiplier reduced to as low as 0.5x

### Abuse Caps and Controls
- Daily XP cap by track and globally (for example: 300 total/day) to prevent farming.
- Repeated-action decay (same action repeated rapidly earns progressively less XP).
- Cooldowns for highly farmable actions.
- Invalidated XP for policy-violating content.

---

## Unlock Model (What Each Level Enables)

### Unlock Categories
- Visibility perks: placement windows, prompt response prominence, discovery freshness boosts.
- Social features: richer icebreakers, extended circle participation features, collaborative prompts.
- Advanced filters: expanded preference precision and saved filter presets.
- Premium cosmetics: profile accents, badge frames, themed response cards.

### Progression Principles
- Early levels prioritize habit formation and low-risk rewards.
- Mid levels unlock communication depth and social participation.
- High levels unlock status and sustained-consistency perks.
- Trust/safety-gated unlocks require behavioral milestones in addition to XP.

---

## Paid Acceleration Model (Bounded Time-Savers)

### Allowed Acceleration
- Boost packs: temporary XP earning efficiency within strict daily caps.
- Challenge multipliers: limited-use multiplier tokens for eligible activity tracks.
- Catch-up passes: reduce recovery friction after missed streaks without full bypass.

### Strict Boundaries
- No purchase can directly grant trust-gated unlocks.
- No purchase can override report-ratio thresholds or moderation outcomes.
- Acceleration cannot exceed system-wide cap multipliers.
- Paid value must remain optional; activity-only path can reach all core levels.

---

## Progression Mechanics Tied to Existing Flows

### Activities
- Daily prompt loop: baseline progression backbone.
- Mini activities: short cooperative engagement increments.
- Circle participation: community consistency and contextual engagement.
- Voice icebreakers: higher-value social confidence signal.

### Trust-Linked Boosts
- Verified profile status contributes a bounded positive multiplier.
- Badge consistency and healthy behavior trend improve progression efficiency.
- Low report ratio across rolling windows unlocks trust bonuses.

### Anti-Farming Rules
- Daily cap per action type and global cap.
- Repeated-action decay for duplicate behavior.
- Cooldown windows for high-frequency actions.
- Device/account anomaly checks and fraud scoring before final XP commit.

### Recovery Mechanics
- Missed-day fallback: partial streak protection tokens via activity completion.
- Weekly catch-up challenges: bounded opportunities to close progression gaps.
- Recovery never creates net advantage over consistent healthy participation.

---

## Level Unlock Catalog

### A) Level Rewards by Category

| Category | Example Rewards |
|---|---|
| Visibility Perks | Short discovery boost windows, profile freshness priority |
| Social Features | Extra guided prompts, richer circle interactions, voice prompt packs |
| Advanced Filters | Additional filter precision, saved filter sets, smarter defaults |
| Premium Cosmetics | Badge styles, profile accents, prompt card themes |

### B) Hard-Locked Features (Behavior Milestones Required)
- Trust-sensitive visibility amplifiers.
- High-impact social broadcasting features.
- Elevated trust presentation states.

Requirement pattern:
- Minimum level + trust behavior thresholds + safety compliance window.

### C) Optional Acceleration Options (Strict Limits)
- Boost packs: limited duration and capped incremental benefit.
- Challenge multipliers: only for specific challenge windows.
- Recovery aids: bounded streak restoration support.

---

## Analytics and Rollout Blueprint

### KPI Set
- Level completion rate (by level and cohort).
- Time-to-next-level (median and p90).
- Activity completion quality score.
- Retention by level cohort (D1/D7/D30 and rolling WAU retention).

### Event List
- `level_xp_earned`
- `level_up`
- `level_reward_claimed`
- `acceleration_used`

Recommended supporting events:
- `level_progress_blocked_safety`
- `level_progress_recovered`
- `xp_cap_reached`

### Rollout Plan
1. Internal dogfood.
2. 5% cohort release.
3. 25% cohort release.
4. Global rollout.

### Guardrails
- Fraud detection on XP event anomalies.
- Report-rate thresholds as rollout stop conditions.
- Instant rollback rules for safety regression or severe metric drift.

---

## Decision Matrix

| Unlock Type | Rule |
|---|---|
| Activity-only unlocks | Available through behavior and progression only; no payment required or accepted |
| Level-plus-premium unlocks | Require level threshold first; premium can enhance convenience/cosmetic value only |
| Never purchasable unlocks | Trust/safety-gated and behavior-earned states; permanently non-monetizable |

---

## Verification

### Document Quality Check
- Each level defines clear requirement intent and reward intent.
- Paid acceleration remains optional, bounded, and non-bypass for trust/safety.
- No section conflicts with existing trust/chat unlock direction.

### Consistency Check Across Linked Docs
- Engagement KPIs and level KPIs are aligned by retention and meaningful interactions.
- Reliability assumptions include high-throughput XP event handling and safe degradation.

---

## Implementation Notes (Next Draft)
- Convert snapshot requirements into exact XP thresholds per level.
- Define canonical quality-score formula and abuse-fraud scoring thresholds.
- Add schema/event contract for XP ledger and level state history.
- Add experimentation map for acceleration pricing and fairness perception.
