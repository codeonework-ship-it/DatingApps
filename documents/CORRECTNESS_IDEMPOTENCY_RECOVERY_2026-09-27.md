# Correctness, idempotency and recovery delivery

Date: 2026-09-27  
Priority: P0/P1  
Production decision: **NO_GO pending target-environment evidence**

## Delivered locally

- **Aggregate ownership:** `platform.aggregate_ownership` assigns one component, source relation, transaction boundary and recovery strategy to each critical aggregate. `platform.aggregate_ownership_health` fails the gate if a declared relation disappears.
- **Uncertain command outcomes:** the shared idempotency store no longer takes over an expired processing lease. It returns `COMMAND_OUTCOME_UNCERTAIN`, preventing a possible post-commit duplicate. `GET /v1/operations/status` lets the authenticated actor recover a completed response or identify a command requiring authoritative-state reconciliation.
- **Client command recovery:** Flutter retries a transport-failed write once with the original idempotency key. When the server reports an uncertain outcome, the client reads the operation ledger and resolves the original request from its durable response when available.
- **Expired replay cursors:** retention deletes advance a durable per-user checkpoint. Chat and notification reconnects behind that checkpoint receive `410 REPLAY_CURSOR_EXPIRED`, a snapshot URL and a safe `resume_after` sequence.
- **Client cursor reconciliation:** a failed resumable handshake triggers one authoritative snapshot, then reconnects chat from sequence zero or notifications from the refreshed high-water mark. The guard prevents recovery loops.
- **XP repair:** transient activity-to-XP failures enter `progression.xp_award_repair_queue`. Any progression worker claims repairs with `SKIP LOCKED`, recovers abandoned leases, applies the original idempotent command, backs off retries and dead-letters after eight attempts. Cap and safety decisions are recorded as suppressed rather than retried.
- **Feature flags:** critical gifts, voice, rooms, calls, billing, quests, daily prompts, circles, group coffee, nudges, SOS and progression routes are enforced by the BFF before idempotency and mutation. A policy-store failure returns `503`; a disabled feature returns `403 FEATURE_DISABLED` even for stale clients.
- **Multi-instance behavior:** the local two-instance gate sends a duplicate-command storm, conflicting reuse, reconnect storm and sustained reads across two BFF processes.
- **Backup/restore:** an isolated local drill creates a custom PostgreSQL backup, restores it into a temporary database and verifies the latest migration and critical ledgers. The artifact is deleted after the drill; the JSON report retains timings and checks.

## Evidence from this delivery

| Gate | Result |
|---|---|
| Correctness Go and PostgreSQL acceptance | Passed |
| Full mobile BFF test package | Passed |
| Flutter idempotent recovery and cursor reconciliation tests | Passed |
| Two-instance duplicate/reconnect gate | Passed: 32 writes, one response body, 31 replays, 40 reconnects, 0 failures |
| Two-instance sustained read sample | Passed: 29,902 requests, 0% errors, p99 48.91 ms |
| Local backup/restore | Passed: 18,041,787-byte backup restored and checked in 6 seconds |
| Local reliability regression | Passed: 638 requests, 0% errors, p99 80.47 ms |
| Production capacity claim | Not made; local reports set `capacity_claim=false` |

## Remaining production acceptance

The guarded harnesses exist, but these items require a production-shaped target, named operators and retained evidence:

1. load-balanced multi-instance recovery under rolling deployment;
2. database and object-store backup restore against approved RPO/RTO;
3. database failover and additive migration rollback drill;
4. distributed capacity run with approved traffic, data skew, socket and pool model;
5. an uninterrupted 24-hour soak;
6. database, network and provider fault injection with recovery verification;
7. deployed dashboards, paging and on-call acknowledgement.

The machine-readable source of truth is [correctness_recovery.v1.json](contracts/correctness_recovery.v1.json). Contract mode verifies implementation and honest status. Launch mode stays red until every production case has passed evidence and the decision changes to `GO`.
