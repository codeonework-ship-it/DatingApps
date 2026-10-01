# Client error reporting and telemetry privacy (2026-10-01)

This change adds two things:

- **Crash and error reporting** for the Connect app, run on our own servers. No vendor SDK is used.
- **Privacy fixes** for request telemetry, server logs and app logs.

Migration: `backend/scripts/122_client_error_reporting_and_telemetry_privacy.sql`.

## 1. Crash and error reporting

### Flow

1. The app catches errors from four places:
   - `FlutterError.onError`
   - `PlatformDispatcher.onError`
   - the root `runZonedGuarded`
   - `log.error(message, error, stack)` (these are recorded as "handled")
2. The app scrubs each event, removes duplicates and saves it to device storage.
3. The app sends events in batches to `POST /v1/client/errors`.
4. The server checks the batch again and scrubs it again.
5. The server groups events into **issues** and stores them in `platform.client_error_*`.
6. Operators review issues in the console under **Client errors**, backed by `/v1/admin/client-errors`.

### What one event contains

| Field | Notes |
|---|---|
| `error_type` | The runtime type, for example `StateError`. |
| `message` | Scrubbed. At most 1,000 characters. For a `FormatException`, only the reason is kept, never the input text, because that text could be a member's message. |
| `stack` | Scrubbed. At most 50 lines and 8,000 characters. |
| `fatal`, `handled`, `source` | `source` is one of `flutter`, `platform`, `zone`, `logger`. Errors reaching `FlutterError.onError` are not fatal: the framework caught them. Errors reaching `PlatformDispatcher` or the zone handler are fatal. |
| `app_version`, `build_number` | Set with `--dart-define=APP_VERSION` and `APP_BUILD_NUMBER`. Without them the values default to the pubspec's `0.1.0` and `1`, so release builds must pass them. |
| `platform`, `os_version` | `platform` is one of android, ios, web, macos, windows, linux. `os_version` is the OS version string, scrubbed. |
| `device_class` | One of `phone`, `tablet`, `desktop`, `web`, `unknown`. Never the device model or name. |
| `locale` | For example `en_IN`. |
| `screen` | The current route as a template. Ids are replaced with `<id>`; there is no query string. |
| `breadcrumbs` | The last 20 events: navigation (route templates), API (`GET /profile/<id> -> 200`, without query or body) and lifecycle (resumed/paused). |
| `occurred_at` | UTC. |
| `install_id` | 32 random characters, created once per install. It is sent with each batch, not with each event. |

### What is never sent or stored

- Account id, username, email or phone number. The server never writes an account id to these tables.
- Device name or model, and the IP address. The IP is used only as an in-memory rate-limit key.
- Request or response bodies and query strings.
- Message text, photos and tokens.

### Anonymity

Reports are anonymous.

- The bearer session is optional. When one is sent, it only selects the signed-in rate limits and sets a `signed_in` flag on the stored occurrence.
- An expired or invalid token is treated as anonymous. Crashes often happen right when a session ends.
- The install id is stored only as a sha256 **reporter key**. That key is used to count distinct affected installs (`affected_users`) and to stop one install's crash loop from filling the table.
- The public route ignores any `X-User-ID` or `X-Admin-User` header the caller sends, so request telemetry cannot attribute a report to a member the caller names.

### Scrubbing

Scrubbing runs twice: on the device (`app/lib/core/telemetry/pii_scrubber.dart`) and on the server (`observability.RedactText`). The server never relies on the client's scrubbing.

| Data | Replaced with |
|---|---|
| Email addresses | `<email>` |
| Phone numbers (7–15 digits; ISO dates are left alone) | `<phone>` |
| `Bearer …`, JWTs, `token=`, `password=`, `api_key=`, `otp=`, and long hex or opaque tokens | `<token>` |
| UUIDs | `<id>` |
| IPv4 addresses | `<ip>` |
| 13–19 digit card-like numbers | `<number>` |

Two more rules:

- URLs lose their query string and fragment.
- In paths, id-like segments (numbers, UUIDs, long tokens, emails, phone numbers, and placeholders the client already wrote) become `{id}`.

### Grouping

The server computes the fingerprint itself. The client's `fingerprint` is advisory only.

The fingerprint is sha256 of three parts:

- the error type
- the first line of the message, with digits normalised
- the top five app frames (framework frames are skipped), with line and column numbers and addresses removed

Platform and app version are not part of the fingerprint. The same fault on Android and iOS, or across releases, is one issue, and versions are tracked per issue in `client_error_issue_versions`. The issue's `culprit` is the first app frame.

### Storage (migration 122)

| Table | Contents |
|---|---|
| `client_error_issues` | One row per fingerprint: title, culprit, status (`open`, `resolved`, `ignored`), fatal, regressed, occurrence count, affected installs, platforms, first and last seen, resolution details |
| `client_error_issue_versions` | Occurrences and first/last seen per (issue, app version, platform) |
| `client_error_issue_reporters` | One reporter key per (issue, install), used for the affected-installs count |
| `client_error_occurrences` | The scrubbed event |

Limits on stored occurrences:

- **Cap per issue:** at most 50 occurrences are kept per issue (the newest). Counts keep growing past the cap.
- **Crash-loop suppression:** an install stores at most one occurrence per issue every 5 minutes.
- **Ignored issues:** they keep counting but store no new occurrences.

### Regressions

When a resolved issue is reported again, it reopens with `regressed=true`, a higher `regression_count` and a status note saying which version reported it. It reopens in either of these cases:

- `resolved_in_version` was set, and the reporting version is the same or later. Versions are compared numerically, so 1.10 is later than 1.9.
- No fix version was set, and the reporting app version or platform had not reported the issue before it was resolved.

Older builds still in use do not reopen an issue that is already fixed.

### Abuse controls

| Control | Limit |
|---|---|
| Body size | 64 KB (`413` above that) |
| Events per batch | 1 to 20 (`400` otherwise) |
| Event age | Older than 7 days is dropped; a future timestamp is set to the time received |
| Per install | 60 events per 10 minutes |
| Per account, when signed in | 120 events per 10 minutes |
| Per IP, when signed out | 60 events per 10 minutes. The IP is the right-most `X-Forwarded-For` entry, which our gateway appends. |
| All signed-out reports together | 3,000 events per minute |

A batch that would go over any limit is rejected as a whole with `429` and `Retry-After`, and it uses up none of the budget. The counters live in memory, one set per BFF instance, and only hashed keys are held.

Every text field is cut to its column limit, and free-form values are reset to a safe default, for example an unknown `device_class` becomes `unknown`.

The ingestion route is not covered by idempotency keys. Retries are absorbed by grouping and crash-loop suppression.

### How the app sends reports

All of this is in `app/lib/core/telemetry/client_error_reporter.dart`.

- **Duplicates:** the same fingerprint within 60 seconds is dropped.
- **Queue:** at most 100 events, kept in SharedPreferences, so a fatal crash is sent on the next start.
- **When it sends:** on start, on resume, 10 seconds after a new event, and when 20 events are queued.
- **By response:**

| Response | What the app does |
|---|---|
| `202` | Removes the sent events |
| `400`, `413` | Drops the batch |
| `429` | Waits for `Retry-After` |
| Network error or `5xx` | Exponential backoff, from 30 seconds up to 30 minutes |

- **Expiry:** events older than 7 days are dropped.
- **Transport:** the reporter uses its own Dio client with no interceptors, so it never logs itself or creates breadcrumbs.

### Opt-out and defaults

- **Opt-out switch:** Privacy & Safety → **Share crash reports**. It is on by default. Reports are essential diagnostics and are anonymous and not linked to the account.
  - The setting is stored on the device (`client_errors.opt_in`), because it also covers signed-out screens.
  - Turning it off stops capture and breadcrumbs, deletes the queued reports and deletes the install id, so turning it back on starts a new id.
- **Build flag:** `--dart-define=CLIENT_ERROR_REPORTING`.
  - Off in debug builds by default; on in profile and release builds.
  - Never active under `flutter test` unless a test turns it on explicitly.
- **Web:** web builds report errors, but without navigation breadcrumbs or `screen`, because the web router was not changed. `os_version` is empty on web.

### Retention

The retention policy row is `client_error_reports`, set to 90 days in `platform.retention_policies`.

`platform.run_client_telemetry_retention(batch)` runs hourly from the BFF's trust retention worker. Each run deletes:

- occurrences received more than 90 days ago
- reporter keys last seen more than 90 days ago
- issues not seen for 90 days, together with their version history

The number of rows removed is published as `verified_dating_trust_retention_rows_total{class="client_error_reports"|"client_error_issues"|"api_request_telemetry"}`.

### Operator use

The console page is **Client errors**: Logs → Client errors.

- **List:**
  - Summary counts: open, open and fatal, resolved, ignored.
  - Filters: status, platform, app version, fatal.
  - Sort by last seen, number of occurrences, or affected installs.
- **Detail:**
  - Per-version counts.
  - The 20 most recent occurrences, each with its stack, breadcrumbs, device class, OS, locale and screen.
  - Resolve (with an optional "resolved in version" and note), Ignore and Reopen.

Who can use it:

- `admin` and `ops_admin`: read and change status.
- `analyst`: read only.
- Other operator roles: no access.

Status changes are recorded by the operator-audit middleware.

The API:

- `GET /v1/admin/client-errors?status=&platform=&version=&fatal=&sort=&limit=&offset=`
- `GET /v1/admin/client-errors/{id}`
- `POST /v1/admin/client-errors/{id}/status`, with body `{status, resolved_in_version?, note?}`

### Metrics

Both counters are in the default Prometheus registry:

- `verified_dating_client_errors_total{platform,fatal}`: accepted events.
- `verified_dating_client_error_reports_rejected_total{reason}`: rejected reports or events. `reason` is one of `malformed`, `too_large`, `invalid_install_id`, `invalid_batch_size`, `rate_limited`, `missing_error_type`, `invalid_platform`, `invalid_app_version`, `stale`.

## 2. Request telemetry (`matching.activity_events`)

### Before this change

The BFF's request middleware wrote every API request into `matching.activity_events`. Each row held:

- the raw client IP (`payload.details.remote_addr`)
- the full query string (search terms, coordinates, cursors)
- the concrete path, which contains other members' and matches' ids

These rows had no retention, and account erasure did not touch them.

### What the middleware stores now

For each API request:

- method
- route template, for example `GET /v1/discovery/{userID}`, used both for `event_name` and for `payload.resource` / `details.path`
- status
- duration
- content type
- the member and actor ids, in their own columns
- `event_domain='api_request'`

It stores no IP (not truncated and not hashed — nothing), no query string, and no concrete path. Engagement and billing classification still reads the real path, but only the dimensions derived from it are stored.

### Existing rows (migration 122)

Request rows were recognised by their `"GET /v1/…"` event name. The migration:

- reclassified them as `api_request`
- removed `remote_addr` and `query`
- replaced UUIDs in the stored name, resource and path with `{id}`
- removed `remote_addr` and `query` from any other event that had copied them

Locally this rewrote 194,030 request rows and 206 other rows.

### Retention

The policy row is `api_request_telemetry`: 90 days. Members on legal hold are skipped, as with migration 081's activity-history class. Domain events (wallet purchases, gestures, quests) are not request telemetry and keep their existing lifetime.

### Account erasure

Two steps were added to `accountErasureSteps`:

- `api_request_telemetry` deletes the member's request rows, whether they are the subject or the actor.
- `activity_event_context` clears IP, device and geo columns, and any `remote_addr` or `query`, on the member's other activity events.

`audit.minimize_member_history` still runs last.

### Member export

The export has a new section, `api_activity_summary`: request counts per UTC day, and nothing else.

Crash reports are not linked to an account, so there is nothing of the member's to export from them.

### Known gap — needs an owner decision

Migration 036 attached the generic row-change audit trigger (`audit.capture_row_change`) to every `matching` table, including `matching.activity_events`. This has three effects:

- `audit.change_log` holds a full copy of every historical request row, including the old IP and query string, under its 24-month retention.
- The minimising UPDATE in migration 122 was itself recorded there.
- Every new request row is still copied, although new rows no longer contain IP or query data.

I did not drop that trigger or clean the existing audit copies: both change the audit trail and need explicit approval.

The recommended follow-up:

1. Drop `trg_audit_row_change` on `matching.activity_events`. The table is itself an activity record, and auditing it doubles write volume.
2. Delete the existing `audit.change_log` rows for that table, or minimise them as `audit.minimize_member_history` does, skipping members on legal hold.

Also note: `trg_domain_event_matching_activity_events` publishes one outbox event per API request. It carries changed field names only, no values.

## 3. Server logs

### Central helpers

The helpers are in `backend/internal/platform/observability/redact.go`, with tests in `redact_test.go`:

- `RedactText`: free-text scrubbing, the same rules as the table in section 1.
- `StripPathIDs`: replaces id-like path segments with `{id}`.
- `RedactedRequestPath(r)`: returns the chi route template, falling back to the path with ids stripped. It never includes the query string.
- `PseudonymizeIdentifier(v)`: returns `id_` plus 16 hex characters of an HMAC-SHA256.
  - The key is `LOG_PSEUDONYM_KEY` if that is set, so pseudonyms stay stable across instances.
  - Otherwise each process uses a random key, so pseudonyms correlate only within that process.
  - Either way, guessing phone numbers cannot reverse a pseudonym.

### Changed call sites

- **Usernames**
  - Before: logged in `auth_login_requested`, `auth_login_failed`, `auth_signup_requested` and `auth_signup_failed` (`internal/services/auth/service.go`), and in `auth_login_command` and `auth_signup_command` (`internal/modules/auth/application/service.go`).
  - Now: only `username_ref` is logged, which is the pseudonym.
- **Card digits**
  - Before: `billing_card_updated` logged the user id, brand and last4.
  - Now: last4 is removed; the brand stays.
- **Request paths**
  - Before: these logs included the concrete path:
    - `http_request`
    - `correlation_id_assigned` (debug level)
    - `http_unhandled_exception`
    - the overload shed log
    - `request_timeout_tier_elapsed` and the bulkhead shed log
    - `operator_audit_write_failed`
  - Now: they log `RedactedRequestPath(r)`, the route template, so member ids are no longer logged with every request.

## 4. App logs

- **`logger.dart`:** release and profile builds log only WARN and above. Debug builds keep full detail.
  - `log.error(msg, error, stack)` also passes the error to the crash reporter as handled.
- **`api_client_provider.dart`:**
  - Request logs never include query values, bodies or headers.
  - Debug builds log query parameter names only.
  - Release builds template the path, and error logs give only the failure type (Dio's error text contains the full URI).
  - API breadcrumbs are recorded from the interceptor.
- **Constants:** the unused `ENABLE_ANALYTICS` and `ENABLE_CRASHLYTICS` constants were removed from `app_constants.dart`. `FeatureFlags.enableClientErrorReporting` replaces them, with a comment that crash reporting is self-hosted and product analytics is computed server-side. See also `THIRD_PARTY_INTEGRATIONS.md`.
