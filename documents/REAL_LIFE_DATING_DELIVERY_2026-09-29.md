# Real life dating — first implementation slice

The approved direction is **Good dates. At your pace.** This slice makes the existing intentional-dating work the main introduction journey and fixes automatic date-plan sharing. It is implemented in the shared Flutter Android/web app and Go/PostgreSQL backend, and delivered locally.

## What members can use

- **Today** replaces the swipe deck as the initial discovery view when both intentional-dating and curated-set flags are enabled. A finite set of real profiles shows their story, genuine shared preferences and a possible first-date activity. Browsing remains reachable through **Explore profiles**, with a return to Today.
- **Set your rhythm** is prominent. Activity filters use the server-provided intersection of both members’ choices. Availability only contributes overlap when both opted in; no full schedule is returned. These suggestions are starting points, not claims of compatibility or confirmed plans.
- **Discovery preferences stay connected.** Manual filters travel to the curated endpoint. Saved profile preferences, trust changes, pause/resume and successful likes refresh Today. A curated candidate outside the browsing deck’s first page can still open the existing like/chat flow. Quota failures and failed likes do not show a success message.
- **Real life** is the default palette: warm ivory, forest and apricot, with a deep forest evening variant on Android. The browser retains its existing light-mode policy with the new palette. Saved named mobile themes remain available. The brand mark now follows the active palette.
- **Plan sharing starts off.** A member opens **Choose who gets your updates**, selects up to ten eligible trusted friends, reviews the disclosure preview and explicitly saves. No friends or groups receive a plan merely because of a friendship or group membership. Each date participant manages their own choices.
- **Consent can be withdrawn.** Deselecting a contact removes their plan-feed/in-app notification copies and suppresses queued notifications. Own plan history exposes sharing controls, including closed plans; the existing list API is bounded and this client loads the latest 100 plans. Messages and private date feedback are excluded from sharing.

Empty, loading, paused and failed-load states have usable next actions. The local QA member currently has no eligible candidates, so live-browser checks exercised the empty state; populated cards, activity filtering and large-text layouts were checked with widget fixtures.

## Backend and privacy contract

Migration `099_date_plan_explicit_sharing.sql` adds per-member, per-plan contact choices with optimistic versions. Both participants’ writes serialize on the plan row. An invalid, blocked, inactive, non-friend or date-participant recipient rejects the whole update. Missing versions and stale saves are rejected. Reading sharing exposes only the caller’s choices.

`GET/POST /v1/matches/{matchID}/plans/{planID}/sharing` is covered by the existing date-plan feature flag, authentication and idempotency policy. OpenAPI documents both operations. Legacy `group_ids` no longer confer access, and older automatic shares are withdrawn by the migration. Reapplying the migration preserves explicitly consented shares.

Sharing changes publish `date_plan.sharing_changed` through the existing transactional domain-event outbox under the date-plan aggregate. Events contain counts/version, not contact lists. The notification worker rechecks consent before delivery, and in-app insertion serializes against withdrawal. Already delivered or in-flight device pushes cannot be recalled; the preview explains this limit. Missed-check-in/help updates only go to selected contacts and are not a replacement for emergency services.

Account exports include the member’s own sharing record. Owner/plan deletion cascades to that record. Billing services were not changed.

## Local verification

- 28 targeted Go tests passed with PostgreSQL enabled, none skipped: private defaults, explicit sharing, recipient rejection, separate member choices, stale saves, withdrawal, blocking, notification delivery eligibility, current shared-activity data, existing plan lifecycle/chemistry/curation tests and OpenAPI contracts.
- 45 targeted Flutter tests passed across intentional dating, plans, discovery and themes. Following the final history/preferences wiring, all 26 affected tests passed again.
- New layout tests cover 390, 768 and 1440 pixels at 2× text, real activity filtering, error/paused/empty states and opening the selected introduction. Sharing tests cover default-off checkboxes, the exact versioned save payload, disclosure preview and retaining choices after a conflict.
- Scoped analysis has no errors or warnings; informational style lints remain.
- The local browser was checked at 390×844 and 1440×1000 for Today, rhythm navigation, Explore and return navigation, and the plan entry point.

Build/install and final local browser status are recorded in [acceptance.json](../qa/results/real-life-dating/acceptance.json). Supporting logs are under `qa/results/real-life-dating/`.

## Next slices and release work

The existing optional chemistry activity, collaborative plans and private second yes remain available. Profile stories and private voice introductions with transcripts are now implemented locally in [phase 2](PROFILE_STORIES_VOICE_DELIVERY_2026-09-29.md). Friend-introducer participation without a dating profile is now implemented locally with scoped consent in [phase 4](INTRODUCER_EXPERIENCE_DELIVERY_2026-09-29.md). Accessible place suggestions and a city-sized pilot before hosted experiences remain planned.

Production rollout is not complete. Physical-device, offline/background/process-death, provider delivery, load/soak and translation acceptance remain. Revised privacy copy uses an English fallback across locales until reviewed translations are ready. History pagination beyond the existing 100-plan bound needs extension for long-lived accounts. The benefit to real dating outcomes is a hypothesis to measure, not an established result.
