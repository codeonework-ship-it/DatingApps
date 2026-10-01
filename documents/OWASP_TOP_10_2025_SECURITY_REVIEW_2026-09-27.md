# OWASP Top 10:2025 security review

**Review date:** 2026-09-27  
**Scope:** Flutter app and web build, browser gateway, Go API gateway and mobile BFF, Django control panel, dependency manifests, CI security gates, and repository secret hygiene. Billing provider work is coordinated separately and was not changed by this review.

## Result

The reviewed code now has locally verified controls for every category in the [OWASP Top 10:2025](https://top10.owasp.org/2025/). This is a code and local-runtime security assessment, not a certification or production launch approval. TLS termination, deployed network isolation, production secrets, monitoring, infrastructure configuration, and third-party provider configuration must still be verified in the target environment.

The review removed the highest-risk code gaps found during testing:

- Removed the public API gateway profiler endpoint and added regression coverage.
- Added browser security headers, a restrictive Content Security Policy, trusted-host validation, request-size enforcement, and safe proxy path handling.
- Redacted upstream 5xx responses at the public gateway so internal errors cannot cross the external trust boundary.
- Added HTTP header, idle, and request time limits to public Go servers.
- Upgraded vulnerable Go and Python dependencies and pinned third-party CI actions to immutable commit SHAs.
- Removed a committed local environment file from version control and replaced the documented Supabase key with a placeholder.
- Added continuous Go, Python, npm, secret, and static-analysis security checks.

## Control matrix

| OWASP 2025 category | Status | Implemented evidence | Production acceptance gate |
|---|---|---|---|
| A01 Broken Access Control | Locally verified | Bearer-session principals, role checks, user and match ownership enforcement, caller-supplied admin identity stripping, and negative access tests in the [mobile BFF security layer](../backend/internal/bff/mobile/server_security.go). | Keep gateway, BFF operations routes, databases, and object storage on private authenticated networks; repeat tenant-boundary tests against production-like data. |
| A02 Security Misconfiguration | Locally verified; deployment gate open | Browser headers, CSP, host allowlist, body limits, public profiler removal, generic proxy errors, and server timeouts in the [website server](../website/server.mjs) and [gateway server](../backend/internal/gateway/http/server.go). | Verify reverse-proxy TLS/HSTS behavior, deny direct BFF access, and require authentication for metrics, docs, and diagnostics. |
| A03 Software Supply Chain Failures | Locally verified | Dependency upgrades plus the [security workflow](../.github/workflows/security-gate.yml), immutable action pins, `go mod verify`, `govulncheck`, `npm audit`, and `pip-audit`. | Require the workflow on protected branches; add SBOM, signed artifact provenance, container and infrastructure scans before release. |
| A04 Cryptographic Failures | Code verified; deployment gate open | Bcrypt password hashing, cryptographically random session tokens, SHA-256 token-at-rest hashes, refresh rotation, and revocation in the [auth repository](../backend/internal/services/auth/postgres_repository.go). | Enforce TLS/WSS end to end, store production secrets in a managed secret store, rotate or retire the key present in Git history, and verify encryption and backup controls. |
| A05 Injection | Locally verified | Parameterized database access, identifier allowlisting in the data client, bounded numeric parsing, safe reverse-proxy path construction, and no reviewed web `eval`, `innerHTML`, or `document.write` sinks. | Run authenticated DAST and database-role boundary testing in staging. |
| A06 Insecure Design | Locally verified; operational gate open | Default-deny actor binding, resource ownership rules, account-state enforcement, upload validation, request limits, idempotency, and abuse controls are built into the service boundary. | Maintain a threat model for calls, recordings, identity evidence, discovery abuse, moderation, and billing; perform abuse-case review before public launch. |
| A07 Authentication Failures | Locally verified | Generic login failure messages, account lockout after repeated failures, short-lived access tokens, rotating refresh tokens, password-change revocation, and gateway rate limiting. | Use distributed rate limiting across replicas, add operator MFA, and validate recovery and session-revocation behavior in the deployed environment. |
| A08 Software or Data Integrity Failures | Locally verified; provenance gate open | Immutable CI action pins, dependency verification, idempotent mutation handling, webhook verification controls in the separately owned billing area, and current-tree secret scanning. | Sign release artifacts, publish an SBOM and provenance, protect release branches, and complete billing-provider acceptance separately. |
| A09 Security Logging and Alerting Failures | Code controls present; deployment gate open | Correlation IDs, recovery middleware, request and operator audit logging, activity tracking, and stable external errors without credential logging. | Connect logs and metrics to retained, access-controlled monitoring; alert on auth abuse, privilege failures, elevated 5xx rates, upload abuse, and audit-log interruptions. |
| A10 Mishandling of Exceptional Conditions | Locally verified | Global panic recovery, in-flight shedding, timeouts, bounded inputs, generic public 5xx responses, proxy error handlers, and regression tests for malformed and oversized requests. | Test dependency outages, storage exhaustion, retry storms, backup restore, and incident response under production-like load. |

## Verification evidence

| Check | Result |
|---|---|
| Go unit and integration suite (`go test ./...`) | Passed |
| Go static analysis (`go vet ./...`) | Passed |
| Go module integrity (`go mod verify`) | Passed |
| Go vulnerability analysis (`govulncheck`) | 0 reachable vulnerabilities; advisories in unused dependency paths remain informational |
| npm production audit | 0 known vulnerabilities |
| Python audits for control panel and Appium manifests | 0 known vulnerabilities |
| Gitleaks scan of current tracked and unignored source | 0 findings |
| Django control-panel tests | 21 passed |
| Flutter tests | 874 passed |
| Browser Playwright regression, including security headers, hostile Host, oversized body, sign-in, preferences, uploads, and member routes | 23 passed |
| Appium suite discovery | 77 tests collected; physical/emulated device execution remains a release activity |

Flutter static analysis still reports 622 existing information-level style and migration findings. The build and test suites pass; this lint backlog should be reduced separately so future security-relevant warnings remain easy to spot.

## Required production gates

1. Rotate or formally retire the Supabase publishable key that remains in Git history, then decide whether history rewriting is necessary. Confirm row-level security before any Supabase-backed production use.
2. Terminate TLS/WSS with current protocols at the production edge and validate redirects, HSTS, certificates, cookies, WebSockets, and large uploads through that edge.
3. Expose only the public gateway. Keep BFF diagnostics, metrics, documentation, databases, storage, media, identity, and calling infrastructure on private authenticated networks.
4. Load credentials from a managed secret store. Do not deploy repository `.env` files.
5. Make the security workflow a required branch check and add SBOM, artifact signing/provenance, container, infrastructure-as-code, and authenticated DAST checks.
6. Configure distributed rate limits, WAF or equivalent edge controls, monitoring, alerting, log retention, backup restore drills, and an incident-response owner.
7. Complete an independent penetration test covering multi-user authorization, recovery flows, discovery abuse, media and document uploads, live calls, voice recordings, and separately coordinated billing flows.

## Security boundary

The browser application uses the same-origin website proxy and does not contain server credentials. Access tokens remain in memory and refresh tokens use tab-scoped session storage; the CSP limits script origins. Any future third-party browser script must receive a security review because it would share this client trust boundary.

The public Go gateway is the external API boundary. The BFF can retain internal diagnostic and detailed error facilities only while it is unreachable from untrusted networks. Production network policy must enforce this assumption.

