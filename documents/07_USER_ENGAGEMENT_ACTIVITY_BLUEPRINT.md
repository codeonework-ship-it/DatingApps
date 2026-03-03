# User Engagement Activity Blueprint

Date: 2026-03-01

## Objective
Increase repeat quality sessions and meaningful interactions without increasing safety risk.

## Core Activity Tracks

### 1) Daily Prompt Loop
- One prompt/day (values + lifestyle).
- 60-second response cap.
- Streak milestones (7/14/30 days).
- Shared compatibility spark on completion.

### 2) Match Mini Activities
- 2-minute "This or That" activity in chat.
- Shared result card + 1 suggested follow-up question.
- Weekly refresh cadence.

### 3) Guided Voice Icebreakers
- One guided prompt/day per match.
- 20-45 second voice clip with transcript.
- Safety moderation before delivery.

### 4) Circles & Weekly Challenges
- City/topic micro-communities (books, fitness, music).
- Weekly low-friction challenge with short submissions.
- Highlight top safe, quality contributions.

### 5) Friend-Assisted Events
- Group coffee poll (time/place voting).
- Lightweight planning flow to reduce first-date friction.

## KPI Targets
- +10% D7 retention.
- +15% match-to-first-message within 24h.
- +12% weekly meaningful interactions/user.
- Keep report/block rate within +2% of baseline.

## Event Instrumentation
- `daily_prompt_viewed`, `daily_prompt_answer_submitted`, `daily_prompt_streak_milestone`
- `mini_activity_started`, `mini_activity_completed`, `mini_activity_shared`
- `voice_icebreaker_sent`, `voice_icebreaker_played`
- `circle_challenge_viewed`, `circle_challenge_submitted`
- `group_poll_created`, `group_poll_voted`, `group_poll_finalized`

## Delivery Plan (8 Weeks)
- Weeks 1-2: Daily Prompt + analytics baseline.
- Weeks 3-4: Mini Activity rollout + A/B cadence tests.
- Weeks 5-6: Voice Icebreaker pilot for selected cohorts.
- Weeks 7-8: Circles + Group Poll pilot in one city.

## Guardrails
- Max two engagement nudges/day.
- Suppress nudges for threads with recent safety events.
- No activity should take more than 2 minutes to complete.
- Add explicit user controls: mute, hide, opt-out per activity track.

---

## Level Progression KPIs and Experiment Hooks

Reference: `08_LEVEL_SYSTEM_ENGAGEMENT_BRAINSTORM.md`

### Progression KPI Layer
- Level completion rate by cohort and by level band (L1-L3, L4-L7, L8-L10).
- Time-to-next-level (median and p90) by acquisition source.
- Activity completion quality score by level cohort.
- Retention by level cohort (D1/D7/D30, WAU stickiness).

### Experiment Hooks
- XP weighting tests:
	- Prompt-heavy weighting vs balanced weighting.
	- Voice/circle bonus multiplier variants.
- Streak policy tests:
	- Strict streak reset vs fallback token recovery.
	- Weekly catch-up challenge enabled vs disabled.
- Acceleration fairness tests:
	- No acceleration (control) vs bounded acceleration (treatment).
	- Multiplier cap variants with safety parity checks.

### Required Event Set
- `level_xp_earned`
- `level_up`
- `level_reward_claimed`
- `acceleration_used`

Supporting recommended events:
- `level_progress_blocked_safety`
- `xp_cap_reached`
- `level_progress_recovered`

### Success and Guardrail Conditions
- Success:
	- Positive retention lift without regression in meaningful interaction quality.
	- Improved time-to-next-level for healthy-behavior cohorts.
- Guardrails:
	- Report/block rate threshold breach pauses rollout.
	- Fraud anomaly spikes trigger auto-disable of acceleration mechanics.

