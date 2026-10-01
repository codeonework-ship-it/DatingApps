# Focused city pilot — local delivery

Status: implemented, tested and rebuilt locally on 30 September 2026. No city or operating owners have been selected, no pilot has been launched, and `city_pilot_enabled` remains false. No production deployment or real-world outcome claim is included.

## Member experience

Android and web: **Explore → The City Pilot**. Members see an honest coming-soon state until a pilot for their profile city is configured and opens. Joining requires a completed, active dating profile, accepted terms, matching city/country and explicit `city-pilot-v1` measurement consent. Friend-only introducer accounts cannot enter the dating pilot.

Participation is optional. A member can leave while recruitment is closed, the pilot is paused, or its runtime flag is off. Leaving cancels their pilot bookings, removes their hosted-experience feedback and excludes their pairs from current pilot aggregates. They cannot rejoin the same pilot. Their ordinary matches and conversations remain. Previously viewed aggregate results cannot be un-seen; the UI explains this.

Hosted experiences are separately chosen: free, with named hosts, a public venue, accessibility information, member-facing safety contact and explicit safety acknowledgement. No attendee directory is exposed. Members can cancel a booking and, for fourteen days after the experience, optionally report attendance and whether it was worthwhile. Individual feedback is never returned to operators or other members by the pilot APIs.

## Command center and launch controls

Django **City Pilot** at `/city-pilot/` uses the Go BFF and existing operator authentication/audit. One active pilot at a time, with city, country, accountable operating owner, safety owner, future recruitment dates, cohort capacity, minimum sample and predeclared outcome targets. Draft configuration freezes once recruitment starts. Stage updates require the current version and a review note.

Stages: draft → recruiting → measuring → experiences; paused and completed are explicit operator decisions. A paused pilot can resume observation, then undergo the experience review again. Operations/admin can configure; analysts can read aggregate results; trust/safety can inspect and pause or cancel, but cannot open recruitment or approve experiences.

Hosted tests require the feature flag, operator safety attestation, a completed 28-day follow-up period after recruitment closes, at least the declared number of mature pairs (minimum 20), declared conversation/plan/date thresholds and no pending moderation reports involving current cohort members. Passing the numerical gate never automatically publishes an experience. Host vetting, staffing and accessibility confirmation are operator attestations; software does not independently certify them.

At most three free experience tests, each 2–30 participants, up to six hours, scheduled within sixty days of creation. Bookings serialize on pilot and event rows to prevent overbooking; repeating an existing booking succeeds even when full. Existing generic growth-event listing/registration cannot expose or book a pilot experience. Pausing/completing cancels upcoming experiences and atomically enqueues cancellation notices through the existing notification outbox. Delivery still depends on member preferences and configured providers.

## Measurement contract

Only matches created during the recruitment window, after **both** members opted in, count. Withdrawn members are excluded. Current canonical records are queried in a repeatable-read snapshot for the command-center scorecard, with no individual drilldown or arbitrary slicing API.

- Seven-day denominator: pairs with seven completed days of follow-up.
- Conversation outcome: at least three non-deleted messages from each participant in those first seven days. No message text is read. This is an activity proxy, not proof of a useful conversation.
- Twenty-eight-day denominator: pairs with twenty-eight completed days of follow-up.
- Plan outcome: at least one accepted date plan during those twenty-eight days, using acceptance history so later cancellation does not erase acceptance.
- Date outcome: both participants voluntarily said a date happened within twenty-eight days. Missing answers remain unknown, not failed dates. Feedback coverage is reported separately.
- Hosted outcomes: active non-cancelled-event registrations, optional responses, self-reported attendance and worthwhile responses. These are counts, not a claim of independently verified attendance.

Counts 1–4 display as `<5`. Small-cell suppression limits disclosure but is not a formal anonymization guarantee. No private notes, would-meet-again answers, safety answers or message bodies enter pilot analytics. The pilot is observational. Its sample minimum is an operational floor, not statistical power or causal evidence. No city/cohort results have been collected.

## Architecture and data lifecycle

Migration `103_city_pilot.sql` adds pilot configuration, consent membership, experience linkage and private feedback under `growth`. Hosted tests reuse existing free events and registrations. New tables have stable aggregate identifiers, source registration and ownership records; mutations emit field-name-only canonical events in their database transaction. Existing operator audit captures administrative requests.

Authoritative reload, version checks, unique membership/booking/feedback records and transaction locks handle retries and concurrent changes. Per-member pilot data is included in account export and account erasure. Pilot withdrawal deletes optional hosted feedback and excludes the member from live measurement. A pilot-specific time-based retention policy and scheduled purge still require an approved operating policy before production launch; the implementation does not invent one or claim that account deletion is a retention schedule.

Runtime disable and release exclusion prevent new joins and reservations. Readback, leaving and cancelling remain available. New pilot controls are independent of separately owned billing.

## Validation and runtime

Evidence: `qa/results/city-pilot/`.

- Eight dedicated Go tests against local PostgreSQL: consent, eligibility, idempotency, fixed measurement windows, both-member inclusion, withdrawal, private feedback, event capacity concurrency, legacy booking bypass, role boundaries, stage gates and immutable live targets.
- Related account export, deferred feature flag, security-role and growth routing regression checks passed.
- Seven new Django tests; all 47 command-center tests passed, including authenticated access, CSRF, escaped content, read-only operator rendering, UTC payloads and gate-error display.
- Twenty Flutter tests across pilot and chat/navigation: consent starts unchecked, paused withdrawal, offline retry, cancelled-event rendering, large text, responsive chat, message-draft recovery, search/unread filters and the Matches/Conversations separation.
- Targeted Flutter analysis: no errors or warnings; informational style lints remain. Web release and Android debug builds succeeded; Android installed and launched on emulator-5556.
- Browser verified the new Matches overview, switching to Conversations and back through Matches navigation, and the city-pilot coming-soon screen against the running local API.
- Database checked after fixtures: zero pilots, flag false. No test pilot or registrations left active.

Launch remains dependent on a chosen city/country, named owners, approved thresholds and retention policy, real cohort recruitment, measured outcomes, provider/device acceptance and staffed physical-event operations. The First Chapter strategy is a separate proposal in [the product decision memo](FIRST_CHAPTER_PRODUCT_STRATEGY_2026-09-30.md).
