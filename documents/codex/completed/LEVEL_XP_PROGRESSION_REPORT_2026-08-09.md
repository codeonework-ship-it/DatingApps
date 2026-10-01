# Level / XP Progression Completion Report

Date: 2026-08-09  
Priority: P3 — product expansion  
State: Functional local implementation complete; production rollout evidence pending

## Completed

- Finalized the L1-L10 cumulative thresholds, XP source weights, per-source and
  global caps, cooldowns, repeated-action decay, quality/risk multipliers,
  trust gates, and deterministic fraud-review threshold.
- Applied migration 064 to local PostgreSQL with an immutable XP ledger,
  idempotency/source-event uniqueness, catalogs, safety controls, experiments,
  fraud cases, telemetry, reward claims, transition history, projection state,
  and a durable projection outbox.
- Added transactional Go award logic and a bounded `SKIP LOCKED` projection
  worker with stale-lease recovery, retries, and dead-letter handling.
- Connected profile completion, daily prompts/streaks, mini activities, circle
  challenges, and played voice icebreakers to stable XP events.
- Added bearer-authenticated member and RBAC operator APIs with fully modelled
  OpenAPI requests/responses.
- Added a Flutter Level & XP journey with ladder, progress, trust/safety state,
  reward claims, recent XP, refresh, and runtime flag reflection.
- Added a Django operator surface for policies, progression metrics,
  experiments, fraud resolution, audited adjustments, and safety controls.
- Added Go unit/contract tests, Flutter model/widget tests, Django client/view
  tests, and a live local-PostgreSQL end-to-end verifier.

## Live proof

The verifier created a new username/password member and passed:

- L1 zero-state and ten-level catalog;
- exact +100 XP award and asynchronous L1 -> L2 projection;
- same-key replay with one ledger event;
- same-key/different-payload HTTP 409;
- once-only `starter_accent` reward claim;
- immediate progression freeze reflection and rejected award;
- audited -100 compensating entry; and
- database-enforced append-only ledger mutation rejection.

No Docker, Supabase API, PostgREST, phone auth, or email auth was used.

## Production boundary

The functional epic and local rollout controls are complete for the mandated
runtime. Stage order/evidence, bounded review-only fraud tuning, projection-load
automation, metrics, dashboard, alerts and stop ownership are implemented.
General rollout still requires real dogfood/5%/25%/GA cohort evidence,
target-environment load, paging and safety-stop drills. Paid acceleration was
intentionally not added: all levels remain reachable through behavior and no
purchase bypasses trust.
