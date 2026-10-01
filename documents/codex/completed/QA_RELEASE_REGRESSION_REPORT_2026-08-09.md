# QA Automation and Release Regression Completion Report

Date: 2026-08-09

## Outcome

The P1 QA automation and release-regression engine is implemented for the
username/password, native-local-PostgreSQL release boundary. Runnable mobile QA
no longer depends on phone numbers, OTP endpoints, OTP selectors, or OTP bypass
flags.

## Implemented gates

- An executable retired-auth ratchet scans all runnable Appium configuration,
  helpers, fixtures, runners, and test modules.
- Credential signup covers account creation, terms acceptance, two validated
  photo uploads, bio, preview, profile completion, and arrival in discovery.
- The security-negative journey proves that a duplicate username is rejected
  by the backend and does not create an authenticated session.
- The core device journey covers username/password sign-in, discovery, an
  existing durable match, persisted chat, background/foreground recovery, and
  application restart/resume.
- `qa/run_release_regression.sh` rejects non-local and Supabase database URLs,
  verifies migration 057 and required tables, then gates Go, backend compliance,
  Flutter tests/analyzer errors, Django, authenticated API preflight, and the
  optional Android release profile.

## Verification evidence

| Gate | Result |
|---|---|
| Appium test collection | 63 tests collected |
| Android release profile | PASS: 4 passed, 59 deselected |
| Flutter | PASS: 471 tests |
| Go and backend compliance | PASS |
| Django control panel | PASS: 7 tests |
| Local PostgreSQL API preflight | PASS: signup/login/refresh/logout |

The Android HTML report is written to
`qa/reports/appium/android-smoke.html`. Release-gate logs are written under
`qa/reports/release/`.

## Remaining non-blocking work

- The Flutter analyzer reports 370 existing catalog/lint findings, including
  one warning. Analyzer errors remain gated; this known warning/info backlog is
  currently non-fatal and should be reduced separately.
- Historical reports may retain phone/OTP evidence for traceability. They are
  not executable inputs, and the static ratchet prevents those assumptions from
  returning to runnable automation.
- Broader safety, engagement, and admin device matrices remain feature-coverage
  expansion; they are not gaps in the completed authentication/core journey
  release gate.
