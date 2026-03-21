# Phase 1 - Story 1.1 Android Emulator Runbook & Readiness Checks

Date: 28 Feb 2026
Story: Epic 1 / Story 1.1 (5 SP)

## Scope
This runbook satisfies Story 1.1 acceptance criteria:
1. Emulator startup checklist exists and is validated.
2. API base URL for emulator uses `10.0.2.2`.
3. Known failures (ADB offline, gateway 503, Supabase schema exposure) have recovery steps.

## Startup Checklist (Validated)

### A) Backend
1. From project root, start backend stack:
   - `cd backend`
   - `make run-all`
2. Verify gateway health:
   - `GET http://localhost:8080/healthz`
   - `GET http://localhost:8080/readyz`
3. Verify BFF health:
   - `GET http://localhost:8081/healthz`
   - `GET http://localhost:8081/readyz`

### B) Android Emulator
1. Start Android emulator (for example `Medium_Phone_API_36.1`).
2. Verify ADB device visibility:
   - `adb devices`
   - Expect `emulator-5554` in `device` state.

### C) Flutter App
1. From app folder:
   - `cd app`
   - `flutter pub get`
   - `flutter run -d emulator-5554`
2. Confirm app API entrypoint resolves to gateway via emulator host mapping:
   - `http://10.0.2.2:8080/v1`

## API Base URL Requirement
- Android emulator base URL: `http://10.0.2.2:8080/v1`
- Source reference: `backend/README.md` documents emulator base URL.

## Known Failure Recovery

### 1) ADB Offline / Device Offline
Symptoms:
- `adb: device offline`
- Flutter deploy/install fails.

Recovery:
1. `adb kill-server`
2. `adb start-server`
3. Re-check with `adb devices`
4. If still offline, restart emulator and re-run `flutter run -d emulator-5554`.

### 2) Gateway/BFF 503 or 502 from app
Symptoms:
- `/readyz` returns `503`.
- App receives `502` from backend routes.

Recovery:
1. Check for stale process/port conflict on `8080`/`8081`.
2. Stop old processes, then restart stack:
   - `make stop-all`
   - `make run-all`
3. Re-validate readiness endpoints before app launch.

### 3) Supabase Schema Exposure Errors
Symptoms:
- Error like `PGRST106 invalid schema user_management`.

Recovery:
1. Verify Supabase schema/API exposure settings include required schema.
2. Confirm service role / anon access policy alignment for expected calls.
3. Re-test endpoint after schema exposure fix.

## Validation Notes
- Emulator startup, backend startup, and endpoint troubleshooting have been executed in development flow.
- This document is the canonical runbook for Story 1.1 acceptance and handoff.
