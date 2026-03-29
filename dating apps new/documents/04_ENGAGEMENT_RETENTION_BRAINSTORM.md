# Engagement & Retention Brainstorm (Phase 2+)

Date: 2026-03-01

## Goals
- Increase quality repeat sessions (not just opens).
- Increase meaningful match interactions within first 72 hours.
- Create low-pressure, high-frequency engagement loops.
- Keep safety and authenticity as first-class constraints.

## North Star + Supporting Metrics
- North Star: Weekly meaningful interactions per active user.
- Supporting:
  - D1 / D7 retention uplift.
  - % matches that exchange at least 3 messages.
  - Time-to-first-message after match.
  - Feature participation rate by cohort.
  - Completion rate for mini experiences.
  - Negative feedback rate (report/block/mute) per feature.

---

## 1) Daily Compatibility Prompt + Streak Rewards

### Core Loop
- User sees one daily prompt matched to profile intent/value domains.
- User answers in <= 60 seconds (text, optional voice later).
- User sees “compatibility spark” with matched users who answered similarly.
- Consecutive-day participation builds streak.

### Prompt Types
- Values (trust, communication, family, ambition).
- Lifestyle (sleep, fitness, social energy, routines).
- Relationship style (conflict handling, affection, boundaries).

### Reward Ideas (non-gimmicky)
- Streak badges (private + optional public).
- “First look” placement in discovery feed for 24h after streak milestones.
- 1 bonus guided icebreaker per milestone.

### Anti-Abuse / Integrity
- One answer per day; edits allowed for 10 minutes only.
- Toxicity and spam checks for free-text prompts.
- Prompt pool rotation to prevent farming patterns.

### MVP Scope
- 1 daily prompt, text answer only.
- 7-day streak logic.
- Basic milestone reward (badge + profile highlight).

---

## 2) 2-Minute Mini Games for Matches

### Game A: This-or-That
- 8 fast rounds, swipe-left/right style choice cards.
- After completion: “alignment score” + top 3 common picks.

### Game B: Rapid Values Quiz
- 6 statements with 5-point agreement scale.
- Ends with a compact “values radar” summary.

### Design Principles
- Cap total session to 2 minutes.
- Always collaborative reveal, never competitive ranking.
- Offer one smart follow-up prompt per mismatch.

### MVP Scope
- This-or-That only, 8 cards.
- Shared result card in chat.
- One replay per match per week.

---

## 3) Weekly Local-Interest Circles + Lightweight Challenges

### Concept
- Topic circles by city: Books, Fitness, Music, Food, Weekend Trails.
- Weekly challenge: tiny social task, e.g. “share one current read in 20 words.”

### Why It Helps
- Converts passive browsing into low-friction contribution.
- Creates social proof and repeat check-ins.
- Surfaces “context-rich” intros beyond profile photos.

### Challenge Templates
- Books: “One quote that changed your week.”
- Fitness: “This week’s 20-min routine.”
- Music: “Song currently on repeat + why.”

### MVP Scope
- 3 city circles only.
- Text+image post format.
- Weekly challenge banner + participation counter.

---

## 4) Voice-Note Icebreakers with Guided Prompts

### Flow
- User taps “Send Voice Icebreaker.”
- Chooses guided prompt (or random prompt).
- Records 20–45 seconds.
- Receiver sees transcript + play button.

### Guided Prompt Examples
- “What does a calm Sunday look like for you?”
- “What’s one small ritual you never skip?”
- “Tell me about a hobby that grounds you.”

### Safety + Quality
- Max duration cap.
- Auto-transcript moderation before delivery.
- Report + hide voice note controls in-thread.

### MVP Scope
- 3 fixed prompts.
- Single voice note per match per day.
- Transcript + playback only (no editing).

---

## 5) Friend-Assisted Intro Events (Engagement Hub)

### Event Types
- Double Date Planner
  - Two users propose slots and vibe preference.
  - App finds overlap and confirms lightweight plan.
- Group Coffee Poll
  - 3–5 participants vote on area/time window.
  - Auto-pick top option after deadline.

### Why This Is Useful
- Reduces first-date anxiety.
- Increases trust via social context.
- Creates coordinated, action-oriented outcomes.

### MVP Scope
- Group Coffee Poll only.
- Up to 4 participants.
- Poll options: day, time, neighborhood.

---

## Suggested Rollout (Fastest Value First)

### Phase A (4–6 weeks)
- Daily Prompt + streaks.
- Mini Game: This-or-That (chat share card).

### Phase B (4–6 weeks)
- Voice-note guided icebreakers.
- Local circles pilot in one city.

### Phase C (6–8 weeks)
- Group Coffee Poll in Engagement hub.
- Expansion to multi-city circles and richer challenge types.

---

## Technical Notes (Aligned to Current Stack)
- Flutter app:
  - New Engagement modules: prompts, mini-games, circles, voice intro, group polls.
  - Reuse existing match + trust UI primitives where possible.
- Go backend:
  - New endpoints for prompt-of-day, answer submit, streak read.
  - Mini-game session start/submit/result endpoints.
  - Circle feed + challenge participation endpoints.
  - Voice-note metadata + moderation status endpoints.
  - Group poll create/vote/finalize endpoints.
- Data model additions (high-level):
  - daily_prompts, prompt_answers, user_streaks.
  - mini_game_sessions, mini_game_responses.
  - circles, circle_posts, weekly_challenges, challenge_entries.
  - voice_icebreakers, moderation_events.
  - intro_events, intro_event_votes, intro_event_participants.

---

## Experiment Matrix (First 8 Weeks)
- Prompt length: short vs reflective.
- Streak reward type: badge only vs visibility boost.
- Game frequency: one-time per match vs weekly refresh.
- Voice prompt count: 3 vs 6 templates.
- Circle challenge cadence: weekly vs bi-weekly.

Success criteria for each experiment:
- >= 8% relative lift in D7 retention OR
- >= 12% lift in meaningful interactions without increased report rate.

---

## Story Backlog Starters
1. As a user, I can answer one daily prompt and track streak days.
2. As a matched user, I can play a 2-minute This-or-That and view shared results.
3. As a user, I can send one guided voice-note icebreaker per match per day.
4. As a user, I can join a local circle and submit a weekly challenge entry.
5. As a user, I can create/vote in a group coffee poll from Engagement hub.

## Recommendation
Start with Phase A immediately. It has the best balance of build cost, engagement frequency, and measurable retention impact.

---

## Focused Brainstorm Output (Requested Now)

### A) 30-Day Engagement Sprint Candidates
1. Daily Prompt Streak + “See who replied” panel in Discover.
2. Match Nudge Engine (smart reminders at 3h/24h when conversation stalls).
3. Weekly Circle Challenge (single city pilot, one challenge only).
4. Voice Icebreaker Lite (one guided prompt + transcript).

### B) Prioritization (Impact vs Effort)
- **Highest ROI first:** Daily Prompt Streak + Match Nudge Engine.
- **Second wave:** Weekly Circle Challenge.
- **Third wave:** Voice Icebreaker Lite.

### C) KPI Targets for the Sprint
- +10% lift in D7 retention.
- +15% lift in “match-to-first-message within 24h”.
- +12% lift in weekly meaningful interactions per active user.
- No increase in report/block rate beyond +2% baseline tolerance.

### D) Instrumentation Required Before Rollout
- Event names (minimum set):
  - `daily_prompt_viewed`, `daily_prompt_answer_submitted`, `daily_prompt_streak_milestone`
  - `match_nudge_sent`, `match_nudge_clicked`, `conversation_resumed`
  - `circle_challenge_viewed`, `circle_challenge_submitted`
  - `voice_icebreaker_started`, `voice_icebreaker_sent`, `voice_icebreaker_played`
- Funnel dashboards by cohort: new users (0–7 days), returning users (8–30 days), power users.

### E) Rapid Experiment Schedule
- Week 1: Daily Prompt + instrumentation baseline.
- Week 2: Match Nudge Engine A/B (`control` vs `nudge`).
- Week 3: Circle Challenge pilot in one city.
- Week 4: Evaluate, keep top-2 winners, disable weak variant.

### F) Product Guardrails
- Avoid notification spam: max 2 engagement nudges/day/user.
- Respect safety state: suppress engagement nudges for recently reported/blocked threads.
- Keep completion time short: each engagement unit must finish in <= 2 minutes.

---

## Level Progression Layer

Reference: `08_LEVEL_SYSTEM_ENGAGEMENT_BRAINSTORM.md`

### Why Add It
- Unifies daily and weekly engagement loops into one long-horizon motivation system.
- Rewards consistency and quality behavior instead of raw activity volume.
- Creates transparent progression goals that support retention planning.

### How It Integrates with Existing Tracks
- Daily Prompt Loop contributes steady base XP and streak milestones.
- Match Mini Activities contribute medium XP for cooperative completion.
- Guided Voice Icebreakers contribute higher XP when quality and playback criteria are met.
- Circles and Weekly Challenges contribute community consistency XP.

### Retention Strategy Alignment
- Map each retention initiative to level outcomes:
  - Habit loops -> early level velocity (L1-L3).
  - Conversation depth -> mid-level stability (L4-L7).
  - Sustained quality and trust -> advanced levels (L8-L10).
- Use level progression to personalize nudges:
  - Early cohorts: completion reminders.
  - Mid cohorts: consistency challenges.
  - Advanced cohorts: prestige and contribution prompts.

### Safety and Fairness Constraints
- Progression remains activity-first; payment is optional acceleration only.
- Trust/safety milestones are non-bypassable.
- Anti-farming controls (daily caps, decay, cooldowns) protect quality metrics.

