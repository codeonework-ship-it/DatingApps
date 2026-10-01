# Open Chapters — implementation and local acceptance

Implemented locally on 1 October 2026. The publishing foundation and dependent blogging flows are implemented on web and Android. Production launch gates are listed below; this is not a production deployment.

## Product contract

Members write a chapter about their life, with an optional closing question and up to six photos. There are no public like counts, response scores or posting streaks. Drafting, reading and publishing use the same Flutter screens on Android and the web.

- **Only me:** the default for a new draft. Neither a friend nor a match can read it.
- **Friends:** accepted Connect friendships only. A match, group membership or pending friend request does not qualify.
- **Connect community:** eligible signed-in dating members. Both reader and author require a complete profile and two approved profile photos. This does not mean public-web visibility.
- Both parties must have an active adult dating account. Blocks in either direction, suspension, deactivation, disabled credentials and account deletion revoke new reads. Introducer-only accounts are outside this first release.
- Title: 100 characters; body: 8,000; at most 100 active chapters per member. Unicode limits are enforced by the API/database.
- JPEG/PNG photos: 300–4096 pixels per dimension, 10 MB each, six per post, 100 MB stored per member. Alt text is required. Images are decoded and re-encoded to remove metadata before moderation and storage.
- A photo requires approval before attachment. Provider errors and review-required/rejected results do not publish it. Local validation checks file structure; it is not a production content classifier.
- Preview does not save or publish. Publishing requires an explicit audience confirmation. Photo changes on a published post require first saving it as Only me.
- Failed saves retain the editor's text. The saved-version sheet lets the member inspect the server copy, adopt it, or retain their edits for an explicit subsequent save against the current version.

## Entry points

- Today on web and Android: **Blog · Open Chapters** is the first feature card, directly below the Today header.

- Web after sign-in: **Blog** in the main sidebar or All features → Blog; `/app/#/blog`.
- Android: **Engage → Blog · Open Chapters** or Settings → Blog · Open Chapters.
- Command center: **Moderation → Blog Moderation**; `/moderation/blog/`.
- Another member's profile: Read their chapters, with Community and Friends collections filtered to that author.
- Reader: edit/delete for the author; report/block for another reader.

## Architecture

Migration `backend/scripts/105_member_blogging.sql` adds `matching.blog_posts` and `matching.blog_photos`. The local migration was applied without running the seed/migration runner over the existing database.

`mobile-bff.blog` owns these aggregates. Each write serializes on the author, checks the post's expected version, and commits state and metadata-only outbox events in one database transaction. Creation uses a stable client UUID. Exact lost-success retries return the authoritative representation; stale competing edits return 409. Deleted UUIDs remain tombstones and cannot be reused.

Photo upload uses a stable attachment UUID and normalized content digest. Random storage object keys prevent a competing upload from replacing committed bytes. Multipart uploads bypass the shared HTTP replay cache; domain-level deduplication handles replay. A commit with an uncertain outcome retains the object for reconciliation rather than deleting potentially committed media.

Feed pagination uses `(created_at, id)` and a repeatable-read transaction. One shared SQL visibility predicate governs list, detail and photo-byte reads. Post responses contain approved photo IDs and descriptions, never storage paths or public image URLs. The authenticated photo endpoint rechecks the current audience and returns private, no-store bytes. Already viewed/downloaded content cannot be recalled from a recipient.

Export includes the member's own posts and photo metadata. Account erasure collects storage references before deleting the post/photo rows and uses the existing durable erasure cleanup. Individual deletion hides content immediately; the media lifecycle worker removes tombstoned objects and scrubs post text, respecting existing legal holds. The cleanup reference query also protects active blog photos from orphan cleanup. Its pre-existing reserved SQL alias was corrected during testing.

Reporting derives reporter and subject from the session and permission-checked content. The completed implementation uses a dedicated Chapter review queue with immutable report snapshots, retained photo evidence, content-specific removal/restoration and private member appeals. Member-level suspension/ban controls also hide affected chapters.

All blog routes use the existing `intentional_dating_enabled` policy. Owner collection reads and removal stay available at the API during a feature pause. The production release exclusion remains in force.

## Publishing-foundation validation (earlier stage)

Evidence is under `qa/results/blogging-phase1/`.

- 25 backend tests passed, including seven blog tests plus API-contract, profile-story, feature mapping, account export and erasure checks. Database tests ran against local PostgreSQL, using isolated disposable member fixtures.
- 22 Flutter tests passed, including six blogging tests and existing profile-story/First Chapter regressions.
- Blog tests cover audience access, block/unfriend revocation, ineligible profiles, anonymous reads, pagination, concurrent edits, retry deduplication, deletion tombstones, private outbox payloads, photo metadata stripping, moderation outage, public-media bypass denial, cleanup, export, legal holds, erasure and report actor binding.
- Widget tests cover private-by-default drafting, preview without publication, publication confirmation, retained edits on conflict, deliberate saved-version recovery, account-switch isolation, audience filters and a 320px layout at 1.6× text scale.
- Targeted Flutter analysis found no errors or warnings. Informational style lints remain in the touched screen set.
- Web and Android build/device results are recorded in the accompanying build logs and runtime check notes.

## Completed dependent stages

1. **Private responses:** chapter-specific invitation, private inbox, author accept/decline, block/report and withdrawal. Five new responses per rolling 24 hours, one per author, a bounded incoming queue and ten contributions per 24 hours. Responses and contributions also count toward the existing daily message allowance. Exact successful retries do not spend allowance again. No response creates a match or unlocks unrestricted chat.
2. **Reciprocal exchanges:** one contribution per participant; the partner's words remain hidden until both submit. Concurrent submissions update separate slots safely. Either person can withdraw. Source privacy, blocks and account eligibility are rechecked.
3. **Story-to-date bridge:** revealed exchanges between existing eligible matches open the existing plan composer with shared windows, budget, atmosphere and accessibility preferences. The service validates the exchange and records attribution atomically. Private words are not automatically copied into a plan. First Chapter Studio is accessible for existing matched pairs.
4. **Permissioned public sharing:** a community chapter can produce a separately approved exact excerpt and explicitly selected photos. Friends/private chapters cannot silently become public. Anonymous visitors receive only title, excerpt, joint flag and selected photo metadata/bytes. Links use `/story.html?id=…`, with no tracking, profile link or source IDs. Editing/hiding/deleting the source, account restrictions, moderation and consent withdrawal invalidate new reads. External saved copies cannot be recalled.
5. **Joint journal pages:** both participants preview the same frozen contributions and separately approve publication. The link remains unavailable with one approval; either person can revoke it. No photos are automatically added to a joint page. Words themselves can identify people, which the preview explicitly explains.
6. **Trust operations:** Django `/moderation/blog/` provides report/appeal queues, preserved evidence, case versions, member-facing reasons, protected photos, 24-hour review deadlines and overdue counts. Only admin/moderator/trust-safety roles may access evidence. Content-specific removals take effect immediately. All outstanding removal cases must approve restoration before content becomes visible. Removed public links require fresh publication/consent. Member notices never expose reporter identities.
7. **Lifecycle and measurement:** exports contain own contributions; deletion removes exchanges/publications; evidence objects remain protected while cases require them. Resolved evidence expires after 90 days unless legally held. Durable object-deletion retries support local and object-store failures. Withdrawn prose is scrubbed by the media worker while command/quota metadata remains. Aggregate metrics cover published posts, responses, accepted/revealed exchanges, attributed plans and accepted plans. These are operational counts, not causal evidence or claims that dates occurred.

Migration `106_blog_connections_and_trust.sql` owns the new response, publication and moderation aggregates under `mobile-bff.blog`. Writes emit metadata-only transactional events. The existing intentional-dating release gate remains; reports, appeals and withdrawal remain available during a runtime feature pause. Billing pricing/payment flows are unchanged; only the shared message-usage counter includes blogging activity.

## Completion validation

Evidence: `qa/results/blogging-completion/summary.json` and adjacent logs/screenshots.

- 32 backend top-level tests passed against PostgreSQL, including 17 blogging tests plus API contract, date-plan, feature-gate and related regression checks.
- 49 Flutter tests passed across blogging, First Chapter, profile stories and date planning. New coverage includes explicit sharing consent, consent reset after editing, retained failed submissions, stable retry IDs, hidden partner text, account-switch isolation and 320px large-text layouts.
- 15 Django tests passed, covering new moderation views and existing API-client behavior. Evidence is escaped, private/no-store, role-protected and CSRF-protected.
- Five public-page browser tests passed at 320px and 1440px, including literal HTML text, withdrawal refresh, report retry and malformed links. These browser tests use intercepted fixtures; backend privacy/consent tests use the database.
- Targeted Flutter analysis: no errors or warnings; informational style lints remain. Release web and debug Android builds passed. Android was installed with replacement on emulator-5556, relaunched and verified as the resumed activity.
- Local web bundle and BFF reloaded. Signed-in browser verification confirmed blog home, private responses, shared links and review notices. Anonymous private exchange requests return 401; missing public copies return 404; the command center redirects anonymous visitors to sign-in.

## Production gates still open

Production text/media moderation acceptance and abuse-limit tuning; named moderation staff and escalation ownership; approval of the 90-day evidence policy; translated copy and accessibility review with representative assistive technology; physical-device acceptance; production monitoring/soak and deployment approval. These operational and external acceptances are not implied by passing local tests. No production link or real member's content was published during verification.
