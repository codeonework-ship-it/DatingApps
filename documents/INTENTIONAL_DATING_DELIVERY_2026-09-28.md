# Intentional dating — 28 September 2026

The six requested experiences extend the existing Flutter Android/web app and PostgreSQL-backed mobile BFF. This delivery is local, not a production launch.

## Member experience

| Experience | Delivered behavior |
|---|---|
| Fits your week | Settings, discovery and friends link to **Your dating rhythm**. Members choose relationship intent, conversation pace, first-date activities and optional broad availability. Curated introductions receive a modest compatibility boost and explain actual shared preferences. Only future time intersections of at least an hour appear, and only when both members opted in. The full schedule is never returned to the other person. |
| A shared chemistry moment | A chat card opens three optional activities: build a Sunday, choose an adventure or choose a first date. A member's choice stays sealed until both answer. There is no score, visible countdown or new conversation gate. One open activity per match and three new activities per match in a rolling 24 hours limit repeated requests. |
| A plan both people shape | Existing plan cards offer shared time windows, broad area and budget choices, plus **Suggest a change**. Counterproposals keep the original participants and sharing choices, increment a version and require the other person's explicit acceptance. Stale or self-acceptance is rejected. |
| A private second yes | The existing private debrief includes separate, default-off permission to share mutual interest. Only two explicit consents plus two positive answers reveal a mutual second yes. Personal safety answers and notes are never included in this reveal. The reporting action remains independently accessible. |
| Dating at your pace | Members can share a temporary slow-replies status with existing matches, pause or resume introductions, and close a conversation through a considerate confirmation. Existing chat remains available during a discovery pause. There is no public response score. |
| Introductions with permission | Both people must opt in before a friend can introduce them. The preview includes name/age, with separate default-off photo and city choices. Consent is rechecked on read and acceptance. The introducer sees a receipt, with no match/decline outcome or match ID. Acceptance also rechecks publication, account status, expiry, friendship, blocks and preference compatibility. |

## Privacy and correctness

- Preferences belong to the authenticated account and use optimistic versions. Conflicting saves preserve the local draft and offer **Reload saved choices**.
- Availability is expressed in the device's local time and stored in UTC. Windows expire automatically; disabling sharing deletes saved windows. The existing five-minute worker removes expired windows. A slow-replies status clears after seven days.
- Chemistry mutations lock the active match. Client-generated UUIDs make starting a moment safe to retry; submitted answers are immutable and identical retries are accepted. Blocked, unmatched and inactive participants cannot access the feature.
- Account exports contain the member's preferences and their own chemistry answers. Foreign keys connect the new rows to existing account erasure. Generic domain events contain field names, not answers or availability values.
- The existing transactional event outbox and aggregate ownership registry cover the new tables. The visible conversation reconciles every 20 seconds and refreshes plans when their revision changes; it does not rely solely on a push arriving.
- Superseded on 29 September: migration 099 replaces automatic date-plan friend/group sharing with explicit per-plan trusted contacts. See [Real life delivery](REAL_LIFE_DATING_DELIVERY_2026-09-29.md). Introduction outcomes and second-yes feedback remain private.

## Implementation and rollout

Migration: `backend/scripts/098_intentional_dating.sql`, also registered in the local migration runner. API contracts are in `backend/internal/platform/docs/openapi.yaml`.

New endpoints:

- `GET/PUT /v1/account/{userID}/dating-preferences`
- `GET /v1/matches/{matchID}/connection`
- `POST /v1/matches/{matchID}/moments`
- `POST /v1/matches/{matchID}/moments/{momentID}/answer`
- `POST /v1/matches/{matchID}/plans/{planID}/counter`

Existing plan decisions carry `expected_version`; debriefs accept `share_mutual_interest`. The optional `intentional_dating_enabled` flag is enabled locally and excluded by default in production-like environments. Counterproposals and opting into second-yes sharing also check it. Baseline privacy enforcement for friend introductions applies regardless of that switch. Billing was not changed.

## Verification

- 24 targeted Go tests pass with PostgreSQL enabled and none skipped. They cover consent withdrawal, availability expiry, versions, sealed chemistry answers, retries, blocks, counterproposals, private debrief projection, curated discovery and friend introductions.
- 104 targeted Flutter tests pass across messaging, matching, plans, friends, graduation, themes, runtime configuration and the new features. After the final rollout-flag wiring, all 23 affected plan/friend/chemistry/graduation tests pass again.
- New widget coverage includes 320, 390 and 1440 pixel widths with 1.5× text, private defaults, availability deletion, save failure recovery, sealed/revealed answers and versioned counterproposals.
- OpenAPI route/semantic checks and release-exclusion configuration checks pass.
- Scoped Flutter analysis reports no errors or warnings; existing informational style lints remain.
- Release web and Android debug builds succeed. The APK was installed and launched on emulator-5556.

Four browser checks pass: two new dating flows and two existing chat regressions, each at 390 and 1440 pixel widths. The new flow verifies private preference defaults, successful save, a sealed answer and the simultaneous reveal after the partner answers. Browser acceptance and screenshots are recorded under `qa/results/intentional-dating/`. Browser feature mutations are intercepted with isolated fixtures after a real local QA login; no real member is messaged or introduced.

## Remaining production acceptance

Physical-device, offline/background/process-death, load/soak and production notification acceptance remain release work. New wording is English and still needs the existing translation/review process. Matching impact is a product hypothesis, not a measured outcome. No production deployment, billing rollout or provider activation is claimed.

[Machine-readable local acceptance](../qa/results/intentional-dating/acceptance.json) · [Mobile chemistry reveal](../qa/results/intentional-dating/revealed-390.png) · [Desktop chemistry reveal](../qa/results/intentional-dating/revealed-1440.png)
