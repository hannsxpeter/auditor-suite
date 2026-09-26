# SCALE: Scalability, Growth and Operations

Weight 2. Always active. The weight is low, so scale risk shows through severity: the cards rise to High or Critical when the code or README shows real growth.
Owns: capacity and operability over time: key-space exhaustion, retention, partitioning, hot rows, connection capacity and pooler modes, replica lag on read-after-write paths, maintenance, observability, and backup posture.
Not here: OFFSET pagination and unbounded result sets (QUERY-R3, QUERY-R2); random UUIDv4 primary keys (TYPES-R3); the statement timeout itself (QUERY-R7); irreversible destructive migrations (MIGRATION-R3); a foreign key column left `INT` after its parent became `BIGINT` (INTEGRITY-R5).
Standards: PostgreSQL docs (partitioning, routine vacuuming, sequences), PgBouncer docs, Designing Data-Intensive Applications (Kleppmann), ch. 5 and 6.
Read first: the growth-bearing tables in the Map and any stated row counts, the scheduler or cron config, the connection and pool setup, the deployment model (serverless, autoscaled containers, fixed servers), and read-routing config.

## Cards

### SCALE-R1 32-bit auto-increment key on a table that grows without bound (quick)
- Leads: `scan.sh SCALE-R1` lists `SERIAL`, 32-bit identity and auto-increment keys, and ORM defaults that create them.
- Confirm: a primary key is 32-bit (`SERIAL`, `INT AUTO_INCREMENT`, `INTEGER IDENTITY`, Knex `increments()`, Django `AutoField`, Prisma `Int @id @default(autoincrement())`, TypeORM `@PrimaryGeneratedColumn()`, Sequelize's default `id`) on a high-churn table (events, logs, messages, orders, line items), so inserts fail at 2,147,483,647; referencing foreign key columns mirror the width.
- Not a finding if: the table is small or slow-growing (plans, users of an internal tool); the key is `BIGINT`, `BIGSERIAL`, `bigIncrements`, or `BigAutoField`.
- Severity: Critical when code, comments, or docs show the sequence is already far along (hundreds of millions, a past sequence reset, a comment about the limit); High on high-churn tables; Low otherwise.
- Fix: migrate the key and every referencing column to `BIGINT` through expand-contract (new column, trigger or dual-write, batched backfill, swap under a short lock); new tables use `BIGINT GENERATED ALWAYS AS IDENTITY`.
- Verify the fix: the catalog shows `bigint` for the key and every referencing column, and the sequence has headroom.
- Refs: PostgreSQL docs, Numeric Types and Sequences; Squawk prefer-bigint-over-int

### SCALE-R2 Table that only grows, with no retention
- Leads: `scan.sh SCALE-R2` lists event, log, audit, session, notification, and outbox tables, and retention jobs.
- Confirm: a table that only grows (events, logs, audit, sessions, notifications, outbox, webhook deliveries, job history) has no scheduled delete or archive, no TTL, and no partition drop, and nothing states how long rows are kept.
- Not a finding if: a retention job exists (cite the scheduler entry and the query); law or policy requires keeping the rows and the table is partitioned (SCALE-R3).
- Severity: High when the table sits on the request path (sessions, events) or is already large; Medium otherwise.
- Fix: a documented retention window and a batched reaper (`DELETE FROM events WHERE id IN (SELECT id FROM events WHERE created_at < now() - interval '90 days' LIMIT 5000)` in a loop), or `DETACH PARTITION` and `DROP` on a partitioned table.
- Verify the fix: the scheduler lists the reaper, and the row count stays flat week over week.
- Refs: PostgreSQL docs, Table Partitioning (partition maintenance)

### SCALE-R3 Large append-only table without partitioning, or partitions maintained by hand
- Leads: `scan.sh SCALE-R3` lists partitioning statements and hypertable calls.
- Confirm: a large time-series or append-only table (events, metrics, audit) is a plain table, so purges are full-table deletes and queries cannot prune by time; or it is range-partitioned but future partitions are created and old ones dropped by hand, so inserts fail at the boundary when no partition exists (PostgreSQL has no default partition unless one is created) and old partitions are never dropped.
- Not a finding if: the table is modest and a batched reaper keeps it bounded (SCALE-R2); partition maintenance is automated (pg_partman, a scheduled job, TimescaleDB policies).
- Severity: High when partition creation is manual (the insert path fails at the boundary); Medium otherwise.
- Fix: declarative range partitioning on the time or tenant key, with partitions created ahead of time and a drop policy, both automated.
- Verify the fix: the scheduler creates next month's partition in advance, and a test insert dated next month succeeds.
- Refs: PostgreSQL docs, Table Partitioning; pg_partman

### SCALE-R4 One hot row serializes every write
- Leads: `scan.sh SCALE-R4` lists increments of global counters and updates of single shared rows.
- Confirm: every write updates the same row (`UPDATE counters SET n = n + 1 WHERE id = 1`, one global running balance, a counter cache on a very popular parent), so all writers queue on that row's lock.
- Not a finding if: the write rate is low; the counter is per user or per tenant.
- Severity: High on a high-throughput write path; Medium otherwise.
- Fix: sharded counters (N rows summed on read), or append rows to a ledger and aggregate asynchronously.
- Verify the fix: under a load test, lock waits on the counter row disappear.
- Refs: Designing Data-Intensive Applications, ch. 6 (hot spots)

### SCALE-R5 Connections exceed what the database or pooler can serve, or the pooler mode breaks session state
- Leads: `scan.sh SCALE-R5` lists pool sizes, pooler settings, and serverless deployment config.
- Confirm: the pool size times the number of processes, containers, or serverless instances can exceed the server's `max_connections` (each serverless instance opens its own pool: "too many connections" under load); or a transaction-mode pooler (PgBouncer `pool_mode = transaction`, RDS Proxy, a hosted pooler) is combined with session state: named prepared statements the pooler does not support, `SET` without `LOCAL`, advisory locks, temporary tables, `LISTEN`.
- Not a finding if: a pooler sits between the instances and the database (cite it) and the session features that the pool mode breaks are off (for example `pgbouncer=true` in a Prisma URL).
- Severity: High for serverless or autoscaled deployments with no pooler; Medium otherwise.
- Fix: a pooler in front of the database, a per-instance pool of 1 to 5 for serverless, and session features disabled or scoped to the transaction.
- Verify the fix: pool size times the maximum instance count stays below `max_connections` minus a reserve.
- Refs: PgBouncer docs (pool modes and feature support); PostgreSQL docs, max_connections

### SCALE-R6 Read after write served by a lagging replica
- Leads: `scan.sh SCALE-R6` lists replica and read-routing configuration.
- Confirm: reads go to a replica (`db_for_read`, `connected_to(role: :reading)`, `readPreference: secondary`, a reader endpoint) on a path that reads right after writing (the balance after a payment, the order after checkout, the session after sign-in), with no read-your-writes guard (the primary for a window after a write, or waiting for the replica to reach the write's position).
- Not a finding if: the post-write read goes to the primary (Rails automatic role switching with a delay, a primary-after-write middleware; cite it).
- Severity: High for money, sign-in, and inventory reads; Medium otherwise.
- Fix: route a session's reads to the primary for a window after it writes, or wait for the replica to catch up to the write.
- Verify the fix: a test with an artificially delayed replica reads its own write.
- Refs: Designing Data-Intensive Applications, ch. 5 (reading your own writes)

## Also check
- Autovacuum left at defaults on hot, update-heavy tables; no `ANALYZE` after bulk loads.
- No slow-query observability (`pg_stat_statements`, `log_min_duration_statement`, MySQL `slow_query_log`).
- No `lock_timeout` or `idle_in_transaction_session_timeout` at the role default.
- No backup and point-in-time recovery posture inferable for the production database (IaC, README, or runbook).
- Materialized views with no documented refresh, or refreshed without `CONCURRENTLY` (readers blocked; it needs a unique index).

## Paper controls (look protective, protect nothing)
- A `created_at` index on the events table but no retention job that uses it (SCALE-R2).
- Range partitioning declared while partition creation and drop are done by hand (SCALE-R3).
- `autovacuum = on` cited as protection while a long transaction or an unused replication slot holds back the xmin horizon: tables bloat, and near transaction ID wraparound PostgreSQL stops accepting writes.
