# Dated engine facts

Last reviewed: 2026-09-26.

Engine behavior changes between versions. Before you rely on a fact, find the version the project runs (the database image tag in a Dockerfile or compose file, `engine_version` in IaC, the README) and state the version you assumed in Scope and limitations. When the version is unknown, assume the oldest version still supported and say so.

## PostgreSQL

- Foreign keys never index the referencing column automatically.
- 11: `ADD COLUMN` with a non-volatile default is metadata-only. Volatile defaults (`gen_random_uuid()`, `random()`, `clock_timestamp()`) still rewrite the table. `now()` is stable: evaluated once, no rewrite.
- 12: `SET NOT NULL` skips the full scan when a validated `CHECK (col IS NOT NULL)` exists. `REINDEX CONCURRENTLY` exists. `ALTER TYPE ... ADD VALUE` may run in a transaction block, but the new value is usable only after commit.
- Enum values cannot be removed, and reordering needs the type recreated.
- `CREATE INDEX CONCURRENTLY` cannot run in a transaction block. A failed build leaves an INVALID index that is maintained on writes and never used; drop it (`DROP INDEX CONCURRENTLY`) and rebuild.
- `CREATE INDEX CONCURRENTLY` does not work on a partitioned parent: create the parent index `ON ONLY` the parent, build each partition's index concurrently, then `ALTER INDEX ... ATTACH PARTITION` each one.
- `ADD CONSTRAINT ... NOT VALID` takes a brief lock; the later `VALIDATE CONSTRAINT` scans without blocking normal reads and writes.
- 15: `UNIQUE NULLS NOT DISTINCT`; views with `security_invoker`; new databases no longer grant `CREATE` on the `public` schema to `PUBLIC` (upgraded databases keep the old grant); each database records its collation version and warns on a mismatch.
- 18 (released 2025-09-25): virtual generated columns, now the default kind, which cannot be indexed; `uuidv7()`; `NOT ENFORCED` CHECK and foreign key constraints (declared, never checked); `WITHOUT OVERLAPS` primary and unique keys (temporal constraints); B-tree skip scan when the leading column has few distinct values.
- glibc 2.28 (Debian 10, Ubuntu 18.10, RHEL 8) changed the sort order of many locales: text indexes built before an OS upgrade across that version can be silently corrupt until `REINDEX`. ICU library upgrades do the same to ICU collations.
- Row-level security: superusers and `BYPASSRLS` roles always bypass it; table owners bypass it unless `FORCE ROW LEVEL SECURITY` is set.
- libpq `sslmode`: `prefer` (the default) falls back to plaintext; `require` encrypts but does not verify the server (unless a root certificate file is present, when it acts like `verify-ca`); `verify-full` also checks the host name.
- SQLSTATE: 23505 unique violation, 23503 foreign key violation, 23514 check violation, 23P01 exclusion violation, 40001 serialization failure, 40P01 deadlock, 55P03 lock not available (lock_timeout).
- Transaction ID wraparound: autovacuum must freeze old rows. Long transactions, abandoned replication slots, and orphaned prepared transactions hold the xmin horizon back; near the limit the server refuses commands that need a new transaction ID.
- Default isolation is READ COMMITTED.

## MySQL and MariaDB

- `CHECK` constraints are parsed and ignored before MySQL 8.0.16 and enforced from 8.0.16. MariaDB enforces them from 10.2.1.
- `utf8` means `utf8mb3` (at most 3 bytes per character); 4-byte characters need `utf8mb4`. The server default is `utf8mb4` from MySQL 8.0.
- `DECIMAL` with no precision is `DECIMAL(10,0)`.
- InnoDB needs an index on referencing columns and creates one when none exists. MyISAM parses foreign key clauses and ignores them.
- Online DDL (8.0): `ADD COLUMN` can be `ALGORITHM=INSTANT` from 8.0.12 (last position only until 8.0.29); before 8.0.12 every `ADD COLUMN` rebuilds the table; `ADD INDEX` supports `ALGORITHM=INPLACE, LOCK=NONE`; adding a foreign key is in place only with `foreign_key_checks` off, otherwise the table is copied; changing a column's type copies the table and blocks writes.
- DDL commits implicitly, so a migration's transaction cannot roll it back.
- `TIMESTAMP` ends at 2038-01-19 03:14:07 UTC; `DATETIME` covers years 1000 to 9999.
- InnoDB index key limit: 3,072 bytes for DYNAMIC and COMPRESSED rows, 767 bytes for REDUNDANT and COMPACT; `utf8mb4` counts 4 bytes per character.
- Before 8.0, `DESC` in an index definition was parsed and ignored. Invisible indexes (8.0) are maintained but not used. Skip-scan range access exists from 8.0.13.
- Default isolation is REPEATABLE READ. Unique indexes allow many NULLs.

## SQL Server

- Foreign key columns are not indexed automatically.
- A `UNIQUE` constraint allows only one NULL; a filtered unique index (`WHERE col IS NOT NULL`) allows several.
- Constraints added or re-enabled `WITH NOCHECK` are untrusted (`is_not_trusted = 1`) and ignored by the optimizer; `WITH CHECK CHECK CONSTRAINT` re-validates them.
- `ONLINE = ON` index builds need Enterprise edition or Azure SQL.
- `DECIMAL` with no precision is `DECIMAL(18,0)`.
- `READ_COMMITTED_SNAPSHOT` does not prevent lost updates. SNAPSHOT isolation raises update conflict error 3960 on write-write conflicts but still allows write skew.
- Dynamic Data Masking only masks display; anyone who can run queries can infer masked values with predicates.

## SQLite

- Foreign keys are off by default and must be enabled per connection: `PRAGMA foreign_keys = ON`.
- Types are dynamic: a `DECIMAL` or `NUMERIC` column stores fractional values as 8-byte floats. STRICT tables (3.37.0) enforce declared types but offer no decimal type, so store money as integer minor units.
- `ALTER TABLE ... DROP COLUMN` exists from 3.35.0; most other changes need a table rebuild. Unique indexes allow many NULLs.

## Oracle

- Foreign key columns are not indexed automatically; without the index, deleting a parent or changing its key locks the child table.
- The empty string is NULL. DDL commits implicitly. `ONLINE` index builds need Enterprise Edition.

## ORM and framework defaults

- Rails 5.1 and later: primary keys and `t.references` are `bigint`; `t.references` and `add_reference` add an index but a foreign key only with `foreign_key: true`; `add_foreign_key` adds no index; `validates ... uniqueness` creates no constraint. On PostgreSQL `t.datetime` is `timestamp` without time zone unless `datetime_type = :timestamptz` (Rails 7.0 and later).
- Django: `AutoField` is 32-bit; projects created with Django 3.2 or later set `DEFAULT_AUTO_FIELD` to `BigAutoField`, older projects keep `AutoField`. `DateTimeField` with `USE_TZ = True` is `timestamp with time zone` on PostgreSQL. `unique=True` and `ForeignKey` reach the database only through generated migrations. `AddIndexConcurrently` needs `atomic = False`.
- Prisma on PostgreSQL: `mode: 'insensitive'` filters are sent as `ILIKE`; `DateTime` is `timestamp(3)` without time zone unless `@db.Timestamptz`; `String @id @default(uuid())` is `text` unless `@db.Uuid`; `Float` is `double precision`; `Int @id @default(autoincrement())` is `serial` (32-bit); relation scalar fields get no index automatically; `relationMode = "prisma"` emits no foreign keys and emulates referential actions in the client.
- Knex on PostgreSQL: `increments()` is a 32-bit key and `bigIncrements()` a 64-bit one; `float()` is `real`; `timestamp()` and `timestamps()` are `timestamptz` unless `useTz: false`; `enu()` is a text column with a CHECK unless `useNative: true`; migrations run in a transaction unless `exports.config = { transaction: false }`.
- Sequelize: the default `id` is a 32-bit `INTEGER`; `DataTypes.DATE` is `timestamp with time zone` on PostgreSQL; `sync({ force: true })` drops tables.
- TypeORM: `@PrimaryGeneratedColumn()` is a 32-bit integer; `synchronize: true` can drop columns.
- SQLAlchemy: `DateTime` is `timestamp` without time zone unless `timezone=True`.
- Laravel: `$table->id()` is 64-bit and `increments()` 32-bit; `foreignId()` creates only the column until `->constrained()` is added.
- Spring: `@Transactional` rolls back only on unchecked exceptions by default, and proxies do not intercept calls from inside the same class.
- node-postgres: a transaction must use one client from `pool.connect()`; `pool.query('BEGIN')` can send each statement on a different connection.
- PgBouncer 1.21 (2023) and later support named prepared statements in transaction mode through `max_prepared_statements`; earlier versions do not.

## Other stores and standards

- UUIDv7 is defined in RFC 9562 (May 2024).
- Signed 32-bit epoch seconds overflow at 2038-01-19 03:14:07 UTC.
- MongoDB: 16 MB document limit; multi-document transactions need a replica set (4.0) or a sharded cluster (4.2).
- DynamoDB: 400 KB item limit; 10 GB per partition key value on tables with a local secondary index; global secondary indexes are eventually consistent only.
- Cassandra defaults: `tombstone_warn_threshold` 1,000 and `tombstone_failure_threshold` 100,000.
- Snowflake enforces only NOT NULL; its PRIMARY KEY, UNIQUE, and FOREIGN KEY are declarations. BigQuery keys must be declared `NOT ENFORCED`. Redshift constraints are informational.
- PCI DSS v4.0.1: sensitive authentication data, including the card verification code, may not be stored after authorization, even encrypted (requirement 3.3); stored card numbers must be unreadable (requirement 3.5).
- OWASP Top 10 2025: A01 Broken Access Control, A02 Security Misconfiguration, A04 Cryptographic Failures, A05 Injection (A03 in 2021).
