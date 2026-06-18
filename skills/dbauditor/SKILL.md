---
name: dbauditor
description: Audit the database layer of the codebase end to end (schema, relationships, indexing, queries, transactions, migrations, data protection, search, and scale), write dbaudit.md (a scored, prioritized, self-contained report), then display the results in chat. Read-only: never connects to a live database, never runs migrations, never mutates data.
---

> Invocation: type `/dbauditor` to run this command. Treat any text after it as the optional path-or-scope argument (a subpath, a schema name, or a single engine).

# dbauditor

Audit the database layer of the codebase in the current working directory end to end: its schema and data model, the relationships between tables, indexing, query and access patterns, transactional correctness, migrations, data protection at the database tier, search, and scalability. Then do two things:

1. **Write a report** named `dbaudit.md` at the root of that codebase.
2. **Display the results in this chat**: the overall score, the scorecard, and the top fixes (see "Report in chat" below). Do not finish silently.

This is **read-only analysis of the code as written**. Do not connect to a live database, do not run or apply migrations, do not execute the project's code, do not mutate data, and do not run `EXPLAIN` against a real server. Work from the schema files, migrations, ORM models, query builders, raw SQL, and configuration in the repository. The only file you create is `dbaudit.md`. If an optional path or scope was provided as an argument, audit that subtree or schema; otherwise audit the whole database layer rooted at the working directory.

The report is written for a reader who has **no memory of the audit**, typically an AI agent that will open `dbaudit.md` later and decide, on its own, what to fix. Every finding must therefore stand alone: cite exact locations (`path/to/migration_or_model.ext:line`), name the table, column, constraint, index, or query, carry its own context, and say how to verify the fix. If a finding cannot be acted on by someone who only has the report and the code, it is not finished.

This is a **database design, integrity, performance, and operability audit**. Scope is the data layer: how the data is modeled, how rows are linked and kept consistent, how queries reach them, how concurrent writes stay correct, how the schema evolves, how data is protected at the database tier, how search works, and whether the design survives growth. General code quality belongs to `codeauditor`, user experience to `uxauditor`, and the full application security surface to `secauditor`; touch those only where they create a database-layer defect. Where database security overlaps `secauditor` (injection, secrets, access control), this audit covers the database-specific slice and says so.

---

## Operating principles (non-negotiable)

These govern the whole audit. A report that violates any of them is not done.

1. **Evidence over assertion.** No claim without a concrete, checkable reference (`file:line`) and the data path that makes it real: the column and its type, the query and its predicate, the migration and its lock. Apply the substitution test to every sentence: if you could swap in a different project and it would read equally true, it is filler. "Indexing could be improved" fails. "`db/migrate/2024_orders.rb:12` declares `orders.customer_id` with `REFERENCES customers` but no index, and Postgres does not auto-index FK columns, so every `customers` delete full-scans `orders`" passes.
2. **Verify against reality, not the ORM's promise.** Read the migration and the actual DDL, not the model annotation, the comment, or the README. An ActiveRecord `validates_uniqueness_of`, a Django `unique=True`, a Prisma `@unique`, or a `belongs_to`/`@ManyToOne` enforces nothing in the database; only a DB `UNIQUE`/`FOREIGN KEY`/`CHECK` does. The gap between the model's claim and the shipped DDL is itself a finding, and often the most serious one.
3. **Refuse theater. Hunt for paper controls.** The most dangerous defects look protective but carry no weight: a Postgres FK added `NOT VALID` and never `VALIDATE`d, a `UNIQUE` on a nullable column that lets unlimited NULLs through, an index whose leftmost column no query filters, a covering index missing the one selected column, a partial index whose predicate does not match the query, a `@Transactional` that is inert because autocommit was never disabled or the proxy is bypassed, RLS `ENABLE`d but never `FORCE`d while the app owns the table, a `statement_timeout` set in config but not inherited through the connection pooler, an external search index kept in sync by best-effort dual-write. Flag anything that exists for appearance but does not actually hold.
4. **Reachability and blast radius.** A weakness matters in proportion to the table's size and traffic and the value of the data. A missing index on a ten-row lookup table is not the missing index on the hot `orders` join; float money in a logging table is not float money in the ledger. Calibrate to table size and throughput where inferable from the code; where it depends on data volume, query plans, or runtime config you cannot see from static code, mark it Suspected and say what would confirm it (a row count, an `EXPLAIN`, an index-usage stat).
5. **Find the root, not the leaves.** If the same mistake appears across the schema (no FK on any `*_id` column, money stored as float in every amount column, no pagination on any list query, no DB-level uniqueness anywhere), that is one systemic finding, not twenty. Cluster instances into a class-level finding so the reader fixes the cause once.
6. **Verify adversarially.** For every candidate, try to refute it before keeping it: is there a DB constraint, a generated column, a trigger, a partial or expression index, a database default, or a framework guarantee elsewhere that already neutralizes it? Is the denormalization deliberate and maintained? Assign a confidence level; when you cannot confirm by reading, mark it Suspected.
7. **Calibrate to the paradigm, not to a relational ideal.** Grade against the workload the project actually has. In an analytics or data-warehouse target (star/snowflake schema, fact and dimension tables, dbt models), wide denormalized tables are the correct design, not an anti-pattern. In a document or wide-column store (MongoDB, DynamoDB, Cassandra), denormalization and duplication are intended and the real risks are unbounded documents, hot partitions, and access patterns not modeled into the keys. State the detected paradigm and calibrate every lens to it.
8. **Be honest about scope.** Say which schema files, migrations, and models you read, whether you read exhaustively or sampled, which engines and surfaces are present and which are N/A, and which findings need a running database, real data volumes, or a query plan to confirm. Never imply you profiled a live database or ran a benchmark.
9. **Score with reasons, not vibes.** Every dimension score is justified against its specific findings. No number appears without the evidence that produced it.
10. **Name the strengths.** Record what the schema gets right, with evidence (real FKs with intentional cascade rules, parameterized queries throughout, `NUMERIC` money, keyset pagination, partitioning with a retention job, DB-enforced uniqueness on identity keys), so the acting agent preserves them instead of removing them while fixing something else.
11. **Recommendations are specific and actionable, and migration-safe.** Banned: "optimize the queries," "add indexes," "improve the schema." Required: the exact column, type, constraint, or index to add or change; the safe pattern; and how to confirm it (a query plan to re-check, a constraint to add, a count that should now be zero). Never propose a constraint or index addition on a large table without the lock-safe path (`CREATE INDEX CONCURRENTLY`, `ADD CONSTRAINT ... NOT VALID` then `VALIDATE`, expand-contract), because the fix itself can cause the outage.

---

## Ownership rule (the de-duplication discipline)

Many defects surface through several lenses: float money touches schema, types, and transactions; an unindexed foreign key touches integrity and indexing; an unsafe migration touches every dimension whose end state it changes. **Each finding is emitted by exactly one dimension, its owner, and contributes only to that dimension's score.** Other dimensions may cross-reference it ("see TYPES for the float-money root") but must not re-score it. Tag every finding with its owner. Use this ownership map:

| Defect | Owner | Rule |
|---|---|---|
| Money stored as FLOAT/DOUBLE/REAL | **TYPES** | physical type correctness is TYPES; others cross-reference |
| Missing FK constraint vs missing index on the FK column | **INTEGRITY** (constraint) / **INDEX** (index) | is the constraint there? INTEGRITY. is the supporting index there? INDEX |
| FK NOT VALID / WITH NOCHECK / untrusted | **INTEGRITY** | unenforced referential state; MIGRATION only if the defect is "the VALIDATE step was never written" |
| App-only uniqueness (ORM validation, no DB constraint) | **CONSTRAINTS** | missing invariant; TXN only when the failure is a lost-update/race |
| Leading-wildcard `LIKE '%x%'`, no trigram/FTS | **SEARCH** if it backs a search feature, else **QUERY** | search feature vs incidental predicate |
| Non-sargable predicate (function-wrapped column) | **QUERY** (sargability) / **INDEX** (does a matching expression index exist) | |
| Unsafe/locking migration mechanics | **MIGRATION** | every other dimension owns the desired end state; how to apply it safely is MIGRATION alone |
| SQL/NoSQL injection sink | **DBSEC** | single source of truth for the injection finding |
| Read-modify-write lost update on money/inventory | **TXN** | the concurrency anomaly |
| Unbounded growth / retention / partitioning | **SCALE** | QUERY owns the missing-LIMIT; SCALE owns growth-over-time |
| Soft-delete pitfalls | split: **INTEGRITY** (dangling children) / **CONSTRAINTS** (partial-unique) / **SCHEMA** (design choice) | document the split so one `deleted_at` does not fire three findings |

---

## Method

Run these phases in order. Use search to find candidates, then **read the cited DDL, migration, model, or query to confirm the data path** before recording anything. A grep hit (a `Float` type, a `LIKE`, an `add_index`) is a lead, not a finding.

### Phase 0 - Orient

- Detect the **engine(s) and access layer** from manifests, connection strings, and config: SQL dialect (PostgreSQL, MySQL/MariaDB, SQLite, SQL Server, Oracle), the ORM or query builder (ActiveRecord, Django ORM, SQLAlchemy, Hibernate/JPA, Sequelize, Prisma, TypeORM, Knex, Ecto, GORM, EF Core), and the migration tool (Rails, Django, Alembic, Flyway, Liquibase, Prisma Migrate, Knex, golang-migrate, EF Core).
- Detect **non-relational and specialized surfaces**, because they decide which lenses apply and how to calibrate: document stores (MongoDB, Firestore, Cosmos, Couchbase), key-value/wide-column (DynamoDB, Cassandra, ScyllaDB, Redis), search engines (Elasticsearch/OpenSearch, Meilisearch, Typesense), vector stores (pgvector, Pinecone, Weaviate, Qdrant, Milvus), analytics/warehouse (Snowflake, BigQuery, Redshift, ClickHouse, DuckDB, Databricks, dbt), and time-series (TimescaleDB, InfluxDB, Prometheus). Record which are present and which are N/A.
- Locate the **schema sources**: migration directories, schema dumps (`schema.rb`, `structure.sql`, `*.prisma`, `*.sql`), ORM model classes, and where queries live (repositories, DAOs, raw SQL, query-builder chains, stored procedures).
- Determine the **workload paradigm** (OLTP application, analytics/warehouse, document/KV, or mixed) and the **data sensitivity and tenancy** (PII/PHI/financial data, single- vs multi-tenant). These set the calibration and raise the bar on INTEGRITY, CONSTRAINTS, and DBSEC.
- Measure size (table count, migration count, model count) and decide exhaustive vs sampled reading. Declare which in the report.
- Note explicitly **what static code cannot reveal**: row counts, real query plans, index-usage statistics, replication lag, autovacuum/bloat state, and production server config. These become Suspected findings or "verify with X" items, never confident performance claims.
- Identify what to exclude: vendored code, generated migrations you will not re-derive, test fixtures (but do read seed data for committed secrets and for whether seeds masquerade as migrations). Record exclusions.
- If there is **no database layer** (no schema, no models, no queries, no datastore config), say so plainly in chat and stop. Do not invent findings.

### Phase 1 - Map the data model

Do a short, lightweight model-and-flow pass before the per-dimension checklist. Keep it to roughly a half page; it informs prioritization.
- **Entities and relationships:** the tables, their primary keys, and the relationship graph, marking each link as DB-enforced (a real FK), ORM-only (a model association with no DB constraint), or cross-service/cross-database (unenforceable by a FK).
- **Hot paths:** the highest-traffic tables and the dominant queries (list endpoints, joins, search, reports), and where money, inventory, authentication, and tenant data live.
- **Write paths and transaction boundaries:** multi-statement operations, counters and running balances, money movement, and anything retried (webhooks, queue consumers, payment captures).
- **Growth-bearing tables:** events, logs, audit, sessions, notifications, outbox; whether any retention or partitioning exists.
- **Search and retrieval surfaces** and any non-relational stores, plus how derived stores (a search engine, a cache, a replica) are kept in sync with the source of truth.
Trace two or three highest-risk flows end to end: a hot list query and the indexes it can actually use; a money movement and its transaction, constraints, and types; a parent delete and its cascade or orphan behavior. Spend effort proportional to blast radius.

### Phase 2 - Analyze across every lens

For each candidate capture three things: the location (`file:line`) and the data path, what the schema or query or migration does now, and why that is a problem and how big its blast radius is. Do not score yet. Skip a conditional lens whose surface is absent (say so), and calibrate every lens to the paradigm from Phase 0. Respect the ownership map: emit each finding once.

**Referential Integrity and Relationships** (INTEGRITY) - the linkage backbone. *Owns: existence, validation state, and cascade semantics of DB-level relationships.*
- A `*_id`/`parent_id` column references another table but has **no `FOREIGN KEY`/`REFERENCES`** in any migration; integrity lives only in an ORM association or app code. Require a DB FK on every column that names another table's key; ORM `belongs_to`/`relationship()`/`@ManyToOne` enforces nothing against raw SQL, batch jobs, or a second service.
- A FK has **no explicit `ON DELETE`/`ON UPDATE`** while the parent is deleted in code and the delete path never removes children first: orphan-or-error at runtime. Require an intentional `CASCADE | SET NULL | RESTRICT` per child semantics.
- **`ON DELETE CASCADE` reaching independently-valuable data** (orders, invoices, ledger lines, payments, audit rows): one parent delete silently mass-removes dependents through nested cascade chains. Reserve CASCADE for disposable children (sessions, tokens, join rows); use RESTRICT or an app-managed delete for the rest.
- **FK type, length, signedness, or collation does not match the referenced key** (`user_id INT` referencing `users.id BIGINT`, `uuid` vs `varchar`, `utf8mb4_general_ci` vs `utf8mb4_0900_ai_ci`): blocks the constraint (MySQL errno 150) or forces an implicit cast that disables the join index. Require identical type and collation on both sides.
- **M:N modeled without a true junction table** (a CSV/array column, or a join table lacking a composite `PRIMARY KEY (a_id, b_id)` and a FK on each side), permitting duplicate links and orphans.
- A **mandatory relationship modeled with a nullable FK**, allowing parentless rows; reserve nullable FKs for genuinely optional links with explicit `ON DELETE SET NULL`.
- A **soft-deleted parent keeping a hard FK satisfied** while app queries filter it out: children point at a logically-gone parent. Require cascading the soft-delete, or not soft-deleting FK targets.
- A **cross-database or cross-service reference** (`account_id` from another service, `other_db.table`) stored as a bare column: a FK cannot span the boundary, so nothing prevents a dangling reference. Require a documented reconciliation/outbox job and a periodic orphan check, and audit whether they exist.
- **Cascade configured only in the ORM** (`dependent: :destroy`, `cascade='all, delete-orphan'`, Prisma `onDelete`) while the migration emits a plain FK with no `ON DELETE`: bulk SQL and other clients bypass it. Require the rule at the DB level.
- **Erasure that must reach denormalized copies, caches, and logs** (GDPR/CCPA right-to-erasure) but only soft-deletes the primary row, leaving copies behind. Cross-ref DBSEC.
- Paper controls to hunt: a Postgres FK `NOT VALID` never `VALIDATE`d (enforces new writes only; pre-existing orphans never scanned); a SQL Server FK enabled but `is_not_trusted = 1` after `WITH NOCHECK`; a MySQL FK on a `MyISAM` table or `FOREIGN_KEY_CHECKS=0` left in a load script; SQLite FKs declared while `PRAGMA foreign_keys = ON` is never issued per connection; a MySQL FK pointing at a non-unique column presented as one-to-one.

**Indexing Strategy** (INDEX) - *Owns: existence, shape, and usability of indexes.*
- **Unindexed FK child column** in PostgreSQL or Oracle (neither auto-indexes it; InnoDB does): every parent delete/update locks and full-scans the child. Grep `ADD CONSTRAINT ... FOREIGN KEY` and confirm a matching index exists.
- **Missing index on a high-selectivity predicate**: a `user_id`, `email`, `slug`, `tenant_id`, `order_id`, or timestamp used in a hot `WHERE`/`JOIN`/`ORDER BY` with no covering index.
- **Composite index column order wrong**: leftmost column is one no query filters on (leftmost-prefix violation, dead index), or a range column precedes an equality column. Require equality columns first, then one range column last.
- **Redundant or duplicate indexes**: `INDEX(a)` alongside `INDEX(a,b)` (prefix-redundant), or two identical indexes (often an ORM auto-index plus a migration index, or a `UNIQUE` plus a plain index on the same column). Each adds write cost and bloat for no read benefit.
- **Single-column index on a low-cardinality column** (boolean, status with three values, soft-delete flag) used alone: the planner ignores it for a seq scan. Drop it or fold it into a composite or partial index.
- **Leading-wildcard `LIKE '%x%'`/`ILIKE` on a plain B-tree index** (cross-ref SEARCH when it backs a search feature): anchored `LIKE 'x%'` is the only form a B-tree serves, and in Postgres only with `text_pattern_ops`/`COLLATE "C"`; substring needs a `pg_trgm` GIN/GiST index.
- **Case-insensitive lookup via `LOWER(col)=...` with no matching expression index**: require a functional index on the identical expression, or `citext`.
- **Wrong index type for the access pattern**: a B-tree on `jsonb` containment, array membership, full-text, or trigram search; require GIN for jsonb/arrays/tsvector/trigram, GiST for ranges and nearest-neighbor, BRIN for naturally-ordered append-only columns.
- **`ORDER BY`/pagination not aligned with an index that also covers the filter**, forcing a sort; require a composite `(filter_col, sort_col [DESC])` matching ASC/DESC and NULLS order.
- **Over-indexing a write-heavy table** (many single-column indexes, each ~5-15% write overhead) where a few composites serving multiple shapes via leftmost-prefix would do.
- Paper controls to hunt: an index whose leftmost column the query never filters (present, counted as "covered," unusable); a `UNIQUE`/covering/`INCLUDE` index missing the one selected column (still a heap fetch); a partial index whose `WHERE` does not exactly match the query's predicate; a functional index on `LOWER(col)` while the query uses `ILIKE` or a slightly different expression; a MySQL `INVISIBLE` index or a Postgres `INVALID` index left by a failed `CREATE INDEX CONCURRENTLY`; an index whose collation version drifted after a glibc/ICU OS upgrade (silent corruption, needs `REINDEX`).

**Query Performance and Access Patterns** (QUERY) - speed and optimization, including the ORM layer. *Owns: query shape, sargability, pagination, fetching, and the data-access lifecycle.*
- **N+1 lazy load**: a loop over a collection touching a relation per row with no eager-load primitive (`select_related`/`prefetch_related`, `.includes`/`preload`, `JOIN FETCH`/`@EntityGraph`, DataLoader, `joinedload`/`selectinload`).
- **`SELECT *` / unprojected ORM fetch** feeding a serializer that uses a few columns, over-fetching every column including large TEXT/BLOB/JSON and defeating covering indexes; require explicit projections (`.only()`, `.select()`, `.pluck()`).
- **Unbounded result set**: a list query with no `LIMIT`/pagination that grows with the table and can OOM the app; require a hard cap or mandatory pagination on every list path.
- **OFFSET deep pagination** (`OFFSET n LIMIT k`, `.offset()`, page-number `Pageable`): O(n) latency that collapses at deep pages; require keyset/seek pagination over an index matching the `ORDER BY`.
- **Non-sargable predicate**: a function or expression wraps the indexed column (`LOWER(email)=`, `DATE(created_at)=`, `col+0=`, `EXTRACT(...)`), forcing a scan; rewrite to range bounds or add a matching expression index.
- **Implicit type coercion** in a predicate (string compared to an int/uuid column, mismatched collation): the engine casts the column side and abandons the index; bind parameters typed to the column.
- **`OR` across different columns** that no single index satisfies, and **`NOT IN (subquery)`** where the subquery can be NULL (three-valued logic silently returns zero rows and blocks anti-join); use `UNION`/bitmap-OR, and `NOT EXISTS`/`LEFT JOIN ... IS NULL`.
- **Correlated subquery re-executed per outer row**, an **accidental Cartesian product** (comma join or incomplete `ON`), or a **query inside a loop**; replace with a single set-based join/aggregate or a batched `WHERE id = ANY(:ids)`.
- **`COUNT(*)` over a large table on every paginated request**; use an estimate (`reltuples`), a maintained counter, or `LIMIT k+1`.
- **No statement/query timeout and no connection pool** (or a pool larger than server `max_connections`): a runaway query or connection churn takes the service down. Cross-ref SCALE for pool sizing; QUERY owns the missing timeout and the per-request connection smell. Also flag an **ORM session/connection leaked on exception paths** or held across request boundaries.
- Paper controls to hunt: an `EXPLAIN` captured against a tiny dev dataset (cardinality will flip the plan in prod); a `statement_timeout` set in config but unreliable through transaction-mode pooling; a `LIMIT` applied after a `DISTINCT`/`GROUP BY`/`ORDER BY` that must first materialize the whole set; "prepared statements" that re-plan every call under a pooler; an eager-load declared on the base query but bypassed by a later `.where`/`.order` on the association.

**Security and Data Protection at the DB layer** (DBSEC) - *Owns: injection, DB access control, secrets, and protection of data at rest in the database. The full app security surface is `secauditor`'s.*
- **Injection sink**: request input reaches a query via string concatenation, f-string, `%`/`.format()`, or template literal in `WHERE`/`VALUES`/`ORDER BY`; or an ORM raw escape hatch (`.raw()`/`.extra()`/`RawSQL`, SQLAlchemy `text()` with an f-string, Sequelize `query` without `replacements`/`bind`, Prisma `$queryRawUnsafe`, Knex `.whereRaw('col='+v)`). Require bound parameters. For **dynamic identifiers** (sort column, table) that cannot be bound, require an allowlist, not pass-through of `req.query.sort`. The NoSQL analog is operator injection (`$where`, an unparsed `{"$gt":""}` reaching a query).
- **App connects as a superuser/owner** (`postgres`/`root`/`sa`), or migrations grant broadly (`GRANT ALL`, `pg_read_all_data`, `GRANT ... TO PUBLIC`): an exploited query gets unrestricted DDL/DML. Require a least-privilege per-service role with DML only on its tables and DDL reserved to a separate migration identity.
- **PII/PHI/financial columns in plaintext** (`ssn`, `pan`, `cvv`, `dob`, `mrn`, `diagnosis`) where sensitivity demands protection: require column-level encryption (pgcrypto, Always Encrypted, CSFLE), tokenization, or for passwords a salted adaptive KDF (argon2id/bcrypt/scrypt); never store CVV at all.
- **Connection without verified TLS** (`sslmode=disable`/`require` rather than `verify-full`, `rejectUnauthorized:false`, JDBC `useSSL=false`, Mongo without `tls=true`) and **no encryption at rest** declared in IaC for a sensitive datastore.
- **Multi-tenant isolation enforced only by app `WHERE tenant_id=`** with no DB-enforced RLS: a forgotten or wrong filter leaks cross-tenant rows. The database is the correct enforcement point here.
- **Committed secrets**: a real `DATABASE_URL`/password/connection string in the repo or git history (live even if later deleted unless rotated), and **default/empty/trust auth** (`postgres/postgres`, blank `sa`, `pg_hba trust`, Mongo without `--auth`, unauthenticated Redis).
- **Database on a public interface** (`0.0.0.0` bind, `0.0.0.0/0` ingress, `publicly_accessible=true`) on its native port.
- **No audit trail** of reads/writes on sensitive tables, an **over-broad view** exposing sensitive columns (a `VIEW ... SELECT *` over a PII table, or a non-`security_invoker` view that reads past RLS), and **unencrypted backups/dumps**.
- Paper controls to hunt: RLS `ENABLE`d but not `FORCE`d while the app owns the table (policies silently skipped); an RLS policy keyed to a session GUC that pooled connections leave stale; a column "encrypted in the model" but stored as plain `TEXT` with some write paths skipping encryption; `sslmode=require` that does not verify the certificate (still MITM-able); a password under a fast unsalted hash labeled "hashed"; a secret deleted from HEAD but live in history and never rotated; SQL Server Dynamic Data Masking treated as access control (it is display-only).

**Schema Design and Data Modeling** (SCHEMA) - best-practice modeling. *Owns: whether the model itself is right; the design choice, not the enforcement mechanism.*
- **Multi-valued attribute in one column** (Jaywalking): a `VARCHAR`/`TEXT` holding a comma/JSON list of IDs queried with `LIKE '%,5,%'`/`FIND_IN_SET`; require a junction table.
- **Repeating-group columns** (`phone1/phone2/phone3`, `addr_line_1..4`): an unnormalized array; require a child table with a position column.
- **A base table with no primary key**: permits duplicate rows and breaks logical replication/CDC.
- **EAV generic store** (`(entity_id, attribute_name, value)` or a catch-all `meta`/`properties` table of stringly-typed data) adopted without justification; prefer typed columns or a constrained `jsonb`.
- **Polymorphic association with no enforceable FK** (`commentable_id` + `commentable_type`): the discriminator cannot carry a FK; use per-parent FK columns with an exclusive-arc CHECK, or per-parent join tables.
- **Free-text status/type column** (`status VARCHAR` accepting `'Active'`/`'active'`/`'ACTIVE'`) with no CHECK, enum, or lookup FK; and a **surrogate PK while the natural business key (`email`, `sku`, `(tenant_id, slug)`) has no UNIQUE** (cross-ref CONSTRAINTS for the enforcement).
- **God table** (dozens of NULL-heavy columns spanning unrelated subject areas) that wants vertical decomposition; and a **boolean/state exploded into mutually-exclusive nullable flags** (`is_draft`/`is_published`/`is_archived`) allowing contradictory states; prefer one `state` column with a CHECK.
- **Denormalized/derived value with no maintenance mechanism** (`orders.customer_name`, a cached `comment_count`) that drifts; SCHEMA owns "should this be denormalized at all," CONSTRAINTS owns "use a `GENERATED` column to prevent drift."
- **Inconsistent naming** across the schema (mixed pluralization, case styles, `uid`/`user_id`/`userId`) signaling no convention.
- **DB-resident logic that is invisible and unaudited**: triggers carrying business logic, recursive/cascading triggers, per-row triggers on bulk DML, or stored procedures split from the app with no ownership. Name what exists and whether it is safe; `SECURITY DEFINER` functions belong to DBSEC.
- Paper controls to hunt: an ORM-level uniqueness/association mistaken for a DB guarantee; a `GENERATED ... VIRTUAL` column relied on as if stored/indexable; a `DEFAULT` mistaken for `NOT NULL`. Engine note: Postgres native `ENUM` values cannot be removed and reordering requires type recreation, so prefer lookup tables for evolving sets.

**Constraints and Data Validation** (CONSTRAINTS) - *Owns: DB-enforced invariants; the enforcement mechanism, not the modeling choice.*
- **Required column left nullable** though the code always writes it: a second writer or import can insert NULL; require `NOT NULL`.
- **Natural key with no DB `UNIQUE`** deduplicated only by app `SELECT`-then-`INSERT` (check-then-act races under concurrency); require a `UNIQUE` constraint. This is the owner for app-only uniqueness.
- **Soft-delete table with a plain `UNIQUE`** that blocks re-creating a row after `deleted_at` is set; require a partial unique index `WHERE deleted_at IS NULL` (Postgres/SQLite) or a generated discriminator (MySQL).
- **Multi-tenant `UNIQUE` omitting `tenant_id`** (`UNIQUE(email)` instead of `UNIQUE(tenant_id, email)`), leaking collisions or wrongly rejecting rows.
- **Domain/range/format invariants left to app code**: no `CHECK (qty >= 0)`, `CHECK (start <= end)`, `CHECK (discount <= total)`, no email/slug format CHECK; require row-level CHECKs so any writer is bound.
- **Overlap invariants** (bookings, non-overlapping validity) enforced by app `SELECT`-then-`INSERT`; require a Postgres `EXCLUDE USING gist` exclusion constraint.
- **App-default-only columns** (`status='pending'`, `created_at=now()` set in the model but no DB `DEFAULT`): raw SQL and bulk import insert rows missing the value.
- **Mutually-dependent nullable columns** with no guard (`canceled_at` set but `cancel_reason` NULL); require `CHECK ((a IS NULL) = (b IS NULL))`.
- **An idempotency/exactly-once key** (payment idempotency key, webhook event id, dedup token) with no `UNIQUE`, permitting double processing.
- Paper controls to hunt: a `UNIQUE` on a nullable column (NULLs are distinct, so unlimited NULL rows slip through unless `NOT NULL`, `NULLS NOT DISTINCT` on PG15+, or a partial index); a Postgres CHECK/FK `NOT VALID` never validated; a SQL Server constraint `WITH NOCHECK`/untrusted; a MySQL `CHECK` silently ignored before 8.0.16; a partial-unique index used as an `ON CONFLICT` arbiter that does not match the insert's predicate; ORM/DTO validation treated as the integrity boundary.

**Transactions, Concurrency and Consistency** (TXN) - *Owns: atomicity, locking, isolation, and idempotency of writes.* Applies if a write path exists.
- **Read-modify-write on a mutable value** (read balance/qty, compute in app, write back the computed value) with no version check or row lock: lost updates; require atomic `SET col = col +/- :delta`, a version-checked `UPDATE ... WHERE version = :expected`, or `SELECT ... FOR UPDATE` in one transaction.
- **Optimistic-lock version column bumped but absent from the `UPDATE`'s `WHERE`**, or the affected-rowcount ignored so a 0-row update reads as success: the column is decoration.
- **Multiple dependent writes not wrapped in one transaction** (insert order, decrement inventory, insert payment as separate autocommit statements): a mid-sequence failure leaves a partial write.
- **External I/O inside an open transaction** (an HTTP/payment/email/S3 call between `BEGIN` and `COMMIT`) holding row locks for the call's latency; do DB work, commit, then call, or use a transactional outbox.
- **A retried/externally-triggered operation with no idempotency key** and no unique constraint to dedupe (webhook handler, payment capture doing a plain `INSERT`); persist a unique idempotency key in the same transaction as the effect.
- **Isolation too low for an invariant** read-checked then written under READ COMMITTED with no `FOR UPDATE` and no backing constraint (lost update / write skew); require SERIALIZABLE with a retry loop, row locks, or a DB constraint.
- **Inconsistent lock ordering** across paths that touch the same rows (deadlock risk); require one canonical order (`ORDER BY id FOR UPDATE`).
- **Long or unbounded transaction** (a loop, bulk `UPDATE`/`DELETE` with no chunking, or a user-wait inside `BEGIN`) holding locks and bloating MVCC; and a **transaction with no guaranteed commit/rollback on all paths** (no `try/finally`, leaving idle-in-transaction).
- **Cross-service workflow treated as atomic** but spanning services with no saga/compensation and no durable outbox; a downstream failure leaves the first service committed and orphaned.
- Paper controls to hunt: `SELECT ... FOR UPDATE` that cannot lock the phantom row the conflict needs (use a `UNIQUE`/`EXCLUDE`/SERIALIZABLE); a `@Transactional` that is inert (autocommit never disabled, self-invocation bypassing the proxy, rollback only on unchecked exceptions); SERIALIZABLE/REPEATABLE READ with no retry on serialization failure (40001); a "transaction" whose `BEGIN`/`COMMIT` are no-ops under driver autocommit; SQL Server snapshot isolation believed to stop lost updates (it does not). Also flag **cache/DB consistency**: stale-after-write and cache-stampede on expiry where a cache fronts the DB.

**Data Types and Storage Efficiency** (TYPES) - *Owns: physical type correctness. The owner for float money.*
- **Money as FLOAT/DOUBLE/REAL** (`price`/`amount`/`balance`/`total` typed floating-point, or ORM `Float`/`:float`): rounding error accumulates; require `NUMERIC/DECIMAL(p,s)` or integer minor units, plus a currency column for multi-currency. `DECIMAL` with no precision/scale (MySQL defaults to `(10,0)`, truncating) is the same defect.
- **Dates/times as `VARCHAR`/`TEXT`** or **Postgres `TIMESTAMP` (no tz) for instants** (`created_at`, `occurred_at`): use `TIMESTAMPTZ` with a UTC write path; the inverse (TIMESTAMPTZ for a wall-clock concept like a birthdate) is also wrong.
- **32-bit epoch/INT timestamp** subject to the 2038 overflow on data meant to outlive 2038.
- **UUID stored as `VARCHAR(36)`/`CHAR(36)`** rather than native `uuid`/`BINARY(16)` (wastes ~21 bytes/row and bloats every secondary index), and a **random UUIDv4 as the clustered/primary key** on a high-insert table (page splits, 30-60% index bloat, worst on InnoDB); prefer UUIDv7/ULID or a `BIGINT` identity, reserving v4 for a non-key external column.
- **Booleans as `VARCHAR`** (`'Y'`/`'N'`) or unconstrained int flags; **JSON in `TEXT`** or Postgres `json` instead of `jsonb` (loses GIN-indexability and reparses every read); **oversized integer keys** (`BIGINT` where `INT`/`SMALLINT` provably fits, or `INT` for a key that will exceed 2.1B).
- **`VARCHAR(255)` applied reflexively** to every string (post-utf8mb4 a `(255)` column is 1020 bytes, risking index key-length limits) and **`CHAR(n)` for variable-length data** (space-padding corrupts equality/LIKE).
- **MySQL `utf8`** (the 3-byte `utf8mb3` alias) silently truncating 4-byte emoji/CJK; require `utf8mb4` at server, table, and connection.
- **Large BLOBs stored inline** instead of object storage with a reference, and an **over-wide row** pushing values off-page (Postgres TOAST) so even narrow scans pay detoast I/O.
- **A sentinel value used instead of NULL** (`''`, `'1970-01-01'`, `-1`, `'9999-12-31'`) corrupting aggregates and three-valued logic.
- Paper controls to hunt: a model declaring `Decimal`/`Boolean`/`UUID` while the migration created `VARCHAR`/`FLOAT` (verify the DDL, not the model); `utf8mb4` on the table but the driver DSN still negotiates `utf8`/latin1; a `DECIMAL` scale too small for intermediate computation; a `BINARY(16)` UUID read/written as a 36-char string on every query; a `DEFAULT now()` on a no-tz `TIMESTAMP` marketed as auditing.

**Migrations and Schema Evolution** (MIGRATION) - *Owns: the safety mechanics of every schema change. Applies if migration tooling or DDL history exists.*
- **`ADD COLUMN` with a volatile DEFAULT** (`gen_random_uuid()`, `now()` per row) or, on old engines, any default: a full table rewrite under `ACCESS EXCLUSIVE`; add the column without a default, set the default, then backfill in batches.
- **`CREATE INDEX` without `CONCURRENTLY`** (Postgres) / `ALGORITHM=INPLACE, LOCK=NONE` (MySQL) / `ONLINE` (Oracle/SQL Server) on a large table: blocks writes for the build; and `CREATE INDEX CONCURRENTLY` wrapped in a transaction (must run outside one, or it errors / leaves an `INVALID` index).
- **A table-rewriting type change** (`ALTER COLUMN TYPE`, `INT`->`BIGINT`, narrowing precision) issued as one `ALTER` on a large table; require new-column + dual-write + backfill + swap.
- **A single-step `RENAME` or `DROP COLUMN`/`DROP TABLE` deployed with the code change**: running app instances still reference the old name; require expand-contract (add, dual-write, backfill, cut over, drop) across deploys, with a tombstone (`ignored_columns`) before a drop.
- **A data backfill in the same transaction as the DDL** or as one unbatched `UPDATE`: holds locks and bloats WAL; batch it separately with per-batch commits.
- **`SET NOT NULL` directly on a populated column** (full scan under lock); add a `CHECK (col IS NOT NULL) NOT VALID`, `VALIDATE`, then `SET NOT NULL`. **A FK or CHECK added and validated in one statement** rather than `NOT VALID` then `VALIDATE`.
- **A destructive migration with no reverse path and no backup gate** (a `change` block with `remove_column`/`drop_table`, an Alembic `downgrade` that is `pass`, a missing `.down.sql`).
- **A non-idempotent migration** (raw `CREATE`/`ADD` without `IF NOT EXISTS`, a seed `INSERT` without upsert) in a tool that can re-run or partially apply; **multiple migration heads / a mutated already-applied migration** (checksum drift); and **ad-hoc DDL outside the migration tool** producing schema drift.
- **No CI migration safety gate** (no `--check`/dry-run, no strong_migrations/squawk lint, no single-head assertion, no up-then-down round trip).
- Paper controls to hunt: a FK/CHECK added `NOT VALID` whose `VALIDATE` step was never written; a down migration that exists but is wrong or untested; a transaction giving the illusion of atomic rollback while it contains `CREATE INDEX CONCURRENTLY` or runs on MySQL/Oracle where DDL auto-commits; a `lock_timeout` configured for the app but not inherited by the migration session; a `safety_assured {}`/linter allowlist waving through the exact dangerous op; a backfill guarded by `WHERE col IS NULL` after a NOT NULL default already filled the column (matches zero rows, silently no-ops).

**Search and Text Retrieval** (SEARCH) - *Owns: substring/full-text/fuzzy/prefix/faceted/vector retrieval. Applies if a search or text-retrieval surface exists.*
- **Leading-wildcard substring search** (`LIKE '%term%'`, `.icontains`) over a large table with no trigram or FTS index: a full scan on the hot path. Require a `pg_trgm` GIN/GiST index or full-text search.
- **Full-text emulated with chained `LIKE`/`OR`** (no stemming, stop-words, or ranking) instead of `tsvector @@` + GIN (Postgres), `MATCH ... AGAINST` on a `FULLTEXT` index (MySQL), or `CONTAINS`/`FREETEXT` (SQL Server).
- **A `tsvector @@` query with no GIN index** on the matching expression (or a stored `tsvector` column with no GIN index): every query is a seq scan; the index expression and text-search config must match the query exactly.
- **Fuzzy/typo search with no similarity primitive** (no `pg_trgm` `similarity()`/`%`, no Levenshtein); a `LIKE` cannot do typo tolerance.
- **Case-insensitive search via `LOWER(col)=` with no expression index**, and **accent-insensitive search attempted with `citext` alone** (`citext` folds case, not accents; needs `unaccent` or a nondeterministic ICU collation).
- **Search returning rows in arbitrary or `created_at` order with no relevance ranking** (`ts_rank`, `MATCH ... AGAINST` score, `<->` distance).
- **Faceted/multi-filter search on single-column indexes only**, or a composite whose order ignores selectivity and the range predicate.
- **An external search engine kept in sync by app-level dual-write** (write DB then write Elasticsearch in the same handler): partial failure guarantees drift; require a transactional outbox + CDC and a documented reindex/backfill with delete propagation.
- **A vector/embedding column with no ANN index** (`hnsw`/`ivfflat`): every similarity query is brute force; the index operator class must match the query's distance operator (a cosine query against an L2 index will not use it). IVFFlat built before the data is loaded has degenerate centroids.
- **JSON path search** (`data->>'k' = ?`, `@>`) over a large table with no expression or GIN index.
- Paper controls to hunt: a `tsvector` GIN index whose config differs from the query's; a B-tree on the text column cited as "search is indexed" while the search uses `LIKE '%x%'`/`ILIKE`; a nightly full-rebuild reindex cited as the sync guarantee but with no delete propagation and a stale window; a vector index whose operator class does not match the query; access-control/tenant filtering enforced only in the search engine, leaking cross-tenant results.

**Scalability, Growth and Operations** (SCALE) - *Owns: capacity and operability over time. Always active at a low base weight; re-weight up when growth signals are strong.*
- **32-bit auto-increment PK on a high-churn table** (`INT`/`SERIAL` on events/logs/orders): max 2.1B, then inserts fail (Postgres can force read-only); require `BIGINT`, and audit FK columns that mirror it.
- **An ever-growing log/event/audit/session/outbox table with no retention** (no scheduled delete/archival, no TTL, no partition-drop); require a documented retention window and a batched reaper or `DETACH PARTITION + DROP`.
- **A large append-only/time-series table as a plain non-partitioned table**: purges become full-table deletes and queries cannot prune; require declarative range partitioning on the time/tenant key.
- **A single-row global counter or running balance updated on every write** (`UPDATE counters SET n=n+1 WHERE id=1`): serializes writes on one row's lock; require sharded counters or an append-and-aggregate ledger.
- **OFFSET deep pagination and unbounded result sets on growing tables** (cross-ref QUERY), and a **random UUIDv4 clustered key** fragmenting the index (cross-ref TYPES).
- **Per-request connections with no pooler**, or pool sizes that aggregate above server `max_connections` (serverless fan-out exhausts it: `too many connections`); and a **transaction-mode pooler combined with session-scoped state** (prepared statements, `SET`, advisory locks, temp tables).
- **A post-write read routed to a replica** with no read-your-writes guard: replica lag returns stale data on money/auth/inventory.
- **No autovacuum tuning on hot tables, no `ANALYZE` after bulk load, no slow-query observability** (`pg_stat_statements`, `log_min_duration_statement`, MySQL `slow_query_log`), and **no statement/lock/idle-in-transaction timeouts** at the role default.
- **No inferable backup/PITR posture and irreversible destructive migrations** (cross-ref MIGRATION); and **materialized views with no documented refresh** (drift, or a non-`CONCURRENTLY` refresh that locks).
- Paper controls to hunt: a `created_at` index on the events table but no retention job using it; range partitioning declared but partition creation/drop is manual (inserts fail at the boundary, old partitions never dropped); a keyset index on `(sort_key)` missing the `id` tiebreaker; `autovacuum = on` cited as protection while a long transaction or unused replication slot holds `xmin` back; a PK migrated to `BIGINT` while a referencing FK stayed `INT`; a `statement_timeout` set per session but not at the role default.

**Non-relational and analytics surfaces** (conditional lens, not a separately weighted dimension) - apply when the target is a document, key-value, wide-column, vector, time-series, or analytics store, and **redirect each finding into the scored dimension it belongs to** (embedding/growth into SCHEMA/SCALE, index-shape into INDEX, consistency into TXN, injection into DBSEC), tagging it `NOSQL`/`ANALYTICS`. Calibrate: denormalization here is correct.
- **MongoDB**: an unbounded embedded array (`$push` with no `$slice`/bucket) trending toward the 16MB BSON limit; embedding an independently-queried or shared entity instead of referencing; a query filtering/sorting on a field with no index (COLLSCAN), where compound-index order must follow Equality-Sort-Range; a collection with no `$jsonSchema` validator (or one at `validationLevel: moderate`/`warn`, so it is advisory) letting field types drift.
- **DynamoDB**: a relational multi-table model with app-side joins rather than access-pattern-first design; a low-cardinality or monotonic partition key creating a hot partition; a `Scan` with `FilterExpression` on a routine read path; a GSI whose key schema does not cover the query (falls back to Scan, or `KEYS_ONLY` projection forcing a second `GetItem`); a strongly-consistent invariant read from an eventually-consistent GSI; an unbounded item-collection nearing the 400KB item / 10GB partition ceilings.
- **Cassandra**: an unbounded partition (`PRIMARY KEY (user_id, ts)` for all events forever); `ALLOW FILTERING` or a high-cardinality secondary index triggering cluster-wide scans; a queue/delete-heavy table accumulating tombstones past the failure threshold.
- **Redis**: keys with no TTL while `maxmemory-policy` is `noeviction` (OOM write failures); an ever-growing collection key (big-key) blocking the single-threaded event loop; Redis used as the sole system of record for durable data with no AOF and no upstream source of truth.
- **Analytics/warehouse (Snowflake, BigQuery, Redshift, ClickHouse, dbt)**: clustering/sort/dist keys and partition pruning are the columnar analog of INDEX (route to INDEX); fact/dimension grain, slowly-changing dimensions, and the fact that wide denormalized marts are correct (route to SCHEMA); dbt model materialization (view vs table vs incremental), an incremental model's `unique_key` and late-arriving-data handling, and the presence of `dbt test` (`not_null`/`unique`/`relationships`/`accepted_values`) and source freshness (route to CONSTRAINTS/SCALE). Flag SQL-in-Jinja injection (route to DBSEC).
- **Time-series (TimescaleDB, InfluxDB, Prometheus)**: hypertable chunking, continuous aggregates, and compression/retention policies (route to SCALE); high-cardinality tag/label explosion (the classic Prometheus outage).

### Phase 3 - Verify adversarially and cluster

- For each candidate, try to refute it: is there a DB constraint, a partial/expression index, a generated column, a trigger, a database default, a framework guarantee, or a deliberate documented trade-off that neutralizes it? Is the table actually large/hot, or is this a ten-row lookup where the "problem" is irrelevant? Adjust or drop.
- Assign Severity, Confidence, and Effort (definitions below).
- Default to caution: if you could not confirm the data path, the table's scale, or the control's absence by reading the code, mark it Suspected and say what would confirm it (a row count, an `EXPLAIN`, an index-usage stat, a config value).
- Cluster repeated instances of one root problem into a single systemic finding, keeping the instance IDs as members, and apply the ownership map so a single defect does not fire under three dimensions.

### Phase 4 - Score

First decide which dimensions are **active** vs **N/A** based on the surfaces found in Phase 0. Score each active dimension 0-100 on how adequate the data layer is for that lens (justified by its findings). The overall score is the weighted average of the active dimensions.

| Dimension | Weight | Applies |
|---|---|---|
| Referential Integrity and Relationships (INTEGRITY) | 14% | always (relational); remapped via the conditional lens for non-relational |
| Indexing Strategy (INDEX) | 13% | always |
| Query Performance and Access Patterns (QUERY) | 12% | always |
| Security and Data Protection at the DB layer (DBSEC) | 12% | always |
| Schema Design and Data Modeling (SCHEMA) | 11% | always |
| Constraints and Data Validation (CONSTRAINTS) | 10% | always |
| Transactions, Concurrency and Consistency (TXN) | 9% | if a write path exists (else fold its weight) |
| Data Types and Storage Efficiency (TYPES) | 7% | always |
| Migrations and Schema Evolution (MIGRATION) | 6% | if migration tooling or DDL history exists |
| Search and Text Retrieval (SEARCH) | 4% | if a search/text-retrieval surface exists |
| Scalability, Growth and Operations (SCALE) | 2% | always (re-weight up when growth signals are strong) |

**Conditional re-normalization:** when a conditional dimension is N/A (no write path, no migrations, no search surface), drop it from the table and re-normalize the remaining weights to sum to 100 by proportional scaling (do not zero-and-keep, which would deflate the score). When the target is a non-relational store, apply the conditional lens and redirect its findings into the scored dimensions rather than scoring a twelfth bucket. Report which dimensions were active vs N/A so the score is reproducible.

Score bands (per dimension and overall): 90-100 = A (exemplary), 80-89 = B (solid, minor issues), 70-79 = C (adequate, real gaps), 60-69 = D (weak, systemic problems), 0-59 = F (failing, critical deficiencies).

**Risk does not average away.** A single Critical finding caps its dimension at 69 and caps the overall at 79 until resolved. Treat severity independently of the weighted average. The following are **Critical regardless of the numeric score**: monetary/ledger/balance data stored as binary float; financial or audit data with no enforced FK and a delete path that can orphan or cascade-destroy it; any user-controlled input concatenated into a query or DDL (SQL/NoSQL injection); a migration that rewrites or holds a long exclusive lock on a large production table, or an irreversible destructive migration with no backup gate; an identity/payment/idempotency uniqueness invariant enforced only in app code; a money movement that is non-atomic or a read-modify-write with no lock/version/constraint; a database reachable from the public internet or running on default/empty/trust auth; PII/PHI/financial data in plaintext (storing CVV at all is Critical); multi-tenant isolation that depends solely on app `WHERE` clauses, or RLS that is bypassed; and an `INT` PK already trending toward 2.1B rows. **Security and data-loss floor:** any of the injection, public-exposure, committed-live-secret, plaintext-PII, or float-money criticals caps the overall grade no matter how good the rest of the schema is, so a beautifully-modeled but internet-exposed or money-losing database cannot score well.

### Phase 5 - Prioritize

Definitions:
- **Severity** - Critical (data loss, corruption, money error, injection, auth/tenant breach, or an outage-grade migration; act immediately) / High (a serious correctness or performance defect on a hot or sensitive path; act this cycle) / Medium (a real weakness with preconditions or on a lower-value surface; schedule it) / Low (a minor best-practice or hygiene gap; batch it).
- **Confidence** - Confirmed (the data path and the control's absence are reproducible from the cited DDL/migration/query) / Likely (strong evidence resting on a stated assumption about table size, traffic, or runtime config) / Suspected (inferred without confirming scale or the control's absence; verify before acting, often needs a row count or query plan).
- **Effort** - S (a localized constraint/index/type change, under ~1 hour, but apply it with the lock-safe migration) / M (a few files or a multi-step expand-contract migration, ~half a day) / L (a data-model change, a backfill, or a cross-cutting redesign, multiple days).

Bucket every finding: **Quick wins** (High/Critical, Confirmed, S), **Plan now** (High/Critical, M or L), **Verify first** (any Suspected, especially anything whose severity depends on real data volume or a query plan), **Backlog** (Low). Order the "What to fix first" list as the union of Quick wins and Plan now, Critical before High, breaking ties toward findings that also close a systemic pattern or protect money, identity, or tenant data. For any fix that touches a large table, the recommended action must include the lock-safe migration path.

### Phase 6 - Write dbaudit.md

Write to `<codebase-root>/dbaudit.md` with these sections in order. Keep finding IDs stable using a dimension prefix and number: INTEGRITY, INDEX, QUERY, DBSEC, SCHEMA, CONSTRAINTS, TXN, TYPES, MIGRATION, SEARCH, SCALE, and NOSQL/ANALYTICS for the conditional lens (for example `INTEGRITY-001`).

1. **Title and banner** - project name; a line stating this is a read-only database audit of the code as written, the date, that no live database was touched and no migration was run, and that the report is self-contained.
2. **Snapshot** - project, state (commit or branch), engine(s) and dialect, ORM/query layer, migration tool, non-relational and analytics surfaces, workload paradigm, data sensitivity and tenancy, size (tables, migrations, models), audit coverage (exhaustive or sampled, with what was sampled), and exclusions.
3. **Data model map** - the half-page map from Phase 1: entities and the relationship graph (DB-enforced vs ORM-only vs cross-service), hot tables and dominant queries, write/transaction boundaries, growth-bearing tables, and the highest-risk flows traced.
4. **Overall score** - `NN/100 - Grade X (label)`, a two-to-four sentence specific verdict, and a one-line calibration note (paradigm and assumed scale). Then a scorecard table: Dimension, Score, Grade, Weight (after re-normalization), Active/N-A, one-line specific verdict; final row is the weighted overall. State which conditional dimensions were dropped and how weights were re-normalized.
5. **What to fix first** - the ordered priority list. Each line: `[ID] title - severity, effort - one-line why`.
6. **Strengths (preserve these)** - what the data layer gets right, each with evidence. The acting agent must not remove these while fixing other issues.
7. **Systemic patterns (root causes)** - one entry per recurring root cause (no FK discipline; money is float schema-wide; no DB-level uniqueness; no pagination), with the member finding IDs and the one root fix.
8. **Findings** - sorted by severity then dimension. Each finding is a self-contained block in this exact shape:

   ```
   ### [INTEGRITY-001] <title>
   - Severity: <Critical/High/Medium/Low> | Confidence: <Confirmed/Likely/Suspected> | Effort: <S/M/L> | Dimension: <name> | Owner: <dimension or "this>
   - Location: `file:line` (table/column/index/migration, and other locations)
   - Evidence: <what the schema/query/migration does now, precisely, including the data path>
   - Impact: <the concrete consequence: data loss, corruption, money error, slow path, outage, leak; and the blast radius / table scale>
   - Recommendation: <the specific change and the safe pattern, including the lock-safe migration for a large table; not a platitude>
   - Verify the fix: <a query plan to re-check, a constraint to add, a count that should now be zero, or a check to run>
   - References: <book/doc/standard, e.g. SQL Antipatterns ch.10; PostgreSQL "Constraints"; Use The Index, Luke>
   - Related: <systemic pattern or finding IDs, or "none">
   ```

9. **Dimension notes** - one short subsection per active dimension tying the score to its findings, and a line for each N/A dimension saying why it was skipped.
10. **Remediation plan** - the four buckets (Quick wins, Plan now, Verify first, Backlog) listed by ID, with Plan now in suggested order.
11. **Scope and limitations** - what was and was not examined, sampling decisions, and which findings need a running database, real data volumes, or a query plan to confirm; plus the assumptions (paradigm, scale, deployment) that would change conclusions if untrue.
12. **How to use this report (for the acting agent)** - include this protocol verbatim:
    1. Triage by severity and confidence. Confirmed Critical and High are safe to act on now, in the order in "What to fix first". Re-verify any Suspected finding (and the table's real scale) before changing anything.
    2. Fix root causes first; prefer the systemic pattern (a uniform FK or pagination policy) over individual leaves.
    3. Preserve the strengths; do not remove a working constraint, index, or generated column while fixing another issue.
    4. Apply every schema change with the lock-safe migration path (`CONCURRENTLY`, `NOT VALID` then `VALIDATE`, expand-contract, batched backfill). The fix must not cause the outage.
    5. One finding, one change, verified: after each fix run its "Verify the fix" step; keep changes atomic and traceable to the finding ID.
    6. Do not widen scope silently; note adjacent issues rather than sprawling into a redesign.
    7. Re-run the audit to measure progress; confirm findings are resolved, not relocated, and watch for regressions in the strengths.

### Phase 7 - Report in chat

After the file is written, print a concise summary to the chat so the user sees the result without opening the file. Include, in this order:
- One headline line: `Database audit complete: NN/100 (Grade X)` followed by the one-line verdict.
- The scorecard table (active dimensions plus the weighted overall; note any N/A dimensions).
- "What to fix first": the top three to five items, each `[ID] title - severity, effort`.
- Counts: number of findings by severity (for example `Critical 2, High 5, Medium 8, Low 6`).
- The path to the full report: `Full report: ./dbaudit.md`.
Keep it tight. The file holds the detail; the chat holds the verdict and the next actions.

---

## Quality gates (self-check before declaring done)

- Every finding cites at least one `file:line` and names the table, column, constraint, index, query, or migration. Run the substitution test on each title and impact line; rewrite anything that would read true for a different repo.
- Every finding states a concrete consequence and its blast radius, not just the presence of a pattern; a missing index on a tiny lookup table is not reported as if it were on the hot path.
- Each finding is emitted by exactly one dimension per the ownership map; the same defect does not appear (and re-score) under three lenses.
- Claims are verified against the actual DDL/migration, not the ORM model or a comment; an ORM-only uniqueness or association is reported as such.
- Paper controls were actively hunted, not just absences (FK `NOT VALID`, `UNIQUE` on nullable, an unusable index, an inert `@Transactional`, RLS not `FORCE`d, dual-write search sync).
- Every dimension score has a justification tied to specific findings, and conditional re-normalization is shown; the risk caps and the security/data-loss floor were applied.
- Every finding has Severity, Confidence, and Effort set, and a reference (book/doc/standard).
- Every recommendation says what to change, the safe pattern, and how to verify it, and includes the lock-safe migration path for any change to a large table. No platitudes.
- Repeated issues are clustered into systemic patterns; there are not many near-identical findings left loose.
- Suspected findings are clearly marked with what would confirm them (a row count, an `EXPLAIN`, an index-usage stat, a config value).
- The data-model map and the Strengths section are present and evidence-backed; the paradigm calibration is stated.
- The report is at the codebase root, named exactly `dbaudit.md`, no live database was touched, no migration was run, no source was changed, and the chat summary was printed.

## Notes

- Read-only and non-destructive. Use search and read tools to investigate, and shell commands only for inspection (listing migrations, counting files, reading manifests and lockfiles, checking version-control state). Do not connect to a database, run or generate migrations, execute the project's code, run `EXPLAIN` against a server, or touch any live system.
- Reason about performance and correctness from the code; never benchmark a live system and never claim you did. Where a verdict depends on real data volume or a query plan, mark it Suspected and say what would confirm it.
- Verify against the shipped DDL. The ORM model, the schema comment, and the README state intent; the migration states reality. When they disagree, the gap is the finding.
- Calibrate to the paradigm and the data's value. Denormalization is correct in a warehouse and a document store; spend the most effort on money, identity, tenant isolation, referential integrity, and the hot-path queries and indexes.
- For a large codebase, sample deliberately (the schema dump, the migration history, the hot-path queries, the money and auth tables, the search and growth surfaces) and declare exactly what you sampled.
- Cite the standard reference where it helps (SQL Antipatterns by Bill Karwin; SQL Performance Explained / Use The Index, Luke by Markus Winand; Designing Data-Intensive Applications by Martin Kleppmann; the PostgreSQL/MySQL/SQL Server/Oracle docs; the strong_migrations and Squawk bodies of knowledge), since many teams reference them directly.
