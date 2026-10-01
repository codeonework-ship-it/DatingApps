# Better date planning — phase 3

Implemented locally in the shared Flutter Android/web app and Go/PostgreSQL backend. This phase lets two people shape a date around their time, spending comfort and practical needs. Production rollout is not complete.

## Member experience

- **Shared time windows:** the existing optional dating-rhythm availability supplies actual intersections only when both members opted in. The redesigned planning sheet explains empty and failed-load states, offers refresh and availability settings, and always allows a manual suggestion. Choosing a window preserves its exact start/end, including 90-minute windows. Dates display in the device's local time with its time-zone name.
- **Flexible duration:** 30, 60, 90, 120 and 180-minute choices supplement the exact selected window. Extending beyond the shared window or editing the date/time labels the proposal as a manual suggestion and removes the shared-window claim. Existing longer or irregular counterproposal windows are preserved until edited.
- **Budget:** decide together, keep it free, modest, or a little treat. These are conversation preferences, not price quotes or an agreement about who pays. Exact prices/currencies and venue booking are outside this change.
- **Atmosphere:** up to three optional settings — quiet conversation, relaxed, lively, outdoors and indoors. These are alternatives the pair might enjoy, not certified venue characteristics.
- **Accessibility:** optional step-free access, accessible toilet, seating, low background noise, nearby public transport and video captions. All start unselected. Copy explains that sending shares the choices with the match on this plan, without requiring a diagnosis. They are excluded from public profiles and trusted-contact updates. Members still need to confirm facilities with the venue/video service.
- **Shared decisions:** the plan card, acceptance sheet and own plan history show budget and comfort choices. A counterproposal stays a proposal until the other member accepts that exact revision. A failed save retains the draft; a counterproposal conflict offers an explicit reload that discards edits.

The existing conversation unlock requirement remains. The live local QA conversation was locked, so its plan CTA correctly remained hidden. Full editor and acceptance behavior was verified using widget fixtures rather than changing that member's access or sending a live plan.

## Backend and privacy

Migration `101_date_plan_preferences.sql` adds bounded, allowlisted atmosphere and accessibility arrays to the existing date-plan aggregate. Existing plans default to empty choices. New proposals and counterproposals persist the fields in their existing transactions. Missing new fields on an older client's counterproposal preserve the current choices; explicit empty arrays clear them for the next review.

Proposals may carry a `shared_window` source. The proposed time must fit it, and the server rechecks both members' current opt-in and actual overlapping availability inside the write transaction. Revoked or changed availability returns `409 SHARED_AVAILABILITY_CHANGED`, with no partial plan write. Manual proposals do not use availability as a requirement. The raw schedules/source window are not persisted on the plan.

Connection reads now use a consistent PostgreSQL snapshot and `private, no-store`. The client scopes its connection stream to the signed-in member. New proposals also recheck the active, unblocked relationship. Existing date-plan/intentional-dating flags, version checks and idempotency middleware remain in force.

Existing database triggers publish changed field names through the transactional event outbox. Accessibility values are not inserted into event payloads, push payloads or trusted-contact feeds. Account export includes shared plan preferences. Erasure clears the shared preference fields when either participant is erased; existing legal-hold rules still apply. Choice values remain available to the two participants in plan history until changed or erased; this is not an ephemeral message feature.

The counterproposal notification key now includes the numeric revision correctly, so repeated rounds of suggestions produce distinct notifications. Billing code and separately owned payment work were not changed.

OpenAPI documents new fields, optionality, legacy behavior and stale-availability conflicts on proposal/counterproposal requests.

## Verification

- **31 backend tests passed**, zero failed or skipped, with local PostgreSQL. Includes input bounds, 90-minute persistence, consent revocation, exact overlap checks, outsider denial, counterproposal versioning, legacy field preservation, explicit clearing, repeated notification delivery, privacy of fan-out/events, erasure, existing plan lifecycle and OpenAPI checks.
- **56 Flutter tests passed**, including nine new planning tests. Covers default-empty accessibility, shared window payloads, manual fallback, duration changes, retained drafts after conflicts, counterproposal prefill, atmosphere limits, and planning/acceptance layouts at 390, 768 and 1440 pixels with 2× text.
- Scoped analyzer: zero errors and warnings; informational style lints remain.
- Backend, web release and Android debug builds completed. Local backend restarted and website reloaded; Android installed/launched on `emulator-5556`.
- Logs and machine-readable acceptance: `qa/results/better-date-planning/`.

Physical-device interaction, live two-person/provider acceptance, reviewed translations and production deployment remain release work. Verified venue suggestions, price data and venue accessibility sourcing remain a separate integration task; no facilities are invented or certified by this feature.
