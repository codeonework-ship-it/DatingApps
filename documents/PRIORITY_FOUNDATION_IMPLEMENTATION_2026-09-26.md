# Priority foundation implementation — 2026-09-26

This change implements the dependency chain **credential/basic-profile validation → published-profile access → discovery/spotlight eligibility**, from [PEN-14–17](PENDING_FEATURE_BACKLOG.md). It also closes a related member-update privilege boundary. It does not complete the entire pending backlog or certify production readiness.

## Delivered behavior

- `GET /v1/profile/{userID}` requires a verified session and PostgreSQL persistence. It returns an explicit display-field allowlist, not the entire user row or a private draft. Contact information, login username, precise location and enforcement metadata are excluded. Rich display attributes use the durable completion snapshot, so purging a completed draft does not erase the published profile.
- Current account restrictions and current photos determine visibility. Missing, incomplete, blocked in either direction, inactive, banned, effectively suspended, deactivated, erased and credential-disabled profiles are unavailable. Public display requires two approved, active, nondeleted photos. Verification is a distinct current field; it is not assumed from completion or taken from a stale snapshot.
- Discovery candidates are revalidated using the same SQL publication predicate in a single batch before filtering/ranking and spotlight exposure accounting. Current approved photo URLs and verification state replace stale card values. Spotlight cannot promote an unpublished profile.
- Flutter profile details make one published-profile request. They never request another person's draft. HTTP failures and not-found payloads remain errors with retry/back controls, instead of showing a fabricated mock member. Explicit mock mode still has its deliberate fixtures.
- General member profile updates reject unknown and server-owned fields, including verification, suspension, ban, activation, completion, credentials and media, in both the application command and profile service. Identity/DOB/gender changes require the dedicated workflow. This prevents members from writing the state on which publication relies.
- Username validation now enforces 3–30 ASCII characters, allowed internal dot/underscore, and alphanumeric endpoints across Flutter, the auth domain, signup/bootstrap, the native auth repository and both PostgreSQL identity tables. Case/whitespace normalization remains.
- Signup and profile completion validate calendar age rather than comparing day-of-year values across leap/non-leap years. Completion revalidates basics, preventing draft edits from bypassing signup validation. Existing 18–80 eligibility and supported gender values remain; display names are 2–50 characters.

## Architecture and policy boundaries

The two-approved-photo rule is the conservative implementation baseline for public visibility. The existing completion transaction still requires all submitted photos to be approved; this change does not create a new pending-review onboarding state. Identity verification remains independent; verification-only discovery/chat, inclusive pairing/gender decisions, and changes to age policy remain product decisions.

This work does not claim complete privacy/data-lifecycle implementation. Existing DOB/display-attribute contracts remain, and visibility preferences, export/deletion/retention and identity-evidence policy need their own acceptance. Account-lifecycle code and migrations 065–067 were already being changed in the shared workspace; this change respects their deactivation/erasure columns and does not claim authorship or acceptance of those workflows.

The publication guard uses one bounded batch for the candidate pool, not one SQL call per card. It can reduce the returned deck below the requested limit when upstream candidates are ineligible. Candidate replenishment and production query-plan/load proof remain separate work.

## Migration and compatibility

Apply [068_username_length_contract.sql](../backend/scripts/068_username_length_contract.sql) additively after the native schema and account-lifecycle migrations. It was successfully applied to the local dating database on port 55433 and recorded in `schema_migrations`. The local rebuild manifest includes migrations 065–068, but the destructive rebuild script was **not** run for this change.

The migration validates existing users and auth credentials transactionally. If a legacy username violates the rule, migration fails without renaming immutable identities or leaving half of the new contract installed. Resolve such identities explicitly before deployment; no silent rename is performed. The local users preflight found no invalid username rows, and both constraint replacements committed successfully.

The public route requires the migrated PostgreSQL schema. A deployment without it fails closed rather than forwarding an unrestricted upstream user row. Own summary/draft routes retain their ownership rules. The [live API contract](../backend/internal/platform/docs/openapi.yaml) describes the new publication response/error behavior and restricted update semantics.

## Validation

- Full backend `go test ./...` passed with `PROFILE_TEST_DATABASE_URL` pointing to local PostgreSQL, so the new database tests ran rather than skipped. After adding shared discovery publication, the affected BFF, auth, matching and profile suites passed again; the final route/privacy tests passed uncached.
- Transaction-rolled-back PostgreSQL fixtures cover current approved photos, published versus private draft content, draft purge, both block directions, incomplete/inactive/banned/suspended/deactivated/erased accounts, disabled credentials, deleted/quarantined/review-required photos and discovery/spotlight parity.
- Database username tests cover empty/1/2/3/30/31-character values, uppercase and illegal endpoints in both identity tables. Domain and Flutter tests cover normalization/boundaries and rejection of a one-character signup.
- HTTP tests reject member privilege escalation and unauthenticated public profile access. Ownership tests preserve foreign draft/summary denial.
- All 31 focused Flutter provider, authentication, profile setup and preview tests passed.
- Android debug APK build and BFF binary build passed. Emulator installation status is recorded below separately from build success.
- Targeted Flutter analysis reported 68 informational style/deprecation diagnostics in the existing profile-detail code; no analyzer errors or warnings were reported. A fully clean lint gate is not claimed.

### Local running app

The universal APK initially failed installation because the emulator lacked storage. A split ARM64 debug APK then built, installed successfully with replacement preserving app data, and launched on `emulator-5554`. The app process remained running after launch. This is build/install/launch acceptance, not a complete authenticated device journey.

The local auth, profile and mobile-BFF binaries were rebuilt and restarted against the existing dating database on port 55433, retaining prior binaries for recovery. BFF health/readiness and gateway health returned HTTP 200; readiness reported auth, profile, matching, chat and PostgreSQL ready. An unauthenticated public-profile request through the gateway returned HTTP 401. No schema rebuild or app-data reset was performed.

## Backlog disposition

| Item | Status after this change | Remaining work |
|---|---|---|
| PEN-14 | Published-profile read path implemented and locally tested. | Broader member visibility preferences and production/device acceptance. |
| PEN-15 | Shared public-detail/discovery/spotlight eligibility implemented and locally tested. | Full completion/media/identity/chat state matrix; pending-review UX and verification-only policy. |
| PEN-16 | Username contract fixed and locally tested across layers. Password is now aligned at 8–72 UTF-8 bytes across current backend/Flutter entry points. | Wider credential/device acceptance. |
| PEN-17 | Calendar-age/name validation fixed for signup and completion; the release contract approves 18–80 and explicit `M`, `F`, or `Other` selection. | Wider device boundary evidence. |
| Related P0 privilege boundary | Member updates cannot set authoritative verification/enforcement state. | Continue auditing other mutation paths and current-source safety/authorization acceptance. |

Next dependency chain: verify account lifecycle across sessions, discovery, chat and retained data; then close connected-stream revocation and replay recovery (PEN-20–21), followed by durable activity-to-XP recovery (PEN-22). Payment/call integrations remain separately gated by their selected provider and approved scope.
