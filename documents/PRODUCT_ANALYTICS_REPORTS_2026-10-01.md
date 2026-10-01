# Product analytics reports (2026-10-01)

Durable product analytics for Connect: what is stored, how every number is
defined, who is counted, and how to read each report in the operator console.

- Migration: `backend/scripts/123_product_analytics_snapshots.sql` (schema `analytics`)
- Snapshot job: `backend/internal/bff/mobile/analytics_snapshots.go` (`analyticsSnapshotWorker`)
- Report API: `backend/internal/bff/mobile/server_admin_analytics_reports.go`
- Console: `control-panel/control_panel/views_analytics.py`, templates under
  `control-panel/templates/control_panel/analytics/`, sidebar section "Analytics"
- Tests: `backend/internal/bff/mobile/analytics_reports_test.go`,
  `control-panel/control_panel/tests/test_analytics.py`

## 1. Why this exists

Before this change:

- DAU/MAU were durable (`platform.member_last_activity`, migration 087) but only
  as "latest activity per member", so there was no history and no retention.
- The funnel and engagement figures of `GET /v1/admin/analytics/overview` came
  from the BFF's in-memory activity list. With Postgres configured that list is
  empty (`recordActivity` returns early), so the numbers were near zero, per
  instance and reset on restart. They are now labelled in the response
  (`metrics.runtime_metrics_scope`: `durable: false`) and the dashboard no longer
  shows them.
- `GET /v1/analytics/{userID}` (same in-memory store, and it counts reports filed
  *against* the member) was readable by the member themselves. It is now a
  support-operator view only (admin, trust_safety, moderator) and labelled
  `data_source: process_local_runtime_store`.

Reports are **never** built on `matching.activity_events`: it is being reduced
for privacy and has a 90-day retention. Every source is a durable domain table.

The City Pilot scorecard (`/v1/admin/growth/city-pilot`) is unchanged and remains
the pre-registered pilot funnel.

## 2. What is stored

| Table | Grain | Contents | Lifetime |
|---|---|---|---|
| `analytics.member_active_days` | member × UTC day | the member had qualifying activity that day; `source` = `session` or `action` | kept; deleted on account erasure |
| `analytics.member_surface_days` | member × UTC day × surface | number of counted actions on that product surface | kept; deleted on erasure |
| `analytics.daily_metrics` | UTC day × metric × segment cell | additive counts, plus `dau`/`wau`/`mau` per cell | kept (anonymous counts) |
| `analytics.member_milestones` | member | first time each activation step was reached | recomputed every run; deleted on erasure |
| `analytics.snapshot_days` | UTC day | derived/built timestamps, `final` flag, row counts | kept |
| `analytics.snapshot_runs` | run | scheduled or operator rebuild, status, error | kept |
| `analytics.excluded_accounts` | member | operator-flagged test accounts | until removed |
| `analytics.report_settings` | key | test-account patterns | editable |

A segment cell is `gender × city × age_band × account_age_band × level_band`.
Each member belongs to exactly one cell on a given day, so cell counts — including
WAU and MAU — add up correctly across any combination of filters.

### Live capture of activity

Every authenticated request updates `auth_sessions.last_used_at`; the 087 trigger
folds that into `member_last_activity` at most every five minutes. Migration 123:

- lets the first request of a new UTC day through the five-minute throttle (so a
  member active just after midnight is not lost), and
- adds a trigger on `member_last_activity` that inserts `(UTC day, member)` into
  `member_active_days`.

The nightly job adds the rest (see §4), so a day is active if *any* of these is
true: an authenticated session was used or created that day, the member's
recorded first/last activity falls on it, or the member performed a counted action.

## 3. Who is counted

`analytics.reportable_members` = every row of `user_management.users` except the
first matching rule of `analytics.member_exclusions`:

| Rule | Meaning |
|---|---|
| `erased_account` | `users.erased_at` is set |
| `introducer_account` | `account_kind <> 'dating'` |
| `operator_account` | any `auth_account_roles.role` other than `user` (admin, ops_admin, trust_safety, moderator, analyst, finance) |
| `flagged_test_account` | a row in `analytics.excluded_accounts` |
| `test_username` | username matches `report_settings.test_username_pattern` (case-insensitive POSIX regex). Default `^(appium|e2e|smoke|loadtest|test|qa)[._0-9]|qa[._]` — matches `giftqa_…`, `theme_qa_…`, `appium_…`, `socialqa_…` |
| `test_email_domain` | e-mail matches `report_settings.test_email_pattern`. Default: the RFC 2606/6761 reserved test domains (`example.com/net/org/test`, `*.test`, `*.invalid`, `*.example`, `*.localhost`) |

Flag or unflag a test account in the console (Analytics → Data & exclusions,
admin only) or with `POST/DELETE /v1/admin/analytics/excluded-accounts`. To change
a pattern: `UPDATE analytics.report_settings SET value = '…', updated_by = '…', updated_at = NOW() WHERE key = 'test_username_pattern'`
(an empty value disables the rule).

When exclusions apply:

- Member-level reports (retention, funnel, engagement, liquidity, women's good-day
  rate) apply them **when read**, so a new flag takes effect immediately.
- `daily_metrics` applies them **when a day is built**. After flagging an account,
  rebuild the days it was active (§4) to remove it from rollups and trends.

Locally most seeded accounts are test accounts (`giftqa_…`, `@example.test`), so
local reports are small and often suppressed. That is the intended behaviour.

## 4. Schedule, rebuilds, backfill

- The BFF starts `analyticsSnapshotWorker` whenever Postgres is configured. It wakes
  every 30 minutes, takes a Postgres session advisory lock
  (`pg_try_advisory_lock(0x616e616c79746963)`), and builds what the trailing 35
  days still need: every completed UTC day is built after midnight UTC, rebuilt
  once more after the following midnight (late rows), and then marked `final`.
  With several BFF instances only one builds; the others skip.
- A build replaces whole days (`DELETE` + `INSERT` per day in
  `analytics.rebuild_day`), so repeated or interrupted runs are harmless
  (idempotent; covered by a test).
- Before the first day of a run, any of the 29 preceding days never derived are
  derived (activity only), so WAU/MAU of the first rebuilt day are complete.
- `analytics.refresh_member_milestones()` recomputes the funnel milestones after
  every run that built something.
- On-demand: `POST /v1/admin/analytics/snapshots/rebuild {"from","to"}` (admin,
  at most 400 days, at most yesterday) starts a background run and returns
  `202 {run_id}`; `409` if a run holds the lock. Progress and errors are in
  `GET /v1/admin/analytics/snapshots` and the console's Data page.
- Backfill: the first start builds the last 35 days from durable timestamps. For
  older history, rebuild a range. History before migration 123 is derived from
  timestamps only (see limitations).
- Worker logs: `analytics_snapshot_cycle` (info, with days built and duration),
  `analytics_snapshot_cycle_idle` (debug heartbeat), `analytics_snapshot_cycle_failed`,
  `analytics_snapshot_rebuild(_failed)`. Each scheduled cycle also reports the
  shared worker heartbeat (`observability.NewHeartbeat("analytics_snapshot", 30m)`,
  items `days_built`); a cycle skipped because another instance holds the lock
  counts as a success.

## 5. Small-count suppression

Every API response and CSV export withholds any count from 1 to 4, and any ratio
or median whose numerator, denominator or support count is from 1 to 4. JSON
returns `null` and lists the key in the row's `suppressed` array; CSV and the
console print `<5`. Zero is not suppressed. A ratio with a zero denominator is
empty, not suppressed. Suppression does not defend against differencing between
overlapping filters; do not publish raw exports outside the operator team.

CSV cells that start with `=`, `+`, `-`, `@`, tab or CR are prefixed with `'` so a
city name cannot run as a spreadsheet formula.

## 6. Metric definitions (exact semantics)

All days are UTC: an event belongs to day `D` when `D 00:00 UTC <= ts < D+1 00:00 UTC`.
"Attributed to" is the member whose segment cell receives the count. Every count is
restricted to reportable members (§3) as of the build. "Action" marks an event that
makes the day active and counts toward its surface.

| Metric | Surface / action | Source and rule |
|---|---|---|
| `signups` | onboarding, action | `users.created_at` on D |
| `profile_completions` | onboarding, action | the member's first `profile_setup_completions` row (by `completed_at`, `id`) on D |
| `verifications` | — | `verification_states.status = 'verified'` and `reviewed_at` on D |
| `sessions_started` | — | `auth_sessions.created_at` on D (sign-ins) |
| `likes` / `passes` | discovery, action | `swipes` with / without `is_like`, attributed to the swiper |
| `matches` | — | `matches.created_at` on D, counted once **for each** member (total ÷ 2 = new pairs) |
| `messages_sent` | chat, action | `messages` with `gift_send_id IS NULL`, by sender (deleted messages still count as sent) |
| `first_messages` | — | the first non-gift message of a match, by the opener |
| `conversations_replied` | — | the first non-gift message of the second member of a match, after the opener wrote; by the replier |
| `date_plans_proposed` | date_plans, action | `match_date_plans.created_at`, by proposer |
| `date_plans_accepted` | date_plans, action | the plan's first `match_date_plan_events.to_status = 'accepted'`, by the event actor (fallback invitee) |
| `debriefs_submitted` | date_plans, action | `match_date_plan_debriefs.created_at` |
| `dates_kept` | — | a plan's first `happened = TRUE` debrief on D, when no participant has `happened = FALSE`; by that debriefer (one per plan) |
| `graduations` | — | `match_graduations.status = 'confirmed'`, `decided_at` on D, by proposer (one per pair) |
| `chapters_published` | chapters, action | `chapter_publications.created_at`, not revoked, partner-approved when there is a partner |
| `blog_posts_published` | blog, action | `blog_posts.published_at`, not deleted |
| `blog_reactions` / `blog_comments` | blog, action | `blog_likes` / `blog_comments` `created_at` |
| `photos_shared` | themes, action | `photo_theme_entries` not rejected |
| `photo_reactions` | themes, action | `photo_entry_likes` |
| `club_posts` / `club_joins` | clubs, action | `club_posts`; `club_members.joined_at` (owners excluded) |
| `room_messages` / `group_messages` / `friend_messages` | rooms / groups / friends, action | `social_messages` by channel kind `room` / `group` / `friend` |
| `room_joins` | rooms, action | `conversation_room_participants.joined_at` |
| `groups_created` / `group_joins` | groups, action | `community_groups.created_at`; `community_group_members.joined_at` (owners excluded) |
| `friend_requests_sent` | friends, action | `friend_request_sends` |
| `friend_requests_accepted` | friends, action | an accepted friendship (two accepted rows) whose later-created row — the accepter's — was created on D |
| `gifts_sent` | gifts, action | `match_gift_sends` not system gifts, not cancelled |
| `xp_awarded` | — | sum of positive `xp_ledger.awarded_xp` by `occurred_at` |
| `rewards_claimed` | rewards, action | `progression.reward_claims.claimed_at` |
| `reports_filed` | safety, action | `moderation_reports` + `blog_cases` with a reporter, by reporter |
| `blocks` | safety, action | `blocked_users.created_at`, by blocker |
| `dau` | — | members with a `member_active_days` row on D |
| `wau` / `mau` | — | distinct members active on any of the 7 / 30 days ending on D |
| `active_days_without_match` | — | active on D with no `matches` event on D |
| `good_days` | — | active on D, no new match on D, and at least one action on an entertainment surface (chapters, blog, themes, clubs, rooms, groups, friends, rewards) |

Derived metrics (computed from the rollups):

| Metric | Definition |
|---|---|
| Stickiness | DAU ÷ MAU on the as-of day (trends: average DAU in the period ÷ MAU on its last day) |
| **North star — weekly plans kept per active member** | `dates_kept` in the 7 days ending on the as-of day ÷ WAU on that day. Launch-to-live target (assumption, pricing doc): 0.08 |
| **Women's weekly good-day rate** | women (reportable, `gender = 'female'`) with at least one good day in the 7 days ÷ female WAU. Proxy for the entertainment strategy's north star ("weekly active women who did something enjoyable on a day they had no new match"). Not shown when the gender filter is not female |
| Good-day share | good days ÷ active days without a new match (any segment) |
| Match participations per active member | `matches` in the window ÷ WAU (or ÷ active members, liquidity) |
| Reports / blocks per 1,000 DAU | reports (blocks) ÷ active member-days × 1,000 |

Segments (computed for the day being built):

| Dimension | Values |
|---|---|
| `gender` | female, male, other, unknown (current profile value) |
| `city` | `initcap(lower(trim(users.city)))`, `unknown` if empty (current profile value) |
| `age_band` | 18-24, 25-29, 30-34, 35-44, 45+, unknown — age on the day from `date_of_birth` |
| `account_age_band` | day_0, days_1_6, days_7_29, days_30_89, days_90_plus — days since `users.created_at` |
| `level_band` | L1-L3, L4-L7, L8-L10 — latest `progression.level_transitions.to_level` before the day ends (level 1 if none) |

Member-level reports use the member's current gender and city, the age band at the
report's end date (funnel and retention: at signup) and the current level band.

## 7. API

All under `/v1/admin/analytics/`, admin and analyst (read-only). trust_safety,
moderator, ops_admin and finance cannot read them; `overview` stays readable by
every operator role because the console login probes it. Rebuilds and test-account
flags are admin-only. Every report accepts `from`, `to` (YYYY-MM-DD, at most 400
days; default `to` = latest built day), the five segment filters, `format=csv`
(or `Accept: text/csv`) and, for multi-table reports, `table=`.

| Route | Tables | Notes |
|---|---|---|
| `GET kpis?as_of=` | `tiles` | value + same window one week earlier |
| `GET trends?metric=&grain=day\|week\|month&group_by=` | `series` | any metric from `definitions`, including derived ones (shows numerator and denominator) |
| `GET funnel?cohort=week\|all&within_days=` | `steps` | one row per cohort × step |
| `GET retention?grain=&experiment=` | `summary`, `triangle` | `experiment` splits by `progression.experiment_assignments.variant` |
| `GET engagement` | `surfaces` | |
| `GET liquidity` | `cities` | gender filter ignored (gender is the breakdown) |
| `GET safety?grain=` | `trend`, `queues`, `by_surface` | |
| `GET definitions` | — | metric/surface/step catalog |
| `GET snapshots` | — | freshness, missing days, runs, exclusion counts, settings |
| `POST snapshots/rebuild` | — | admin; 202 + `run_id` |
| `GET/POST excluded-accounts`, `DELETE excluded-accounts/{memberID}` | — | admin; body `{member_id, reason}` |

## 8. Reading each report

**Overview.** KPI tiles as of the last day in range, with the previous week beside
each, and a DAU/WAU/MAU chart plus table. Watch stickiness (habit), the north star
(real-world outcomes) and the women's good-day rate (enjoyment without a match).

**Activation funnel.** Members who signed up in the range, strictly in order:
signup → terms → profile complete → verified → first like → first match → first
message → two-way conversation (both members sent at least three messages in one
match — the City Pilot proxy without its 7-day window) → plan accepted → date kept.
"From previous" is the step conversion; median hours are between consecutive steps
and from signup. `within_days` counts a step only if reached within N days of
signup (use 7 or 28 to compare cohorts fairly; recent cohorts are otherwise
immature). Milestones are recomputed on every run, so older cohorts keep improving
until their members stop progressing.

**Retention.** D1/D7/D30 = share of the cohort active on exactly day 1/7/30 after
signup, among members whose day N has been observed (the denominator columns show
how many). The triangle shows weekly return: week k = active any day of the k-th
week after the signup week (Monday). For a feature holdout pass its experiment key;
compare variants' D7/D30 (strategy target: +3 and +2 points for women — combine with
`gender=female`).

**Engagement.** Per surface over the range: members who used it, reach (share of
active members), DAU share (its member-days ÷ all active member-days), actions per
member and repeat use (members back on a second day ÷ members who used it).

**Liquidity by city.** Members active in the range by city and gender, women per
man, women share, new members, match participations and likes per active member,
dates kept. A coarse density signal; it does not model who is seeking whom.

**Safety health.** Reports and blocks per 1,000 active member-days (trend, follows
segment filters), time to action for member reports (`reviewed_at` vs
`review_deadline_at`) and content reports (`resolved_at` vs `review_due_at`) by
filing period (all reporters), and reports per 1,000 counted interactions by surface
(content cases mapped by `content_type`; member reports attributed to chat).

**Data & exclusions.** Built/final days, missing days, recent runs and errors,
exclusion counts by rule, the test-account patterns, a rebuild form and the flagged
accounts list.

The command-center dashboard reads DAU/MAU and four product KPIs from
`/kpis` (falling back to the live trailing windows of `member_last_activity` when
the operator lacks the analyst/admin role or no day is built yet).

## 9. Known limitations

- **History starts with migration 123** for anything not derivable from durable
  timestamps. Backfilled active days are a lower bound: before this migration only
  each member's first and last activity, sessions' creation and last use, and
  actions with timestamps are known. A member who only browsed on a past day is
  invisible for that day. Retention and WAU/MAU for backfilled periods are therefore
  understated.
- Rebuilding an old day uses today's source rows: room and group `joined_at` move on
  re-join, erased members' content is gone, later deletions disappear, and a plan
  whose second debrief later said "did not happen" stops counting as kept. Days
  become `final` after the second build so routine runs never rewrite them.
- Rollup segments use the member's gender and city at build time; member-level
  reports use current values. A member who moves city appears in the new city for
  member-level reports.
- Flagging a test account updates member-level reports immediately but daily
  rollups only after a rebuild.
- `matches` counts participations, not pairs.
- The women's good-day rate is a proxy: "enjoyable" = an action on an entertainment
  surface; it cannot see passive enjoyment (reading the wall) or satisfaction.
- No D7/D30 lift is computed automatically; the retention report splits by variant
  and the reader compares. Experiments must assign variants in
  `progression.experiment_assignments`.
- Suppression is per cell; overlapping filters can be differenced.
- On-demand rebuilds are logged but not part of the heartbeat.
- Large ranges on member-level reports (retention, engagement) scan
  `member_active_days`; keep ranges to what the question needs.
