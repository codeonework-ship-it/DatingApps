# Reliability, Idempotency, Observability, and Load — Scale Gate Report

Date: 2026-08-09  
Priority: P2 — scale gate  
State: local implementation complete; production proof pending

## Completed in this implementation

- Shared PostgreSQL idempotency claims, request fingerprints, response replay,
  payload-conflict rejection, owner leases, and crashed-owner takeover.
- Default coverage for every authenticated mutating route, with explicit
  credential-issuance/recovery and multipart-media exclusions.
- Flutter HTTP-client key injection for the same authenticated command surface,
  preserving explicit domain keys and authorization retries.
- OpenAPI `Idempotency-Key` contract coverage enforced against registered routes.
- Monthly partitioned idempotency archive and bounded `SKIP LOCKED` retention
  for idempotency, terminal notification, and expired realtime rows.
- Production-shape query-plan gate for chat resume, notification claims,
  idempotency lookup, and retention.
- Prometheus metrics/alerts for idempotency health, conflicts, retention, and
  PostgreSQL pool use; Grafana panels/datasource and Alertmanager paging template.
- Distributed harnesses for duplicate storms, WebSocket reconnect storms,
  sustained burst/soak, and approval-gated failover/chaos hooks.
- A production-soak profile that cannot be shortened below 24 hours and refuses
  loopback targets.

## Local evidence

| Gate | Result |
|---|---|
| Go unit/contract suite | Passed |
| Go race suite (mobile BFF, config, postgresdata, observability) | Passed |
| Flutter analysis for shared API client | Passed, zero findings |
| Migration 063 applied to local PostgreSQL | Passed |
| Retention archive transaction proof | Passed; one expired row archived, source removed, transaction rolled back |
| Query plans | Passed at 250,000 rows per workload; no critical sequential scans |
| Cross-instance duplicate storm | 32/32 HTTP 200, 31 replays, one response body, one PostgreSQL record |
| Payload/key conflict | HTTP 409 |
| WebSocket reconnect storm | 40/40 successful |
| Cross-instance sustained local burst | 56,893 HTTP 200, 0% error, p99 22.95 ms over 15 seconds |
| Local authenticated reliability smoke | 639 HTTP 200, 0% error, p99 37.0 ms at target 80 RPS |

These numbers are bounded local regression evidence and are not production
capacity evidence.

## Production proof still required

1. Provision Prometheus, PostgreSQL exporter, Grafana, Alertmanager, and real
   on-call/ticket receivers; test page delivery and resolution.
2. Run the distributed-burst profile against at least two load-balanced BFF
   instances with production-cardinality/skewed data and captured query stats.
3. Run the non-shortenable 24-hour soak and validate SLO/error-budget reports.
4. Execute duplicate/reconnect storms during rolling deploy, database failover,
   network impairment, and provider degradation.
5. Execute the approval-gated chaos wrapper with environment-owned failover and
   recovery hooks, then verify no duplicate domain/provider side effects.
6. Measure table/index growth before approving online repartition of any hot
   message, notification, or realtime table.
7. Obtain capacity-model and SLO sign-off before making a scale claim.

## Commands

```bash
./qa/reliability/run_local_reliability_gate.sh
./qa/reliability/run_cross_instance_idempotency_gate.sh
SCALE_API_BASE_URLS=https://target-a/v1,https://target-b/v1 \
  python3 qa/reliability/distributed_scale_gate.py --profile production-soak
```

The chaos gate additionally requires `SCALE_ALLOW_CHAOS=true` and absolute,
executable `SCALE_CHAOS_HOOK`/`SCALE_RECOVERY_HOOK` paths.
