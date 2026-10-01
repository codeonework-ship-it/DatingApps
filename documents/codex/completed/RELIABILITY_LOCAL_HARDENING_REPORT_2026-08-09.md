# Reliability Local Hardening Report

Date: 2026-08-09  
Epic: Reliability, idempotency, observability, and load engineering (rank 11)  
Result: Local native-PostgreSQL hardening implemented; production scale gate remains

## Implemented

- Fast-read, normal-read, and write timeout tiers with response headers,
  structured timeout events, and bounded Prometheus labels.
- PostgreSQL statement, lock, and idle-transaction limits on the shared pgx
  pool and every direct `database/sql` pool, with bounded pool sizing.
- SQLSTATE classification for statement timeout, lock timeout, and deadlock.
- Idempotent replay and bulkhead-shed metrics; durable notification queue depth,
  age, processing, dead-letter, and batch-failure metrics.
- Migration 058 covering active matches, chat reconnect, discovery, moderation,
  and notification claims. It is applied and recorded locally.
- Provisionable Grafana dashboard and Prometheus alert rules with runbook links.
- Race-enabled timeout, idempotency, and bulkhead tests.
- Loopback-only authenticated smoke/burst/soak harness that treats HTTP 429 as
  a failure and explicitly refuses to make a capacity claim.
- Unified release regression now requires migration 058 and runs the reliability
  smoke gate by default.

## Verification

- Complete Go suite: passed.
- Backend compliance: passed.
- Flutter: 471 tests passed.
- Flutter analyzer error gate: passed; 370 existing catalog/lint findings remain.
- Django control panel: 7 tests passed.
- Auth retirement contract: passed.
- Authenticated native-PostgreSQL API preflight: 4 tests passed.
- Race-enabled reliability suite: passed.
- Release reliability sample: 624 requests, 16 workers, 80 target RPS, 0 errors,
  p99 28.21 ms, with fast-read and normal-read tiers both observed.
- Full release regression: passed.
- Backend stack remains running on gateway `:18080`, BFF `:18081`, and local
  PostgreSQL `:55432`; no Docker or Supabase runtime was used.

## Explicit residuals

- Shared cross-instance idempotency and complete critical-write coverage.
- Production-cardinality query-plan and partition/retention proof.
- Deployment of the committed dashboard/alerts and paging integrations.
- Distributed burst, 24-hour soak, duplicate/reconnect storm, failover, and
  chaos evidence in a production-shaped environment.
- A reviewed capacity model and signed SLO results before any 10M claim.

The architecture, configuration, lock order, rollback guidance, incident
runbooks, and commands are in
`documents/RELIABILITY_SCALE_GUARDRAILS_LOCAL_POSTGRES.md`.
