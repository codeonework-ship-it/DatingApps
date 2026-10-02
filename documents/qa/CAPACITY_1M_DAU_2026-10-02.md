# Connect: capacity review for 1M daily active users (2026-10-02)

**Verdict.** The app cannot handle 1M DAU today. A laptop also cannot prove that it can, even after the fixes below. What the laptop does show:

- Where the per-instance ceilings are.
- That three database-level problems would stop the current design at 1M DAU no matter how many API servers are added:
  1. Every write commit is serialised by a database-wide NOTIFY lock (C1).
  2. Each API request writes about 4 rows into append-only event tables that are never cleaned up, roughly 0.5 TB/day at 1M DAU (C2).
  3. Realtime chat delivery queries the database per open socket (H2). This is partly fixed.

C1 and C2 need an owner decision. With those resolved, plus the fixes in this report and the topology in §7, 1M DAU is a reasonable target. It has to be proven in staging (§8).

Scope: Go backend (api-gateway → mobile BFF → gRPC services → PostgreSQL 17). Flutter, the website and media CDN behaviour were not measured.

---

## 1. Load model

### Assumptions

| Item | Assumption |
|---|---|
| DAU | 1,000,000 |
| Sessions per DAU per day | 5 |
| Average session length | 6 min, so about 30 min online per day |
| Average concurrency | 1M × 30 / 1440 ≈ **21k members online** |
| Peak factor | evening peak hour ≈ 2.5× the daily average, plus ≈ 1.4× burst inside the hour, so **3.5× average** |
| Design headroom | 1.5× peak, for growth, retries and a lost node |

### API requests per DAU per day

Total: about **160 API calls per DAU per day**. The read and write weights are also the request mix of the k6 scenario.

| Feature | Calls/DAU/day | Peak RPS (×40.5) |
|---|---:|---:|
| Swipes (`POST /swipe`) | 40 | 1,620 |
| Profile summary / profile views | 15 | 608 |
| Match chat send | 15 | 608 |
| Chat history (`GET /chat/{id}/messages`) | 10 | 405 |
| Notification unread-count | 10 | 405 |
| Matches list | 8 | 324 |
| Friend/room/group channel history | 5 | 203 |
| Friend/room/group channel send | 5 | 203 |
| Config flags | 5 | 203 |
| Token refresh | 5 | 203 |
| Discovery feed (20 cards/page) | 3 | 122 |
| Notification inbox | 3 | 122 |
| Today wall | 3 | 122 |
| Social channels list | 3 | 122 |
| Today curated set | 2 | 81 |
| Liked-me | 2 | 81 |
| Friends list | 2 | 81 |
| Rooms directory | 1 | 41 |
| Groups | 1 | 41 |
| Everything else (profile edits, blog, walls, reads/acks, presence…) | 20 | 810 |
| Login (fresh) | 0.1 | 4 normally; **50–100/s** in a forced re-login storm |
| **Total API** | **≈160** | **≈6,500 rps peak** |

- The average is 160M calls/day ≈ **1,850 rps**.
- **Design target: 10,000 rps** at the edge.

### Other load

| Item | Volume |
|---|---|
| **Media reads** | ≈150 photo loads per DAU per day (discovery cards, avatars, chat). That is ≈6,000 req/s at peak. At 40–150 KB per image that is 2–7 Gbit/s and 6–22 TB/day. **This must be served by a CDN, never by the BFF.** |
| Media uploads | ≈0.05 per DAU per day, about 50k/day |
| **Realtime sockets** | 21k average and ≈62k at peak (3×) per stream. The app can hold both `/realtime/chat` and `/realtime/notifications`, so **design for 100k–200k concurrent sockets**. |
| Realtime events | 20M messages/day × ≈3 outbox rows each (created/delivered/read) ≈ 60M/day, about 2,400/s at peak |

---

## 2. How it was measured

**Machine and data.**
- One MacBook (12 cores, 24 GB) runs PostgreSQL 17, all services, k6 and other agents' traffic at the same time.
- The database is the shared local database: about 2k users and 3.2 GB, of which 1.8 GB is `domain_event_outbox`.
- Absolute numbers are therefore pessimistic about CPU and optimistic about data size.

**Load generator.**
- k6 at a constant arrival rate, 15–20 s per step, sent straight to the BFF. The gateway's per-IP limit of 120 req/s would otherwise throttle one load generator.
- Fixtures: 24 synthetic members created through the real signup journey (prefix `perf1002_`).
  - 12 unlocked matches, 6 friend channels and 1 room.
  - 24 sessions at first, then 240–312 sessions created by real logins.
- At the end the members were retired through the account deletion and deactivate API.

**Before/after method.**
- "Old" is the BFF and matching-svc binaries running in the stack (`.run/local-signup-stack/bin`, built 01:19, without these changes). "New" is the working tree with these changes.
- Both were started on spare ports (BFF 18092 or 18091), **one at a time**, with identical environment, against the same database.

**Database observation.**
- `pg_stat_activity` was sampled every second.
- `pg_stat_database.xact_commit` deltas give commits per request.
- The BFF's `/metrics` gives pool waits.
- `pg_stat_statements` is not preloaded, and enabling it needs a restart, so it was not used. Hot queries were planned with EXPLAIN ANALYZE at production-like cardinality in temp tables (§5).

**Harness** (scratch, not committed): `mix.js` (weighted read/write mix), `ws.js` (idle sockets), `sessions.py` (login rate and multi-session fixtures). They follow the patterns in `qa/reliability/*` and `qa/api_e2e/client.py`.

---

## 3. Measured results

### 3.1 Baseline: the running BFF (old code), read mix, 24 sessions

| Target rps | Achieved | p50 ms | p95 ms | p99 ms | Errors | PG CPU (cores) | BFF CPU (cores) |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 100 | 100 | 2.1 | 34.6 | 55.3 | 0 | 0.3–0.4 | 0.3–0.5 |
| 300 | 300 | 1.3 | 21.7 | 27.9 | 0 | 0.5 | 0.6–0.7 |
| 600 | 600 | 0.9 | 18.6 | 24.9 | 0 | 0.7–1.1 | 0.8–1.5 |
| 1,200 | 1,198 | 2.4 | 32.5 | 62.8 | 0 | 1.5–1.6 | 2.0–2.7 |
| 2,000 | 1,988 | 36.4 | 173.9 | 274.9 | 0 | **3.8** | 3.6–4.0 |

**Discovery and Today cost the most** at every rate:

| Endpoint | p50 at 100 rps | p50 at 2,000 rps | p99 at 2,000 rps |
|---|---:|---:|---:|
| Discovery | 37 ms | 98 ms | 380 ms |
| Today | 47 ms | 135 ms | 423 ms |

Every other read had p50 ≤ 3 ms.

**Wait events at 1,500 rps** (12 samples of active backends):

| Count | Wait | Statement |
|---:|---|---|
| 31 | `Lock:object` | `UPDATE auth_sessions SET last_used_at` |
| 29 | `Lock:object` | `INSERT INTO matching.activity_events` |
| 6 | `Lock:transactionid` | session UPDATE |
| 12 | autovacuum | on `domain_event_outbox` |

`Lock:object` is PostgreSQL's database-wide NOTIFY commit lock (C1).

**Write amplification of one GET request.** 500 × `GET /profile/{id}/summary` produced:

| Rows | Table |
|---:|---|
| 2,199 | `platform.domain_event_outbox` (≈4.4 per request) |
| 548 | `auth_sessions` updates |
| 528 | `audit.change_log` |
| 528 | `audit.activity_log` |
| 488 | `matching.activity_events` |

That is about **9 commits per API request** (`xact_commit` delta).

**Connection pool.** The running BFF's main pool (`mobile/profile_repository`, hard-capped at 16) had recorded **183,847 waits totalling 1,479 s** (`verified_dating_db_pool_wait_seconds_total`).

### 3.2 Before/after, read mix, spare instances one at a time

**24 sessions (hot session rows):**

| rps | Variant | Achieved | p50 | p95 | p99 | Errors / dropped |
|---:|---|---:|---:|---:|---:|---|
| 600 | old | 600 | 1.3 | 244.7 | 530.8 | 0 / 0 |
| 600 | **new** | 600 | 0.8 | **13.1** | **22.9** | 0 / 0 |
| 1,200 | old | 1,044 | 12.6 | 1,600 | 2,368 | 0.3% / 1,503 |
| 1,200 | **new** | 1,200 | 1.0 | **20.1** | **50.6** | 0 / 0 |
| 2,000 | old | 1,589 | 37.2 | 1,736 | 2,615 | 0.24% / 4,282 |
| 2,000 | **new** | **1,997** | 1.0 | **19.5** | **49.0** | 0 / 0 |

**240 distinct sessions (closer to production):**

| rps | Variant | Achieved | p50 | p95 | p99 | Errors / dropped |
|---:|---|---:|---:|---:|---:|---|
| 1,200 | old | 1,139 | 77 | 934 | 1,308 | 0.05% / 883 |
| 1,200 | **new** | 1,184 | 0.9 | **97** | 622 | 0 / 222 |
| 2,000 | old | 1,280 | 329 | 2,223 | 3,471 | 2.5% / 7,560 |
| 2,000 | **new** | **1,664** | 5.6 | **336** | 1,311 | 0.97% / 573 |
| 3,000 | old | 1,744 | 515 | 1,476 | 1,947 | 0.07% / 17,438 |
| 3,000 | **new** | **2,353** | 32.5 | 986 | 3,011 | 7.9% / 2,885 |

**What changed:**
- Commits per request went from **8.9 to 6.7**.
- In the old runs every endpoint had the same p95 (1.1–2.5 s). That is queueing for the 16-connection pool behind lock waits, not slow SQL.
- **Single-instance ceiling on this laptop**:
  - Old: about **1,100–1,300 rps** with p95 under 1 s.
  - New: about **1,700–2,000 rps** with p95 under 350 ms.
  - New, comfortably: about **1,200 rps** with p95 under 100 ms.
- At saturation the laptop is CPU-bound: PostgreSQL about 3.3 cores, BFF about 4 cores, plus k6 and the other services on the same 12 cores.
- The `Lock:object` waits (C1) remain in the new runs: 12–27 backends were waiting at peak.
- The old spare did worse than the long-running stack BFF at the same rates (§3.1). Likely causes are a cold pool combined with connection churn (MaxIdleConns=2/4, fixed) and other agents' load at the time. Read the old columns as "this code under this contention", not as a precise baseline.

### 3.3 Realtime: 300 idle chat websockets held for 25 s (separate sessions)

| Variant | DB commits/s (background ≈ 54–66/s) | Connect p50 / p95 / p99 |
|---|---:|---|
| old (per-socket 400 ms polling) | **1,929** | 72 / 192 / 236 ms |
| **new** (shared wake hub) | **352** (includes the spare BFF's own workers) | 19 / 58 / 85 ms |

- Old: about **6.2 queries/s per idle socket**. At 62k–200k sockets that is **385k–1.2M queries/s**, more than one PostgreSQL primary can serve.
- New: about **0.4 queries/s per idle socket** (session check + read on the 5 s fallback poll), plus one 0.5 ms scan per instance every 400 ms.

### 3.4 Writes, login and refresh

**Writes, with Free-plan quotas disabled** (`BILLING_ENFORCE_DAILY_LIMITS=false`, spare only), mix of swipe 40 : chat 20 : channel 5:

| rps | Variant | p50 | p95 | p99 |
|---:|---|---:|---:|---:|
| 600 | old | 1.8 | 3.2 | 5.6 |
| 600 | new | 1.3 | 2.9 | 41 |

- Both sustain 600 rps.
- One cold old run at 300 rps stalled: p95 3.4 s, 54 lock waiters. That shows how the NOTIFY lock behaves when commits queue.
- Channel sends were mostly rejected by the per-sender rate limit, which is product policy. With quotas on, Free members are limited to 5 messages/day and the extra sends fail fast with 429.

**Login** (bcrypt cost 10 in auth-svc, 12 concurrent clients):
- **136–178 logins/s**, p50 63–82 ms, p95 94–125 ms, on the laptop.
- A forced re-login of 20% of peak users within 10 minutes is about 20/s, which is fine. A mass re-login after an outage needs auth-svc on several cores; budget about 25 logins/s per core.

**Refresh** runs in a SERIALIZABLE transaction with FOR UPDATE of the session. It was not load-tested beyond functional calls; 203 rps at peak is low.

---

## 4. Fixes made in this change

All fixes are small, low-risk and tested. `cd backend && go build ./... && go test ./...` passes. The DB-backed tests also pass with `PROFILE_TEST_DATABASE_URL` pointed at the local database.

| # | Fix | Files | Tests |
|---|---|---|---|
| F1 | **Gateway rate limit keyed on the real client.** `httprate.LimitByIP` keys on `RemoteAddr`. Behind nginx (`deploy/nginx/connect.conf` → 127.0.0.1:8080) that put *every member in the world into one 120 req/s bucket*. The key is now `X-Real-IP`, trusted only from loopback or `GATEWAY_TRUSTED_PROXY_CIDRS`. A spoofed header from an untrusted peer is ignored. IPv6 is grouped per /64. | `internal/gateway/http/server.go`, `cmd/api-gateway/main.go`, `internal/platform/config/config.go` | `internal/gateway/http/server_rate_limit_key_test.go` |
| F2 | **Gateway → BFF connection reuse.** The reverse proxy used `http.DefaultTransport`, which keeps 2 idle connections per host, so nearly every proxied request opened a new TCP connection. It now uses a dedicated transport: 1,024 idle connections per host, 90 s idle timeout, and no response-header timeout so realtime streams are not cut. | `internal/gateway/http/server.go` | same file |
| F3 | **Session check is 1 round trip, and `last_used_at` is written at most once a minute.** Before: 3 round trips per authenticated request (session, roles, UPDATE). The UPDATE ran on every request, creating a dead tuple, WAL and a captured domain event, and it took a row lock that concurrent requests of the same session queued on. Now roles come in the same SELECT and the UPDATE is guarded by `sessionTouchDueSQL`: older than 60 s, or the first request of a new UTC day, which keeps the DAU triggers of 087/123 exact. | `internal/bff/mobile/server_security.go` | `capacity_session_touch_test.go` (DB) |
| F4 | **Realtime wake hub.** One shared change detector per BFF instance and stream (`realtime_outbox`, `user_notifications`). It reads new rows from the last ≈2k sequences and 10 s, grouped by recipient, every 400 ms, and wakes only those members' sockets. The socket still runs the authoritative per-user query and session check, so visibility and revocation rules are unchanged. There is a 5 s fallback poll for late commits and hub errors. It works across instances because every instance reads the shared outbox. Without a database (tests) the socket keeps the old 400 ms poll. | `internal/bff/mobile/realtime_wake_hub.go`, `server_chat_realtime.go`, `server_notification_realtime.go`, `server.go` (wiring and Close) | `realtime_wake_hub_test.go`, existing realtime tests, `-race` |
| F5 | **Primary pool follows `POSTGRES_POOL_MAX_CONNS`.** The pool that carries almost all request SQL was hard-capped at 16. Raising the env var, as `MONITORING_RUNBOOKS_2026-10-01.md` advises, could only lower it. It is now `max(16, POSTGRES_POOL_MAX_CONNS)`; the default is unchanged at 16. | `internal/bff/mobile/repository_data_access.go`, `profile_repository.go` | `capacity_pool_test.go` |
| F6 | **database/sql pools keep idle connections.** `SetMaxIdleConns(MinConns=2–4)` made every burst close and reopen backends. Idle is now kept up to MaxConns and still reaped after 5 idle minutes. Trade-off: steady-state connection count per instance is higher, which is one more reason for PgBouncer (§7). | `internal/platform/postgresdata/sql.go` | `client_test.go` (`TestSQLPoolLimits…`) |
| F7 | **Matches list no longer downloads whole chat histories.** The last-message preview fetched *every message of every match*, sorted, and kept one per match in Go. It is now one `LATERAL … LIMIT 1` probe per match (index `idx_messages_match_time`). Unread counts are now `GROUP BY` in SQL instead of one row per unread message. The hosted PostgREST mode keeps the old path. New `postgresdata.Client.QueryRows` for fixed, caller-written SQL. | `internal/services/matching/match_previews_native.go`, `service.go` (2 hooks), `internal/platform/postgresdata/client.go` | `match_previews_native_test.go`, including a DB test proving identical results to the old queries |
| F8 | **Notification queue gauges throttled to once per 15 s per instance.** They were refreshed after every batch on every worker. `notification_queue_metrics` counts the whole outbox: 67 ms per run at 1M rows. | `internal/bff/mobile/notification_worker.go` | `capacity_pool_test.go` |
| F9 | **Migration `129_capacity_hot_path_indexes.sql`** (additive, `CREATE INDEX CONCURRENTLY IF NOT EXISTS`, no transaction). Applied to the local database and registered in `backend/scripts_run_order.txt` and the `migrate_local_postgres.sh` list. Indexes: `matching.messages(sender_id, created_at DESC)` for the daily message quota count on every send; `matching.notification_outbox(updated_at, id) WHERE status IN ('delivered','suppressed','dead_letter')` for the 5-minute retention sweep. | `backend/scripts/129_capacity_hot_path_indexes.sql` | plans in §5 |

---

## 5. Query plans at production-like cardinality

Temp tables; methodology as in `qa/reliability/production_cardinality_query_plans.sql`.

| Query | Before | After |
|---|---|---|
| Match previews, 30 matches × 100 messages (2M-row table) | bitmap scan of 3,000 rows + sort, **1.33 ms**, 3,000 rows to Go | LATERAL LIMIT 1, **0.12 ms**, 30 rows |
| Daily message quota count (2M rows, 30 days) | **Seq Scan, 87.5 ms** (grows with table size; ≈20M rows/day at 1M DAU) | Index Only Scan, **0.024 ms** |
| Notification retention, 1M-row outbox | Seq Scan + sort, **105 ms** | Index Only Scan, **0.14 ms** |
| Queue metrics full count, 1M rows | Seq Scan, **67 ms** after every batch | unchanged SQL, run once per 15 s |
| Wake-hub scan, 1M-row realtime outbox | n/a | PK range scan of 2,048 rows, **0.52 ms**, once per 400 ms per instance |
| Per-socket poll | 0.009 ms of SQL, but a pool checkout and round trip 2.5×/s per socket | about 0.2×/s per idle socket |

---

## 6. Bottlenecks found

| ID | Severity | Status | Finding | Recommended fix |
|---|---|---|---|---|
| **C1** | **Critical** | **Open (owner decision)** | `platform.publish_domain_event()` (075) calls `pg_notify('domain_events', …)` for **every captured row change on about 190 tables**. PostgreSQL serialises the commit of every transaction that issued NOTIFY behind one **database-wide lock**. That is the top wait event under load (`Lock:object` on `activity_events` INSERT and `auth_sessions` UPDATE). It caps total write commits for the whole database at roughly 1/(commit+fsync) no matter how many cores it has, and every API request writes. **Nothing LISTENs** on `domain_events`: no Go listener, and the control panel reads the table. | Replace the function without the `PERFORM pg_notify(...)`; the 075 comment already calls it "a low-latency hint only". I prepared this as part of migration 129, but changing a shared database function was not permitted in this session, so 129 ships only the indexes. Needs the owner's approval. If a hint is ever needed, use one NOTIFY per transaction from the application, or a poller. |
| **C2** | **Critical** | Open | **Write amplification and unbounded growth.** One read request writes ≈1 `activity_events` row, ≈4.4 `domain_event_outbox` rows, and until migration 125 is applied, `audit.change_log` + `audit.activity_log` copies. `domain_event_outbox` is append-only (DELETE is rejected by trigger), has 6 indexes, and has no retention: 2.0M rows / 1.8 GB locally after a few days of QA. At 1M DAU that is about **600–700M rows/day (≈0.5 TB/day)** of WAL, vacuum and storage. | (a) Apply 125 (owner-approved, not yet applied locally). (b) Unregister telemetry tables from event capture: `matching.activity_events`, and `auth_sessions` updates that touch only `last_used_at`. (c) Partition `domain_event_outbox` by day, with retention by dropping partitions after consumers' checkpoints pass. (d) Batch or sample request telemetry (one multi-row INSERT per 100 ms). |
| C3 | Critical | **Fixed (F1)** | The gateway's per-IP limit keyed on nginx's loopback address, so the whole service was limited to 120 req/s. | Also: per-IP limits will hurt carrier CGNAT, where thousands of members share an IP on Indian mobile networks. Add a per-member (token) limit and raise the per-IP limit at the edge. |
| H1 | High | **Fixed (F3)** | 3 round trips plus 1 write per authenticated request. | Optional next step: cache principals for 5–10 s in-process, with revocation fan-out. |
| H2 | High | **Mostly fixed (F4)** | Per-socket polling at 400 ms: 2 queries per tick per socket. | At 200k sockets the 5 s fallback still costs about 80k q/s. At scale raise the fallback to 30 s and re-check the session every 30 s (about 13k q/s), or move to Redis pub/sub or NATS for wakes. Also put realtime on dedicated instances (§7). |
| H3 | High | **Fixed (F5, F6)** | The main pool was hard-capped at 16 (1,479 s of waits) and database/sql idle churn reopened connections. | Size per §7, behind PgBouncer. |
| H4 | High | **Fixed (F7)** | The matches list loaded all messages. | `ListMatches` itself still has **no LIMIT or pagination** (Medium, open). |
| H5 | High | Open | **Discovery** costs about 20 DB round trips and up to 300 candidate rows of JSON per request (≈1,500 JSON operations), and is the slowest endpoint (p50 15–37 ms idle, 98 ms at 2k rps). Specific problems: no gender, age or geo filter in SQL (it fetches the newest 900 users for everyone and filters in Go, which is a global hot set and an empty deck once those are liked); passes are never excluded; the trust filter is N+1 (up to 300 queries); the **Spotlight counters are read-modify-write upserts on one global row per tier on every discovery and swipe**, causing lost updates and row-lock contention, with deadlock risk from map-ordered multi-row upserts. | Push filters into SQL using `idx_users_discovery_active_cover`, with a keyset cursor. Exclude all swipes with an anti-join. Batch trust badges. Make counters atomic `INSERT … ON CONFLICT DO UPDATE SET n = n + EXCLUDED.n` with sorted keys, or aggregate in memory and flush every few seconds. Cache candidate pools per (city, gender, age band) for about 60 s. |
| H6 | High | Open | **Today curated set** re-runs the whole discovery pipeline on every request (p50 23–54 ms; 135 ms at 2k rps). The first request of each member's day runs `percentile_cont` over the whole `member_reply_signals` table. | Serve the stored daily set when it exists. Compute the percentile once per day in a job. |
| H7 | High | **Fixed (F9)** | Message quota COUNT had no sender index. | — |
| H8 | High | **Fixed (F8, F9)** | Queue metrics full scan per batch; retention sort over the whole outbox. | — |
| H9 | High | Open | `realtime_outbox` retention deletes 1,000 rows per 5 min per instance (≈288k/day) against ≈60M rows/day written. Rows live 60 days. Each delete also fires a per-row checkpoint trigger. | Partition by day and drop partitions, or raise the batch to 50k with a 10 s loop on one elected worker. A realtime TTL of 7 days is plenty. |
| H10 | High | Open (deploy) | **PgBouncer compatibility.** `statement_timeout`, `lock_timeout`, `idle_in_transaction_session_timeout` and `TimeZone` are set as connection startup parameters (`postgresdata.setRuntimeTimeout`), and PgBouncer transaction pooling drops them. pgx caches prepared statements. The analytics snapshot uses a session-level advisory lock. | Set the timeouts with `ALTER ROLE … SET`. Use PgBouncer ≥ 1.21 with `max_prepared_statements`, or pgx `QueryExecModeCacheDescribe`. Run the analytics worker on a direct (session) connection. |
| M1 | Medium | Open | Social channels: `GET /social/channels` is N+1, up to about 900 round trips in the worst case. Unread counts scan the whole history when a channel was never read. Send holds `FOR UPDATE` on the sender's `users` row and updates a hot `social_channels` row, then loops `enqueue_notification` per recipient inside the transaction (up to 199). | One query with LATERAL per kind, a default `last_read_at`, and set-based enqueue after commit. |
| M2 | Medium | Open | `/rooms` always reads 500 rooms with correlated COUNTs. `/engagement/groups` discover orders by a correlated COUNT over all groups plus `ILIKE '%q%'`. | Maintain counters, apply LIMIT in SQL, add a trigram index. |
| M3 | Medium | Open | Chat history has no `before` cursor; only the newest N messages are reachable. | Keyset pagination on `(created_at, id)`. The covering index already exists. |
| M4 | Medium | Open | Request telemetry is one INSERT per request, with 4 indexes and 3 FKs (see C2). | Batch writes. |
| M5 | Medium | Open | Feature flags: a PK lookup per gated request, with no cache. | 2–5 s TTL cache. |
| M6 | Medium | Open | Workers run on every BFF instance: retention, billing sweeps without LIMIT, hourly media cleanup over an unbounded UNION, and analytics snapshots doing full scans of messages, swipes and matches. | Dedicated worker instances with leader election. Bound every sweep. |
| M7 | Medium | Fixed (F2) | Gateway transport kept only 2 idle connections. | — |
| L1 | Low | Open | Login skips bcrypt for unknown usernames, a timing oracle for username enumeration (security, not capacity). | Compare against a dummy hash. |

---

## 7. Production topology for 1M DAU

Per-instance figures are from §3, derated for production data sizes, TLS and the fact that the laptop shares cores.

| Tier | Sizing | Notes |
|---|---|---|
| Edge | CDN in front of nginx | All photos go through the CDN with resized variants (thumbnails ≤ 40 KB). Keep the `X-Accel-Redirect` authorisation, but give public approved media signed, cacheable URLs; otherwise 6k img/s reaches the BFF. Set `real_ip_header` so `X-Real-IP` is the member, not the CDN, and list the LB/CDN ranges in `GATEWAY_TRUSTED_PROXY_CIDRS`. |
| nginx / LB | 2 × 4 vCPU | TLS, HTTP/2, websocket upgrade. Raise `worker_connections` to ≥ 65k and `ulimit -n` to 1M on realtime nodes. |
| api-gateway | 2 × 2 vCPU, or merge into nginx | Stateless; the rate limit is in-memory per instance, so move it to Redis for exact global limits. |
| **API BFF** | **8 × 4 vCPU / 8 GB** (N+2) for 6.5k rps peak, 10k design | Laptop: about 500 rps per BFF core at saturation. Budget 300 rps per core in production, so about 25–30 cores. |
| **Realtime BFF** (same binary, realtime routes only) | **4 × 4 vCPU / 16 GB**, about 50k sockets each, 200k total | Route `/v1/realtime/*` to these. Wake hubs per instance: about 2.5 scans/s each. |
| gRPC services | auth 3 × 4 vCPU (bcrypt; login storms); matching, profile, chat 2 × 4 vCPU each | Stateless. |
| Workers | 2 × 2 vCPU | Notification delivery (≈20M+ jobs/day; `NOTIFICATION_WORKER_COUNT` 8, batch 100), retention, analytics. Disable workers on API nodes. |
| **PgBouncer** | 2 × 2 vCPU, transaction mode | Clients: up to 8 BFF × (16–32 + 16 + 8) + services. Server side: `default_pool_size` 80–120 on the primary, 50 per replica. Fix H10 first. |
| **PostgreSQL primary** | 32 vCPU, 128–256 GB RAM, NVMe (≥ 50k IOPS), `max_connections` ≈ 300 | Only realistic after C1 and C2. Laptop: about 650 rps per PG core on a tiny dataset; budget 250–300 per core at production size, with replicas taking the reads. `shared_buffers` 25% of RAM, `wal_compression=on`, aggressive autovacuum on outbox, session and telemetry tables, and partitioning for messages, swipes and the outboxes. |
| **Read replicas** | 2 × 16–32 vCPU | Discovery, Today, profile and public profile, matches list, history reads. Route reads through the existing `SelectRead` / read-replica URL. Replica lag must be under 1 s for chat history. |
| Cache | Redis, 2 × 4 GB | Principals (5–10 s), feature flags, candidate pools, rate limits, realtime wake pub/sub at the 200k-socket scale. |
| **Monitoring alerts** | (`deploy/monitoring`) | Add or confirm alerts for:<br>• `verified_dating_db_pool_wait_seconds_total` rate > 1 s/s<br>• p99 per route > 500 ms for 5 min<br>• 5xx > 1%<br>• gateway 429 rate<br>• Postgres: lock waiters > 10, `Lock:object` waits > 0 (C1 canary), commits/s, WAL MB/s, replication lag > 2 s, autovacuum age, table growth of `domain_event_outbox`, `realtime_outbox`, `notification_outbox` and `activity_events`<br>• realtime: open sockets per node, delivery lag p95 > 2 s, `realtime_wake_scan_failed` log rate<br>• notification queue depth and oldest pending age<br>• worker heartbeats<br>• disk > 75% |

Rough monthly egress: 6–22 TB/day of media decides CDN cost far more than compute does.

---

## 8. What a laptop cannot prove, and how to prove it

**What a laptop cannot prove:**
- A database with 1M users, about 100M swipes and about 500M messages: plan shapes, cache hit ratios, vacuum and index bloat.
- Multi-node behaviour: PgBouncer, replicas and their lag, LB/CDN, cross-instance realtime, and N BFFs sharing pools.
- 200k concurrent sockets: file descriptors, memory, LB limits.
- WAL and fsync throughput on real disks, which is exactly where C1 bites.
- Long-run effects: table growth, retention keeping up, autovacuum, 24 h soak.

**Staging plan.** Run it after C1, C2, H5 and H10 are fixed; each step gates the next.

1. **Data.** Build a production-shape database with a generator, not production data:
   - 1.2M users across cities and genders, 120M swipes, 12M matches, 600M messages
   - 60 days of outboxes at the modelled rates
   - `ANALYZE`, then run `qa/reliability/run_query_plan_gate.sh` and the §5 queries against it.
2. **Topology.** Deploy §7 at half scale (4 API BFFs, 2 realtime BFFs, primary + 1 replica, PgBouncer), using the same instance types as production.
3. **Load.** Distributed k6 from 4–8 generators in-region, with 50k synthetic members holding real sessions:
   - Weighted model mix from §1. Ramp 1k → 6.5k rps over 30 min, hold 30 min.
   - **Pass criteria:**
     - p95 < 300 ms and p99 < 800 ms for reads; p95 < 500 ms for writes
     - errors < 0.5%
     - PG CPU < 70%, pool waits < 50 ms p99, replication lag < 1 s
   - Then a spike to 10k rps for 5 min.
4. **Realtime.** Ramp to 100k chat sockets plus 100k notification sockets across the realtime nodes (k6 `ws` or a Go client). Send 2,400 events/s.
   - Pass criteria: delivery lag p95 < 1 s; DB queries from realtime < 15k/s.
   - Then kill one realtime node and verify reconnect and replay (`distributed_scale_gate.py --profile distributed-burst`).
5. **Soak.** 24 h at about 3k rps (`distributed_scale_gate.py --profile production-soak`). Verify:
   - table sizes plateau (retention keeps up)
   - no connection or memory growth
   - autovacuum keeps dead tuples under 10%
6. **Failure drills.** Primary failover, PgBouncer restart, Redis loss, and a mass re-login (100 logins/s for 10 min).

A per-instance number from staging, multiplied by the instance count with 30% headroom, is the capacity claim to sign. The laptop figures here only rank the bottlenecks and show the fixes help.

---

## 9. Reproducing the measurements

- Synthetic members: the signup journey from `qa/api_e2e/client.py`, prefix `perf1002_` (retired afterwards).
- k6: constant-arrival-rate weighted mix; per-op `http_req_duration{op:…}` thresholds give per-endpoint p50/p95/p99.
- Spare BFFs: source `backend/config/.env.local-postgres.example`, then override `MOBILE_BFF_ADDR`, `MATCHING_SVC_GRPC_ADDR`/`_ADMIN_ADDR` and `PROGRESSION_AWARD_SPOOL_PATH`.
  - Run **one spare at a time**: each BFF holds up to about 40 connections and the local `max_connections` is 100. Two spares plus the stack hit "too many clients" during this review for a few seconds.
- DB: `pg_stat_activity` per second, `pg_stat_database.xact_commit` deltas, and the BFF `/metrics` pool counters.
