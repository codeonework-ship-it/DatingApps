# Discovery Visibility Enforcement

Date: 2026-09-26  
Scope: FRD-CONNECT-001 gaps PROF-011 and SAFE-008; correction to SAFE-002.  
Evidence: Go unit tests, each mutation-tested. No live database was available
(port 55432 is held by an unrelated project's PostgreSQL and the `dating_app`
database is absent), so nothing here is backed by an end-to-end run.

## Summary

Three public-visibility rules were enforced on the single-profile read and not
on the discovery deck. The two surfaces disagreed about who may be seen.
`loadPublicProfile` filters lifecycle, moderation, ban, suspension, credential
state and blocks; discovery filtered only `is_active` and moderation status.

Every fix narrows what discovery returns. None widens visibility.

## Defects closed

| # | Rule | Before | After |
|---|---|---|---|
| 1 | Quarantined media must not reach public discovery (PROF-011) | Candidate photos filtered `moderation_status='approved'` only | Also requires `lifecycle_status='active'` |
| 2 | Bans and suspensions must take effect (SAFE-004 intent) | Candidates filtered `is_active=true` only | Also excludes `is_banned`, and drops members whose suspension is still in force |
| 3 | Blocking must apply to discovery (SAFE-002) | Not applied at all | Bidirectional block filter, applied before the deck is trimmed |

### 1. Quarantined media

`moderation_status` and `lifecycle_status` are independent columns. A photo
approved by moderation and later quarantined — by a rescan, a report, or an
operator decision — keeps `moderation_status='approved'` while its lifecycle
moves to `quarantined`. Filtering on the moderation decision alone returned it
to the public deck.

### 2. Bans and suspensions

Suspension writes `suspended_at`/`suspended_until` and bans write `is_banned`;
both revoke sessions. Neither clears `is_active`. Discovery filtered on
`is_active` alone, so a banned or suspended member stayed in everyone else's
deck even though their own access was cut off.

Suspension is evaluated in Go rather than as a query filter because the
predicate is a disjunction — never suspended, or suspended with an elapsed
expiry — which the key/value filter API cannot express. Filtering
`suspended_at is.null` instead would have permanently hidden anyone who had
ever served a suspension. An unparseable expiry fails closed.

### 3. Blocking

The candidate exclusion set covered self, already-swiped and already-matched
members only. Blocking is now filtered in both directions, matching the profile
read: the blocking member is not dealt the blocked member's card, and is not
dealt to them either. If the block list cannot be read the deck is emptied
rather than served unfiltered — discovery degrading to empty is recoverable, a
silently skipped safety rule is not.

## Documentation correction

SAFE-002 is labelled `P0 / D` ("documented current local behavior; reports say
implemented") and states that blocking applies to discovery. It did not. The
label reflected the block/unblock persistence and the messaging/social paths,
not the discovery deck. The requirement is now enforced; the label was
inaccurate before this change and should be re-derived from code rather than
from the prior report.

## Verification

Seven Go tests were added:

- `TestGetUserPhotos_ExcludesQuarantinedMediaFromDiscovery`
- `TestListActiveUsers_ExcludesBannedMembers`
- `TestDropSuspendedUsers_KeepsServedSuspensions` (served, active, indefinite
  and unparseable expiries)
- `TestAttachBlockedFilteredDiscovery_RemovesBothDirections`
- `TestAttachBlockedFilteredDiscovery_FailsClosed`
- `TestAttachBlockedFilteredDiscovery_NoBlocksLeavesDeckIntact`

Each guard was mutation-tested: removing the lifecycle filter, making the block
filter one-directional, and switching the block filter to fail open each
produce a failure naming the defect. Sources were restored byte-identical after
every mutation.

Full backend suite: 0 failures. `check_backend_compliance.sh`: pass.

## Not established

- No end-to-end or device run; the local application database does not exist in
  this environment.
- The `public.photos` smoke schema (migrations 015–017) has no lifecycle,
  moderation or deletion columns. The discovery fallback path against that
  schema was already passing `moderationStatus` and `deletedAt` filters it
  cannot satisfy; adding `lifecycleStatus` changes nothing there. That legacy
  schema remains unreconciled.
- `listActivePhotosPostgres` is named for the active lifecycle but filters only
  `moderation_status <> 'rejected'`. It is owner-scoped, so this is a naming and
  latent-reuse hazard rather than a leak, and was left unchanged.
- PROF-011's remaining release gates — provider activation and labelled-corpus
  policy acceptance — are untouched.

---

# Addendum: Account Deactivation, Deletion and Export

Date: 2026-09-26  
Scope: FRD gaps AUTH-009 and SAFE-008 (member-initiated data lifecycle).  
Evidence: live local PostgreSQL round trips plus Go unit tests. The application
database was found intact on port 55433 and did not need rebuilding.

## Database

No rebuild was performed. The `dating_app` database was healthy — 39 migrations
through `064`, 442 users, 897 photos, 136 matches — and had been moved to port
55433 because an unrelated project holds 55432 on this machine. Rebuilding would
have destroyed working seed data to fix a port mismatch.

`backend/config/.env.local-postgres.example` and `local_postgres.sh` still
defaulted to 55432, so the next restart would have pointed the stack at the
wrong server. Both now default to 55433.

## Delivered

Migration `065_account_lifecycle.sql` adds `deactivated_at`,
`deletion_requested_at` and `deletion_effective_at` to users, plus
`user_management.account_lifecycle_requests` with a partial unique index
allowing one open request of each type per member.

Seven endpoints, all self-service:

| Method | Path | Behaviour |
|---|---|---|
| GET | `/account/{userID}/lifecycle` | Current state |
| POST | `/account/{userID}/deactivate` | Reversible pause |
| POST | `/account/{userID}/reactivate` | Resume |
| POST | `/account/{userID}/deletion` | Schedule erasure after 14 days |
| DELETE | `/account/{userID}/deletion` | Cancel inside the window |
| POST | `/account/{userID}/export` | Generate the member's record |
| GET | `/account/{userID}/export` | Fetch the latest unexpired export |

Every action writes an attributed event to the append-only
`audit.security_events` table.

## A design error found by testing, and corrected

The first implementation expressed deactivation by clearing `is_active`, which
looked natural because discovery already filtered on it.

That column also gates login and bearer-session validation. Deactivating the QA
account therefore locked it out completely: re-login returned "account is
suspended or banned", and the member could not reach the endpoint that reverses
the pause. Deactivation was advertised as reversible and was in fact a one-way
trip requiring operator or database intervention. The same flaw applied to the
deletion grace period — a window the member cannot sign in to use is not a
grace period.

`is_active` was overloaded: it means "the platform has enabled this account",
which is an enforcement concept, and it was being reused for "the member has
paused themselves".

Corrected so that visibility is withdrawn through `deactivated_at` while
`is_active` and live sessions are untouched. Discovery and the public profile
read now exclude `deactivated_at IS NOT NULL`. The paused member stays able to
sign in, which is what makes the reversal real.

The QA account was restored; its final state is active with both lifecycle
columns null.

## Export boundary

The payload is built from an explicit allow-list — account, preferences, photo
metadata, settings, terms acceptances, blocks, matches and messages the member
sent. Excluded: password and recovery-code hashes, session and refresh tokens,
and other members' profile data. Match counterparties appear as opaque ids.
Message bodies the member wrote are included; bodies written to them are not,
because those are another member's words.

## Verification

Live round trips against local PostgreSQL:

- deactivate → re-login **allowed** → reactivate, state returning to normal
- deletion scheduled with a 14-day `effective_at`; duplicate request 409;
  cancel restores; cancel with nothing scheduled 409
- acting on another member's account id: **403** for both deactivate and delete
- export returned 2 photos, 1 match, 1 sent message, and no credential material
- a member is discoverable → not discoverable → discoverable again across the
  deactivation cycle
- `UPDATE` against `audit.security_events` rejected: *"append-only"*

Go tests added: `TestAccountRootIsSelfScoped` (every path × method, owner vs
other), `TestAccountExportOmitsCredentialMaterial`,
`TestListActiveUsers_ExcludesSelfDeactivatedMembers`. The access-control guard
was mutation-tested — removing `"account"` from `selfRoots` fails it, naming the
fail-open default as the cause. Source restored byte-identical.

Full backend suite: 0 failures. Compliance check: pass. OpenAPI contract tests
pass with all seven operations documented.

## Not established

- **No erasure worker exists.** A due deletion sets `effective_at` and the row
  waits; nothing yet performs the erasure or enforces a retention schedule.
  Until that is built, deletion is a scheduled intent, not a completed deletion,
  and SAFE-008 remains open on the retention half.
- Export payloads are stored as JSONB with a 7-day expiry; no job prunes expired
  payloads yet.
- No Flutter UI. The journeys are API-complete and unreachable from the app.
- AUTH-009 also names recovery-code loss, inaccessible-account support and cold
  start session persistence. Those remain untouched.

---

# Addendum 2: Account Erasure Worker

Date: 2026-09-26  
Scope: completes the deletion journey opened by migration 065.  
Evidence: live local PostgreSQL, two disposable subjects erased end to end and
removed afterwards; Go tests for the invariants.

## Erasure is anonymisation, and the schema forces that

`progression.xp_ledger.user_id` references `users` **ON DELETE RESTRICT**, and
the ledger carries an append-only trigger. The ledger rows can be neither
cascaded away nor deleted first, so a member who has ever earned XP cannot have
their `users` row removed. Confirmed against this database:

```
HARD DELETE BLOCKED: update or delete on table "users" violates foreign key
constraint "xp_ledger_user_id_fkey" on table "xp_ledger"
```

Erasure therefore scrubs identity and deletes content, leaving rows that no
longer identify anybody. This is a product decision the schema made before this
change; it is recorded here rather than silently worked around.

| Removed | Retained, deliberately |
|---|---|
| photos (rows and storage paths), profile drafts and snapshots, preferences, emergency contacts, device push tokens | `progression.xp_ledger` (cannot be deleted) |
| message text and prompt answers the member wrote | `audit.security_events`, `audit.change_log` |
| username, name, phone, email, bio, DOB, location, all profile attributes | `media_moderation_events`, moderation reports and appeals |
| credentials disabled, every session revoked, export payloads dropped | |

Message *rows* survive with their text replaced, so the counterparty's
conversation keeps its shape. Bodies written **to** the member are untouched —
those are someone else's words.

## Worker

`accountErasureWorker` sweeps hourly inside the BFF, wired into the existing
worker lifecycle. It erases only where `deletion_effective_at <= NOW()`, skips
accounts already carrying `erased_at`, and continues past a failed subject so
one bad row cannot block every other deletion. It also prunes export payloads
past their retention window — a copy of the data must not outlive the data.

## Two defects found by testing, both fixed

**The erasure silently scrubbed nothing.** The first version updated
`matching.messages.content`; the column is `text`. The error was swallowed and
recorded as `-1`, so the account would have been marked erased with the member's
messages intact. The step now aborts the transaction on any failure — erasure is
the one operation that cannot be partially right — and the sweep retries.

**The tombstone username collided.** `users.username` is immutable
(`prevent_username_change`), unique, and capped at 30 characters by
`users_username_check`. `'erased_' + full uuid` is 39 characters and was
rejected; truncating the uuid to its leading 23 characters then made ids sharing
a prefix collide, which would have aborted the second member's erasure. The
tombstone is now 23 hex characters of a sha256 digest of the id. Go and SQL
compute it independently, so they were checked against each other:

```
SQL: erased_f4a3638de68706b10ff7426
Go : erased_f4a3638de68706b10ff7426
```

Migration `067_username_erasure_carveout.sql` permits the rename only on the
not-erased → erased transition and only to that exact value. Verified: a plain
rename, a wrong tombstone, and a rename on an already-erased row are all still
refused.

## Verification

Two disposable members were created with photos, XP ledger rows and elapsed
grace periods, erased by the wired worker on service start, then removed.

- identity scrubbed: `erased_16b3efbb35ad01f9a2a3079`, name `[erased]`, bio,
  phone, email and location null, DOB reset
- photos 0, profile drafts 0, live sessions 0
- `xp_ledger` 1 retained, audit event `account.erased` written with the released
  storage count
- request closed as `completed` with an `erasure_summary`
- second sweep produced no new audit event and no error — **idempotent**
- grace period respected: erasure refuses while `deletion_effective_at` is in
  the future

Go tests added: tombstone satisfies the username format constraint, tombstones
are distinct across ids, erasure never touches the retained tables, erasure
still covers member content, retained tables are declared. The distinctness test
is the one that caught the collision.

Database left clean: 442 users, 0 erased accounts, 0 fixtures, append-only
trigger re-enabled, QA account untouched.

Full backend suite: 0 failures. Compliance: pass. OpenAPI contract tests: pass.

## Not established

- **Storage objects are not deleted.** Erasure collects `storage_path` values
  and records them in the audit event, but releasing the underlying objects is
  left to the existing media cleanup sweep. Nothing yet proves those objects go.
- No retention schedule beyond the 14-day grace and the 7-day export window.
  SAFE-008 also asks for market-specific review ownership, which remains a
  policy decision.
- The worker runs in-process on a fixed hourly tick with no metrics, alerting,
  or cross-instance coordination. Two BFF instances would both sweep; the
  `erased_at` check and row locking make that safe but wasteful.
- No Flutter UI for any of the lifecycle journeys.

---

# Addendum 3: Storage Release Verified, and Two Defects It Exposed

Date: 2026-09-26  
Scope: verification of the storage-object claim left open in addendum 2.  
Evidence: live local filesystem and PostgreSQL, measured before and after.

## The claim was wrong

Addendum 2 said releasing storage objects was "left to the existing media
cleanup sweep". Measured, that sweep does not release them:

| Backend | Behaviour before this change |
|---|---|
| Local filesystem | Released only on the **third** sweep, not the first |
| AWS S3 | **Never released** |

Erasure deletes the photo rows, and those rows were the only pointer the
cleanup had. `runMediaLifecycleCleanup` acts on rows that still exist, so it
never sees them. The fallback orphan scan, `cleanupUnreferencedLocalFiles`,
reads the referenced-path set *before* erasure removes the rows, which is why
the first pass missed the file — and it is skipped entirely when the storage
backend is S3:

```go
if !s.usesAWSS3Storage() {
    s.cleanupUnreferencedLocalFiles(ctx)
}
```

Measured directly: after erasure the account showed `erased_at` set and zero
photo rows, while the file was still on disk after two sweeps. On S3 there is no
pass that would ever have removed it. The product would have reported a
completed erasure while the member's photographs remained in the bucket.

## A second defect found while fixing it

`user_management.auth_credentials.username` is a separate copy of the member's
handle and is that table's primary key. Erasure disabled the credential row but
left the username in place, so the member's most recognisable identifier
survived an erasure that reported success — and the handle stayed permanently
occupied.

No foreign key references that column; every relationship is on `user_id`. It is
now rewritten to the same tombstone the `users` row carries.

## Fix

Migration `069_erasure_storage_release.sql` adds `storage_released_at` to the
lifecycle request plus a partial index for the pending set.

The worker now drives deletion itself instead of relying on an orphan sweep. It
reads the paths from the persisted `erasure_summary` — deliberately, because the
photo rows are gone by then — deletes each object, and marks the release only
when every object succeeded. A partial failure leaves the marker unset so the
next sweep retries; deleting an object twice is harmless, losing one is not.
Both backends tolerate an already-absent object, so a retry cannot loop.

A numbering collision was corrected on the way: this migration was first written
as `068`, which was already taken by `068_username_length_contract`. Renamed to
`069` and the recorded version updated.

## Verification

A disposable member with a real file on disk and a credential row, erased by the
wired worker on service start:

```
BEFORE: file=YES  cred_username=erasure_subject_5
AFTER 1st sweep:
  file on disk     : RELEASED
  users.username   = erased_f3e4857bbef18550ea5fd21
  cred.username    = erased_f3e4857bbef18550ea5fd21
  storage_released = 2026-09-26 19:28:11
```

Released on the **first** sweep, where the previous behaviour left it on disk
indefinitely.

Go tests added: every non-empty path is deleted; a failed object is reported so
the release stays unmarked and retries; the erasure summary still carries the
`storage_paths_released` field the release pass reads.

Database and filesystem left clean: 0 fixtures, 0 erased accounts, uploads
directory restored.

Full backend suite: 0 failures. Compliance: pass.

## Still not established

- Verified against the **local** filesystem backend only. The S3 path uses the
  same injected deleter and `DeleteObject` is idempotent, but no S3 bucket was
  exercised, so that remains reasoned rather than measured.
- There are two upload directories on this machine — `<repo>/.run/uploads` and
  `backend/.run/uploads` — because `MEDIA_UPLOADS_DIR` is relative and the
  services run from the repository root. Only the first is live. The second
  holds 13 stale directories that nothing reads or cleans.
- The worker still has no metrics or alerting, and no cross-instance
  coordination.

---

# Addendum 4: Account & Data Screen

Date: 2026-09-26  
Scope: Flutter UI for the lifecycle journeys built in addenda 2 and 3.  
Evidence: 821 Flutter tests, two mutation checks, live payload contract check,
build and launch on `emulator-5554`.

## Why one screen

Pause, export and delete share a screen because they are the same decision at
different strengths — step away, take a copy, leave for good. A member weighing
deletion sees the reversible option in the same view instead of discovering it
afterwards. Reached from Settings → Preferences → **Account & Data**.

## Behaviour

| State | What the member sees |
|---|---|
| Normal | Take a break · Download your data · Delete my account |
| Paused | "Your profile is hidden", with **Unhide my profile** |
| Deletion pending | A countdown card **above everything else**, with **Keep my account** |

The countdown leads the screen because it is the member's window to change
their mind; burying it inside the delete section would make them go looking.

Pause and delete are both disabled once a deletion is scheduled. They act on
the same thing — visibility — and a scheduled deletion has already hidden the
member, so leaving both live would present two switches for one state and let a
pause silently contradict a pending erasure.

Deletion is never a single tap. Its dialog also offers **Hide instead**, because
a member who wants to disappear usually wants to be hidden rather than erased.

The export is shown in a dialog with a copy action rather than written to a
file: the app holds no storage or share permission for this, and a member who
can see and copy the payload has the data without the app asking for access it
otherwise never needs.

## Verification

- **821 Flutter tests pass**, analyzer 0 errors.
- The screen is registered in the responsive matrix, so it is now exercised at
  5 device sizes × light and dark — **551 responsive cases**, all passing.
- Nine tests cover the screen and the model, including that an elapsed deadline
  floors at zero days rather than rendering "Deletion in -1 days".
- **Mutation-checked**: removing the confirmation dialog fails the suite, and
  so does leaving the pause control live during a scheduled deletion. Source
  restored byte-identical.
- The provider's field names were checked against the live server payload
  rather than assumed:

```
server keys: deactivated, deletion_cancellable, export_expires_at,
             export_ready, is_active, user_id
required keys missing: none
```

- Built, installed and launched on `emulator-5554` with no fatals and no
  Flutter exceptions.

Database left clean: 0 export payloads, 0 erased accounts, QA account active.

## Not established

- **The screen was not driven signed-in on device.** Rendering, state logic and
  the payload contract are covered by tests and a live API check, but no one
  tapped these buttons in the running app. The Appium suite has no coverage for
  this screen yet; the widgets carry `qa.account.*` keys so it can be added.
- The export dialog renders the raw JSON. It is complete and copyable but not
  formatted for a non-technical reader, and there is no file download.
- No Appium journey, and no entry point other than Settings.

---

# Addendum 5: Device Journey, and the Gift Economy P0s

Date: 2026-09-26  
Scope: Appium coverage for the Account & Data screen; verification of the
GIFT-003 and GIFT-005 acceptance criteria the FRD labels `P0 / R`.

## Account & Data on device: 5 passed

`qa/appium/tests/test_15_account_lifecycle.py` under a new `account_lifecycle`
marker:

| Case | Asserts |
|---|---|
| screen shows every journey | pause, export and delete all reachable |
| pause hides and can be undone | UI **and** server state agree both ways |
| export produces the member's own data | dialog contains the member's own id |
| delete requires confirmation | dialog appears and offers "Hide instead" |
| scheduled deletion can be cancelled | schedules, then clears, verified server-side |

Each case that changes lifecycle state restores it through the API in a
`finally`, not through the UI path under test. The suite shares one QA account
and a deletion left scheduled would hide it from Discover and break every later
test. Confirmed afterwards: the account is active with both lifecycle columns
null.

The Flutter controls needed `Semantics` labels, not just `ValueKey`s — a key
never reaches the accessibility tree, which is all UiAutomator can read. Both
are kept: the key for widget tests, the label for the device.

**Three attempts were needed.** The first two failed at session setup with
`the instrumentation process cannot be initialized`. The app launched fine by
hand with no fatals, so the fault was the emulator, not the build: `/data` sat
at 89%. After trimming caches and a cold restart the same suite passed
unchanged. Worth recording because the failure looks like a product defect in
the log and is not one.

## GIFT-003 and GIFT-005 verified

Both are `P0 / R` — retained requirements whose completion the FRD says is not
established. Verified against a disposable two-member match with an unlocked
conversation and a funded wallet, so the shared QA account was never touched.
The QA account's own match is quest-locked, which answers 423 before any gift
validation runs; that is correct ordering, safety ahead of payment, and it is
why an isolated fixture was needed.

| Criterion | Result |
|---|---|
| Same-key retry yields one debit | **Pass** — 200 then 200, one coin charged |
| Different key charges again | **Pass** |
| Per-match daily limit under **concurrent different-key** sends | **Pass** — 5 concurrent, one 200 and four 429, exactly 20 coins charged |
| Insufficient funds uses 402 | **Pass** — `INSUFFICIENT_COINS`, balance unchanged |
| Expired/inactive gift uses 422 | **Failed → fixed** |
| Unauthenticated send | **Pass** — 401 |

The concurrency case is the one that mattered: five simultaneous sends of a
one-per-match exclusive gift produced exactly one success and a single debit.
No double-spend and no limit bypass.

### The 422 defect

An inactive gift answered **400 `BAD_REQUEST`** where GIFT-005 documents 422.

`getCatalogByID` filters on `is_active`, so a retired or out-of-season gift came
back as "gift not found" — indistinguishable from an id that never existed — and
both fell through to the generic 400. The distinction matters to a client: 422
says the request was well formed and the gift cannot be sent, 400 says the
request was wrong.

Fixed with an `errGiftUnavailable` sentinel and an existence probe that ignores
the active filter. Verified live:

```
inactive gift     -> 422 (GIFT_UNAVAILABLE)
nonexistent gift  -> 400 (BAD_REQUEST)      still a client error, correctly
balance 100 -> 100                          no charge either way
```

Two Go tests guard it, including that the neighbouring documented codes — 402,
429 and 423 — survive alongside the new branch.

## Verification and cleanup

Backend suite 0 failures, compliance pass, Flutter **826 tests** pass, analyzer
0 errors.

Fixtures removed: both gift probe members, their match, quest template and
workflow. Catalog restored — the three inactive gifts remaining are the
pre-existing seasonal entries (Christmas, Diwali, New Year), which are exactly
the seasonal-window case GIFT-005 describes.

## Not established

- **The UTC-day versus rolling-24-hours question in GIFT-005 is still open.** The
  limit was proven to hold under concurrency, but which window it uses was not
  tested and the FRD records it as an unresolved product decision.
- Seasonal start/end windows were not exercised. The three seasonal gifts are
  inactive by flag; no test moved a clock across a window boundary.
- The remaining `P0 / R` rows — PROF-002, PROF-004, UNLK-002, BILL-002 — are
  untouched.
