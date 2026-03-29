# 10M Request Scale, Concurrency & Reliability Plan

Date: 2026-03-01

## Objective
Ensure API layer remains reliable under high concurrency and burst load while preventing deadlocks, request collapse, and cascading failures.

## 1) Capacity Targets (SLO-Driven)
- Target load: 10M requests/day baseline with burst headroom to 5x.
- Availability SLO: 99.95% monthly.
- Latency SLO:
  - p50 < 120ms
  - p95 < 350ms
  - p99 < 800ms
- Error budget policy: autoscaling + feature degradation before hard outage.

## 2) Concurrency Strategy
- Keep handlers stateless; avoid shared mutable state in request path.
- Move hot mutable state from in-memory maps to durable stores with optimistic concurrency.
- Use per-resource idempotency keys for write endpoints (`swipe`, `match actions`, `agreement updates`).
- Enforce bounded worker pools for async jobs (notifications, moderation, fanout) to prevent unbounded goroutine growth.

## 3) Deadlock & Contention Prevention
- DB transaction rules:
  - Keep transactions short and single-purpose.
  - Access tables in consistent order across code paths.
  - Use row-level locking only where strictly required.
- Avoid nested lock chains in app code.
- Add lock timeout and statement timeout defaults.
- Add periodic deadlock detection alerts from DB logs.

## 4) Failure Isolation
- Circuit breakers for dependencies (Supabase, gRPC services, websocket broker).
- Timeouts everywhere:
  - incoming request timeout,
  - downstream call timeout,
  - DB statement timeout.
- Bulkheads by domain:
  - auth,
  - profile,
  - matching,
  - engagement,
  so one domain does not starve the others.
- Retries only with jitter + max-attempt cap; never retry non-idempotent calls blindly.

## 5) API Hardening Checklist
- Add idempotency token support on write-heavy endpoints.
- Standardize error envelopes with retryability hints.
- Implement request shedding for overload (`429` + `Retry-After`).
- Add adaptive rate limiting per user/IP + endpoint sensitivity tiers.
- Add schema-level unique constraints that reflect business invariants.

## 6) Data Layer Scaling
- Add indexes for high-cardinality filters and timeline queries.
- Partition largest append-only tables by date/user shard.
- Introduce read replicas for heavy read surfaces.
- Cache stable master-data and profile summary fragments with bounded TTL.

## 7) Observability & Incident Readiness
- Metrics by endpoint:
  - throughput,
  - p50/p95/p99,
  - saturation,
  - error-rate,
  - timeout-rate.
- Distributed tracing with correlation IDs across gateway -> BFF -> services.
- Alerting priorities:
  - p99 latency burn,
  - error-budget burn,
  - queue backlog growth,
  - deadlock count > 0.
- Runbooks for: dependency outage, DB lock storm, rate-limit spike, queue saturation.

## 8) Load/Soak Test Plan
- Stage 1: baseline RPS and latency curve.
- Stage 2: burst test (5x in 1 minute).
- Stage 3: 24-hour soak with realistic mixed traffic.
- Stage 4: chaos injections (dependency latency, partial failures, dropped connections).
- Acceptance gate: no deadlocks, stable p99, controlled error-rate under recovery.

## 9) Rollout Plan
- Phase A: observability + guardrails + timeout standardization.
- Phase B: idempotency + adaptive rate limiting + queue bulkheads.
- Phase C: partitioning/read replicas + regional failover strategy.

## 10) Immediate Engineering Tasks
1. Add idempotency middleware for write endpoints.
2. Add per-endpoint timeout policy table.
3. Add overload shedding path with clear client semantics.
4. Add deadlock detection dashboard and pager alert.
5. Run first burst + soak test and publish bottleneck report.
