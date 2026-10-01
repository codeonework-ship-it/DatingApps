# Pending Engine Priority Audit

Date: 2026-08-03  
Scope: Flutter app, Go services/BFF, Django control panel, PostgreSQL migrations,
automated tests, and repository documentation.

## Baseline completed in this implementation

- Username/password is the only Flutter signup and login mechanism.
- Username is normalized, unique, and immutable in PostgreSQL; UUID remains the
  relational key.
- Native PostgreSQL signup credentials, opaque sessions, terms, profile draft,
  photo upload, workflow activities, resume, and completion are implemented.
- Platform-wide native bearer authentication, self-ownership checks, admin
  RBAC, refresh rotation, revoke/logout, password change/recovery, recovery
  codes, and account lockout are implemented by migration 052.
- Native pooled-pgx repositories now back the local profile, matching, chat,
  safety, engagement, social, gifts, spotlight, and billing runtime. Local mode
  fails closed instead of falling back to memory, and migration 053 plus a full
  restart durability proof are complete.
- The Flutter signup path is account basics -> terms -> photos -> about/bio ->
  preview/completion. Resume selects the first missing durable activity.
- The local PostgreSQL database contains 86 application tables across
  `user_management` and `matching`.
- Migration 055 completes transactional safety/moderation/verification
  workflows, immediate suspension/ban enforcement, SLA queues, and immutable
  operator-attributed security events.
- Migration 056 makes profile media durable at upload time, enforces count,
  byte, type, and dimension limits, records moderation/lifecycle metadata,
  preserves completed profile snapshots, and drives local orphan cleanup.
- Migration 057 replaces best-effort notification fanout with a transactional
  PostgreSQL outbox, durable inbox, preference-aware worker, retry/dead-letter
  state, device registry, provider-neutral push bridge, authenticated resumable
  WebSocket, unread state, and queue telemetry.
- Migration 058 adds native PostgreSQL covering indexes for active matches,
  chat resume, discovery, moderation queues, and notification claims. The BFF
  now enforces route timeout tiers; every PostgreSQL pool applies bounded
  statement/lock/idle-transaction limits; reliability and durable notification
  metrics feed committed Grafana and Prometheus assets; and a loopback-only
  burst gate is part of release regression.
- Migrations 059-060 complete the local admin control-plane boundary: Django
  username/password operator sessions, bearer refresh, scoped operator roles,
  eight native PostgreSQL sections, runtime app feature-flag reflection,
  nudge operations/kill switch, and immutable acceptance-tested audit events.
- Migration 064 completes the local Level/XP product: exact thresholds and
  anti-farming rules, append-only XP ledger, asynchronous projection, trust
  gates, reward claims, experiments, telemetry, fraud review, Flutter journey,
  and operator controls.

The imported activity-unlock Jira backlog is documented as complete. It is not
listed below as missing product behavior; its remaining work is conversion from
Supabase/in-memory storage to the mandated native PostgreSQL runtime and broader
UI automation.

## Prioritized pending engines

| Rank | Priority | Engine | Current evidence | Completion outcome |
|---:|---|---|---|---|
| 1 | **P0 — implemented foundation** | Session, authorization, and account security | Migration 052 and the BFF security boundary now authenticate protected native-local routes, derive actor headers from opaque sessions, enforce self paths/body actors and match membership, protect admin routes with database roles, and provide refresh/revoke/logout/password/recovery/lockout contracts. | Extend fine-grained resource membership checks as the remaining Supabase/in-memory repositories move to native PostgreSQL; provision operator roles only through reviewed database administration. |
| 2 | **P0 — implemented foundation** | Native PostgreSQL data-access conversion | Local mode now composes pooled pgx repositories for all runtime modules, disables Supabase Realtime, validates repository readiness at startup, and passed a multi-module service-restart proof. Production BFF composition forces durable/fail-closed behavior in every environment; memory compatibility is test-only. Migration 053 is applied. | Continue adding typed repository methods and performance indexes as feature queries evolve; keep remote Supabase compatibility isolated from the local execution graph. |
| 3 | **P0 — implemented** | Core dating runtime: profile, discovery, swipe, match, and chat | The completed-signup → discovery → mutual swipe/match → quest unlock → persisted chat journey is native PostgreSQL. Migration 054 adds transactional outbox events, read cursors, lifecycle fields, and indexes. Flutter consumes a bearer-authenticated WebSocket with cursor replay and bounded reconnect. Live QA proved delivery/read receipts, restart replay, unmatch events, match-list removal, and post-unmatch chat denial. | Add broader device/Appium automation and production-scale WebSocket load/soak tests; the functional P0 path is complete. |
| 4 | **P0 — implemented** | Safety, moderation, verification, and admin enforcement | Migration 055 and typed PostgreSQL workflows now cover block/unblock, report transitions, 48-hour appeals, verification synchronization, priority SOS queues, and atomic suspend/ban plus session revocation. Operator identity is bearer-derived, security events are append-only, and live tests proved next-request rejection, SLA persistence, correct SOS queueing, and audit immutability. | Add production moderation staffing/alert integrations and broader browser/device automation; the functional P0 enforcement boundary is complete. |
| 5 | **P1 — implemented** | Media lifecycle and profile quality | Migration 056 and the native BFF now validate content signatures and 300-4096 px dimensions, accept JPEG/PNG/WebP/HEIC, enforce 5-photo/10 MB item/50 MB user quotas, reject metadata-only bypasses, persist lifecycle/moderation metadata transactionally, and clean delete-pending, expired, and orphaned objects. Flutter provides exact validation feedback, confirmed deletion, rollback-safe reorder/delete, HEIC fallback rendering, and durable draft resume. | Production image-moderation provider selection and tuning remain an operational integration; the functional local-PostgreSQL media lifecycle is complete. |
| 6 | **P1 — beta gate** | Billing, wallet, subscriptions, and entitlements | Plans, local subscriptions, payments, gifts, and wallet state are now PostgreSQL-backed and restart durable. External settlement and accounting controls remain incomplete. | Add provider integration, webhook idempotency, entitlement enforcement, refunds/reconciliation, double-entry wallet invariants, and accurate admin KPIs. |
| 7 | **P1 — implemented** | Admin control plane | Migrations 059-060, the bearer-authenticated Django console, and native Go/PostgreSQL APIs cover dashboard, gifts, users, moderation/verification, engagement, billing, flags, and SOS. Roles `admin`, `ops_admin`, `trust_safety`, `moderator`, and `analyst` are route-scoped; access refreshes server-side; mutations emit append-only audit events. Database flags poll into Flutter and control gifts, billing, calls, nudges, prompts, voice, circles, rooms, coffee polls, and SOS without an app rebuild. | Keep the executable eight-section gate mandatory. Production deployment still needs SSO/MFA, reviewed operator provisioning, secrets management, and organizational approval matrices; the functional local-PostgreSQL beta gate is complete. |
| 8 | **P1 — production integration implemented; device sign-off pending** | Notification and asynchronous delivery | Migration 057 atomically enqueues domain notifications; migration 061 adds 15-minute provider success/p95 telemetry and enforceable queue thresholds. The BFF now sends directly through FCM HTTP v1 or APNs HTTP/2 with short-lived token auth, high-priority call/nudge payloads, provider message IDs, bounded retries, and invalid-token-only disablement. Flutter requests permission, registers/refreshes real FCM or APNs tokens, unregisters on logout, persists background receipt evidence, and routes background/terminated taps to call or nudge UX. Local PostgreSQL migration, provider contract tests, Android debug build, and the no-traffic queue SLO gate pass. | Supply production FCM/APNs credentials and signed physical Android/iPhone devices, then sign off the 12-case foreground/background/terminated matrix and a production-shaped burst. These are operational release gates; they were not simulated or marked complete. |
| 9 | **P1 — implemented** | QA automation and release regression | Runnable Appium automation is username/password-only and protected by a retired-auth contract ratchet. The Android release profile passed duplicate-username rejection, complete signup/profile completion, and credential login → discovery → durable match → persisted chat restart/resume. The unified native-local release gate passed migration 058 verification, Go tests/compliance, 471 Flutter tests, analyzer error gating, 7 Django tests, the authenticated PostgreSQL API preflight, and the race-enabled reliability smoke gate. | Keep the release gate mandatory as the product grows. Historical evidence documents may retain OTP references, but executable automation cannot reintroduce those assumptions. The 370 existing Flutter catalog/lint findings (including one warning) remain cleanup work, not release-gate failures. |
| 10 | **P2 — implemented local hardening** | Engagement persistence and UI breadth | Quest unlock, gestures, mini activities, trust badges, rooms, prompts, groups, polls, voice, circles, and gifts use the native PostgreSQL runtime. All engagement mutations now coalesce same-key retries; race-enabled tests prove concurrent retry suppression, OpenAPI documents the contract, and a complete backend restart preserved a daily-prompt answer. The `engagement-full` Android profile traverses all nine engagement-hub destinations and passed on `emulator-5554`. | Keep production-scale concurrency/soak and deeper destructive-action UI matrices in rank 11. The functional native-local persistence, retry safety, restart recovery, and UI-breadth gate are complete. |
| 11 | **P2 — local scale implementation complete / production proof pending** | Reliability, idempotency, observability, and load engineering | Route timeout/pool/lock guardrails, shared PostgreSQL idempotency for authenticated critical writes, payload-conflict detection, lease takeover, OpenAPI coverage, migration 058 indexes, migration 063 partitioned retention, 250k-row query-plan gates, Prometheus/Grafana/Alertmanager assets, race tests, two-instance duplicate/reconnect storms, and bounded authenticated burst/soak harnesses are implemented. | Production completion still requires deployed paging/exporters, production-cardinality/skew evidence, a distributed burst and non-shortenable 24-hour soak, rolling-deploy duplicate/reconnect storms, failover/network/provider chaos drills, measured-growth approval for hot-table repartitioning, and signed capacity/SLO evidence. No scale claim is made from local results. |
| 12 | **P3 — implemented locally; production rollout pending** | Level/XP progression | Migration 064 provides an immutable idempotent XP ledger, exact L1-L10 thresholds, source/global caps, cooldowns, decay, safety/risk controls, stable experiments, fraud queue, telemetry, `SKIP LOCKED` projection, transitions, and once-only rewards. Activity workflows emit XP; Flutter exposes the member journey; Django exposes operator policies, experiments, cases, corrections, and freezes. Live PostgreSQL QA proved replay/conflict, L1 -> L2, reward claim, freeze, compensation, and append-only enforcement. | Stage dogfood/5%/25% rollout with production cohort dashboards, real-traffic fraud and safety-threshold review, distributed projection load evidence, and experiment sign-off. The functional native-local product expansion is complete. |

## Recommended execution order

1. Select the billing and push providers; keep the completed admin gate mandatory.
2. Expand device/Appium coverage beyond the completed signup, core-dating, engagement-hub, and admin API journeys into browser/device safety enforcement.
3. Complete the production scale gate: cross-instance durable idempotency, distributed load/soak, and chaos/failover evidence.
4. Stage the completed Level/XP engine only after production fraud, cohort,
   projection-load, and safety stop-threshold sign-off.

## Documentation reconciliation notes

- `scripts/DEVELOPMENT_ROADMAP.md`, `scripts/STATUS_BOARD.md`, and older QA
  documents still describe Supabase and/or mobile OTP. They are historical and
  must not be treated as the current architecture.
- `documents/SIGNUP_WORKFLOW_LOCAL_POSTGRES_ARCHITECTURE.md` is the current
  identity/signup authority.
- `documents/codex/JIRA_STORY_PROGRESS_TRACKER.md` closes the imported
  activity-unlock backlog, but that completion predates the native PostgreSQL
  mandate.
- `documents/NATIVE_POSTGRES_RUNTIME_CONVERSION.md` records the current local
  data-access architecture and restart evidence.
- `documents/CORE_DATING_NATIVE_POSTGRES_REALTIME.md` records the completed
  core dating lifecycle, outbox/WebSocket architecture, and live replay proof.
- `documents/SAFETY_MODERATION_ENFORCEMENT_LOCAL_POSTGRES.md` records the
  completed safety state machines, enforcement boundary, SLA policy, audit
  immutability, and live negative-security proof.
- `documents/codex/completed/PROFILE_MEDIA_LIFECYCLE_REPORT_2026-08-09.md`
  records the completed quota, validation, deletion, retention, cleanup,
  Flutter, migration, and live local-PostgreSQL proof.
- `documents/codex/completed/NOTIFICATION_ASYNC_DELIVERY_REPORT_2026-08-09.md`
  records the completed notification outbox/inbox, worker, preferences,
  realtime client, queue telemetry, migration, and live restart proof.
- `documents/RELIABILITY_SCALE_GUARDRAILS_LOCAL_POSTGRES.md` records the
  implemented local runtime limits, lock order, migration 058, metrics,
  monitoring assets, executable burst gate, runbooks, and explicit production
  scale residuals.
- `documents/codex/completed/RELIABILITY_LOCAL_HARDENING_REPORT_2026-08-09.md`
  records migration 058, runtime/monitoring implementation, complete release
  evidence, and the production-scale work that intentionally remains open.
- `documents/codex/PERSISTENCE_TABLE_BACKLOG_2026-03-21.md` identified the
  original durability gaps. Its local repository/application wiring is now
  implemented; recovery, concurrency, and UI acceptance coverage remain.
- `documents/LEVEL_XP_PROGRESSION_LOCAL_POSTGRES.md` and
  `documents/codex/completed/LEVEL_XP_PROGRESSION_REPORT_2026-08-09.md` record
  the finalized Level/XP rules, migration 064, runtime/UI/operator design, live
  local proof, and explicit production rollout boundary.
