# TXN: Transactions, Concurrency and Consistency

Weight 9. Active when a write path exists (INSERT, UPDATE, DELETE, or ORM writes).
Owns: atomicity, locking, isolation, and idempotency of writes: lost updates, multi-write atomicity, retried handlers, external calls inside transactions, write skew, long or unclosed transactions, transactions that silently do not apply, and cache consistency after writes.
Not here: uniqueness that a constraint can enforce, including an idempotency key column that lacks UNIQUE (CONSTRAINTS-R1) and non-overlap rules (CONSTRAINTS-R6); float money (TYPES-R1); one hot row that serializes writers (SCALE-R4); pooler modes and session state (SCALE-R5); reading your own writes from a replica (SCALE-R6).
Standards: Designing Data-Intensive Applications (Kleppmann), ch. 7; PostgreSQL and MySQL transaction isolation docs; framework transaction docs.
Read first: every write path in the Map (money, inventory, counters, retried handlers), each transaction boundary, and the database client's transaction API.

## Cards

### TXN-R1 Read-modify-write on a balance, stock, or counter with no lock, version check, or atomic update (quick)
- Leads: `scan.sh TXN-R1` lists arithmetic on balances and quantities, updates that write a computed value, and existing row locks.
- Confirm: code reads a mutable value (balance, stock, credits, seats, a counter), computes the new value in the app, and writes it back (`update({ balance: newBalance })`, `SET balance = ?`) with no `SELECT ... FOR UPDATE` in the same transaction, no version check, and no atomic `SET col = col - :delta`, so two concurrent requests lose one update. Also an optimistic-lock version column that is bumped but missing from the `UPDATE`'s `WHERE`, or whose affected-row count is ignored, so a zero-row update reads as success.
- Not a finding if: the read locks the row inside the same transaction as the write (`FOR UPDATE`, `forUpdate()`, `select_for_update()`, `lock!`, `with_for_update()`); the update is atomic and guarded (`SET stock = stock - $1 WHERE id = $2 AND stock >= $1`, row count checked); SERIALIZABLE with a retry.
- Severity: Critical on money, balances, credits, or inventory; High on other shared counters.
- Fix: one atomic statement (`UPDATE customers SET credit_balance = credit_balance + $1 WHERE id = $2 RETURNING credit_balance`), or lock the row in a transaction before reading; with optimistic locking add `AND version = $expected` and treat zero rows as a conflict.
- Verify the fix: a test runs 50 concurrent increments of 1 and the value rises by exactly 50.
- Refs: CWE-362; Designing Data-Intensive Applications, ch. 7 (lost updates)

### TXN-R2 Dependent writes not wrapped in one transaction (quick)
- Leads: `scan.sh TXN-R2` lists transaction boundaries; compare them with the write paths in the Map.
- Confirm: an operation makes two or more writes that must succeed together (create the order, decrement stock, record the payment; debit one account and credit another) as separate autocommit statements or separate transactions, so a failure or crash between them leaves a partial state.
- Not a finding if: all writes share one transaction handle (check each call: TXN-R7); the steps are idempotent and a retry or outbox completes them (cite it).
- Severity: Critical when money moves (a debit without its credit, a charge without its order); High otherwise.
- Fix: one transaction around the writes, with the handle passed to every call; move external calls out (TXN-R4).
- Verify the fix: a test that makes the second write fail leaves no trace of the first.
- Refs: Designing Data-Intensive Applications, ch. 7 (atomicity)

### TXN-R3 Retried or externally triggered write with no idempotency key (quick)
- Leads: `scan.sh TXN-R3` lists webhook handlers, queue consumers, retries, and idempotency keys.
- Confirm: a handler that can run twice for one event (webhooks, at-least-once queue consumers, client retries, payment captures) inserts rows or changes balances without storing a unique idempotency key (the provider's event ID, a client-sent key) in the same transaction as the effect.
- Not a finding if: a unique key makes the second run a no-op (`INSERT ... ON CONFLICT (event_id) DO NOTHING` inside the transaction); the key column exists but lacks UNIQUE (file CONSTRAINTS-R1 instead).
- Severity: Critical when a duplicate run moves money or grants credit; High otherwise.
- Fix: store the key in a table with a UNIQUE constraint in the same transaction as the effect; on conflict return the first result.
- Verify the fix: a test delivers the same event twice and one effect is recorded.
- Refs: Designing Data-Intensive Applications, ch. 11 (idempotence)

### TXN-R4 External call inside an open transaction, or a cross-service workflow treated as atomic
- Leads: `scan.sh TXN-R4` lists HTTP, payment, email, storage, and queue calls; check which run between a transaction's start and its commit.
- Confirm: a network call (HTTP, payment provider, email, object storage, a message publish) runs inside a database transaction, holding row locks and a connection for the call's latency, while the commit can still fail after the external effect happened; or a workflow across services is treated as atomic with no saga, compensation, or durable outbox, so a downstream failure leaves the first service committed.
- Not a finding if: the call happens after commit, or through an outbox row written in the same transaction and relayed later (cite it).
- Severity: High on a hot path or when money moves; Medium otherwise.
- Fix: do the database work, commit, then call out; or write an outbox row inside the transaction and publish from a relay.
- Verify the fix: no network client runs inside a transaction callback, and a test with a failing external call leaves consistent rows.
- Refs: Transactional outbox pattern (microservices.io)

### TXN-R5 Isolation too weak for a rule that spans rows (write skew), or serializable without retry
- Leads: `scan.sh TXN-R5` lists isolation levels and serialization-failure handling.
- Confirm: code checks a rule across several rows and then writes (at least one doctor on call, allocations at most 100 percent, seats across rows) under READ COMMITTED or REPEATABLE READ with no lock covering the rows it read and no constraint that expresses the rule; or it uses SERIALIZABLE or REPEATABLE READ without retrying serialization failures (SQLSTATE 40001) and deadlocks (40P01).
- Not a finding if: a UNIQUE or EXCLUDE constraint can express the rule (file CONSTRAINTS-R1 or CONSTRAINTS-R6); every writer first locks one common parent row.
- Severity: High when the rule protects money, capacity, or safety; Medium otherwise.
- Fix: SERIALIZABLE with a bounded retry loop on 40001, a lock on a common parent row, or the rule materialized into a row that can be locked or constrained.
- Verify the fix: a test with two conflicting concurrent transactions leaves the rule intact.
- Refs: Designing Data-Intensive Applications, ch. 7 (write skew); PostgreSQL docs, Transaction Isolation

### TXN-R6 Long, unbounded, or unclosed transactions
- Leads: `scan.sh TXN-R6` lists manual BEGIN and COMMIT, connection checkouts, and autocommit settings.
- Confirm: a transaction wraps a loop, a bulk `UPDATE` or `DELETE` over an unbounded set, or a wait on a user or a slow call, holding locks and blocking vacuum; or a manual transaction has no guaranteed COMMIT or ROLLBACK on every path (no `try/finally`), leaving the session idle in transaction; or two paths lock the same rows in different orders (deadlock risk).
- Not a finding if: bulk work is chunked with a commit per batch; a context manager or the framework guarantees release.
- Severity: High on hot tables (blocked writers, bloat from long snapshots); Medium otherwise.
- Fix: batch bulk work (about 1,000 rows per transaction), release in `finally`, lock rows in one canonical order (`ORDER BY id FOR UPDATE`), and set `idle_in_transaction_session_timeout`.
- Verify the fix: no transaction spans a loop over unbounded input, and `pg_stat_activity` shows no idle-in-transaction sessions during a load test.
- Refs: PostgreSQL docs, Routine Vacuuming and Client Connection Defaults

### TXN-R7 Transaction that does not apply: inert decorator or queries outside the transaction handle (quick)
- Leads: `scan.sh TXN-R7` lists transaction callbacks, decorators, and autocommit settings.
- Confirm: code believes a block is transactional but it is not: inside `knex.transaction(async (trx) => ...)` a query uses `knex` or `db` instead of `trx`; a Prisma interactive transaction calls `prisma.` instead of `tx.`; a Sequelize managed transaction omits `{ transaction: t }` without CLS; `BEGIN` and `COMMIT` go through `pool.query`, so each statement may use a different connection; Spring `@Transactional` sits on a private method or is called from the same class (the proxy is bypassed), or rolls back only on unchecked exceptions while the code throws checked ones; driver autocommit makes BEGIN and COMMIT no-ops.
- Not a finding if: every call inside the block uses the transaction handle (read each one).
- Severity: as the protection it removes: Critical when it guards money movement or a balance update (TXN-R1, TXN-R2); High otherwise.
- Fix: pass the handle to every call; check out one client for BEGIN through COMMIT; make `@Transactional` methods public, call them through the proxy, and set `rollbackFor = Exception.class` where checked exceptions must roll back.
- Verify the fix: a test that throws after the first write inside the block leaves no row behind.
- Refs: node-postgres docs, Transactions; Spring docs, Declarative Transaction Management

## Also check
- A cache in front of the database with no invalidation on write (stale reads after a write) or a stampede on expiry (many requests recompute at once): delete or update the cache on write, and use a lock or early refresh on expiry.

## Paper controls (look protective, protect nothing)
- `SELECT ... FOR UPDATE` used to stop a duplicate insert: it cannot lock a row that does not exist yet (use a UNIQUE or EXCLUDE constraint, or SERIALIZABLE).
- A `@Transactional` that is inert: self-invocation, a private method, autocommit left on, or rollback only on unchecked exceptions (TXN-R7).
- SERIALIZABLE or REPEATABLE READ with no retry on serialization failure (TXN-R5).
- A version column bumped on every update but never checked in the `WHERE` clause (TXN-R1).
- SQL Server `READ_COMMITTED_SNAPSHOT` believed to stop lost updates: it does not, and SNAPSHOT isolation still allows write skew.
