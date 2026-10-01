# Pending epics audit — 27 September 2026

## Finding

The repository still has eight actionable epic groups. They are consolidated
from the canonical `PENDING_FEATURE_BACKLOG.md`; the 53 PEN rows are stories,
acceptance gaps and deferred proposals rather than 53 separate epics.

The imported activity-unlock Epics 1–7 are complete according to the current
tracker and completion reports. Historical documents that say an individual
activity-unlock story is pending are superseded by those completion reports.

## Current pending epics

| Rank | Epic | Priority | Backlog mapping | Current state / next completion boundary |
|---:|---|---|---|---|
| 1 | Release contracts and governance | P0 | PEN-14–17, PEN-25–27, PEN-46 | **Governance baseline completed 2026-09-27.** The versioned contract approves public-profile/eligibility/auth-age rules, excludes economy/quests from the first release, defines accountable roles and fails production closed at `NO_GO`. Remaining launch work is named human approval, exclusion enforcement and target-environment evidence rather than unresolved product policy. |
| 2 | Privacy, safety and production trust operations | P0/P1 | PEN-05–08, PEN-20, PEN-37–39 | **Local product and architecture controls hardened 2026-09-27.** Current-schema fail-closed export, private-media erasure, active-socket revocation, durable SOS contact delivery, truthful safety notifications, queue metrics, retention policy and a production trust gate are implemented. Production remains `NO_GO` until named coverage, paging rehearsal, deployed SSO/MFA, provider preflights, backup/retention jobs and target-environment evidence exist. |
| 3 | Calls, identity, voice and notification providers | P0/P1 | PEN-03–04, PEN-09, PEN-35–36 | **Provider boundaries completed locally 2026-09-27.** Calls use short-lived room/member-bound JWTs; identity bytes reach a fail-closed decision adapter; voice is moderated before delivery and plays through signed private URLs; direct FCM/APNs adapters and token cleanup exist. Production remains `NO_GO` until credentials, paired calls, labelled identity/voice corpora and the signed 12-case Android/iOS push matrix are recorded. |
| 4 | Billing and coin-economy completion | P0 when money is enabled; P2 expansion | PEN-01–02, PEN-10–13 | **Billing implementation is locally complete through disputes and ledger reconciliation; separately owned production acceptance remains.** Stripe/sandbox checkout, webhook dedupe, renewals, plan/card changes, refunds, chargebacks, coin settlement and entitlements pass locally. Production remains `NO_GO` until Stripe test-mode evidence, provider balance/payout/bank reconciliation and signed INR pricing approval exist. Optional reward/drop/fraud loops remain deferred while disabled. |
| 5 | Correctness, idempotency and recovery | P0/P1 | PEN-18–19, PEN-21–24, PEN-40–43 | Local correctness controls and guarded evidence harnesses are complete. Production remains `NO_GO` pending deployed observability, target backup/failover, capacity, 24-hour soak and chaos evidence. |
| 6 | Product-rule and complete-screen acceptance | P1 | PEN-28–34, PEN-44 | **Rules and local automation completed 2026-09-27.** The versioned contract approves activity, discovery, chat, prompt/nudge, group/friend and KPI semantics. All 55 Flutter screens have responsive/theme/large-text semantics coverage; native background, process-death and font-scale cases are present; friendship now requires recipient consent. Production remains `NO_GO` until the six-row representative physical-device/OS/network matrix passes on the signed build. |
| 7 | Progression production rollout | P1 when XP is exposed | PEN-45 | **Local rollout controls completed 2026-09-27.** Stage order and evidence are database-enforced; fraud tuning is bounded and review-only; a 2,000-event four-worker projection gate passed with zero mismatches/dead letters; production metrics, dashboard, owner-labelled alerts and stop ownership exist. Audit follow-up (migration 086): the nonempty-exposed-cohort promotion rule is now enforced by the API (409 `PROGRESSION_ROLLOUT_COHORT_REQUIRED`) and a DB trigger, inserts must start at draft, and stage history is append-only, with Postgres-backed tests. Production remains `NO_GO` pending dogfood→5%→25%→GA real-cohort evidence, target load, paging and safety-stop drills. |
| 8 | Deferred growth portfolio | P2 / deferred | PEN-47–53 | Admirer gifts, richer gift economy, paid XP mechanics, advanced recommendations/fraud graph, events/referrals/partnerships, social imports/history and full support ticketing require separate product approval. |

## Recently closed or narrowed

- Epic 4 (local): coin refunds/chargebacks take coins back, freezing the
  wallet with recorded debt when spent; a lost dispute ends the subscription
  immediately and stops renewal; operators can reverse gifts; paid-gift and
  coin-checkout velocity limits; zero-default wallets; and complete
  coin-liability reconciliation with idempotent historical provenance repair
  (migrations 084 and 090).
- Epic 5 (local): write-ahead XP award intents with an offline spool; money
  aggregates in the ownership registry checked by `/readyz`; behavioural tests
  for flag middleware, expired cursors and uncertain outcomes; the money storm
  proves one debit per key across two instances.
- Epic 6 (local): durable DAU/MAU (migration 087); accessibility guideline
  checks on every screen with a shrink-only allowlist; web shell tests.
- Epic 8: support ticketing held at foundation and switched off (migration 088)
  until accepted; deferred growth flags default off when their row is missing.

- Epic 1 exclusions are now enforced, not only documented: in production-like
  environments billing/coin purchase, gifts, quests (including the
  `unlock-requirements` alias), calls, voice, identity verification submit and
  XP routes return `FEATURE_EXCLUDED_FROM_RELEASE`; `/config/flags` reports them
  off; non-local clients default them off; web destinations respect flags. The
  provider-less coin self-credit and plan activation paths are local-only. The
  release governance gate runs in CI.
- Epic 2: legal holds and the trust retention worker (migration 081), SOS stale
  delivery reclaim, provider requirement and paging rules, erasure of SOS data
  and audit-history copies, operator removal through erasure, and the PEN-06
  operator-assisted recovery journey (migration 082) are implemented locally.
  Remaining Epic 2 work is a direct SMS/voice SOS vendor, backup aging and the
  human/production evidence already listed.
- The browser app is locked to the Daylight theme by product decision
  (`webThemeLockedProvider`); member presets are a mobile choice.

- The release contract is now machine-readable and part of release regression;
  signup, recovery and password change share bcrypt's 8–72 UTF-8 byte limit,
  and signup requires explicit gender selection. Production remains `NO_GO`
  until named owners and target-environment gates are complete.
- Privacy and trust operations now have a versioned, machine-checked contract.
  The local runtime closes PEN-08 and PEN-20 and narrows PEN-05/PEN-07; PEN-37–39
  remain production acceptance work because credentials, deployed controls and
  named people cannot be supplied by repository code.
- Browser and Android theme infrastructure is implemented; the Star Wars preset
  adds an account-saved dark palette and a deterministic in-app space scene.
- Browser checkout is implemented at the app boundary; provider and settlement
  acceptance remain in the separately owned billing epic.
- Live call rooms narrowed PEN-03 from “no media path” to provider/security and
  physical-device lifecycle acceptance.
- Private identity document/selfie upload narrowed PEN-04 to provider decision,
  reviewer access and production retention.
- Voice recording/private upload narrowed PEN-09 to playback, moderation,
  server policy and physical-device acceptance.

## Recommended dependency order

1. Resolve Epic 1 contracts and owners.
2. Run Epics 2, 3 and 4 in parallel against those approved contracts.
3. Apply Epic 5 correctness and recovery gates to every enabled integration.
4. Complete Epic 6 and Epic 7 acceptance before production exposure.
5. Select Epic 8 items individually after the release gates pass.

This audit does not classify missing production credentials or unsigned policy
decisions as completed software. It also does not reopen the completed
activity-unlock epic set.
