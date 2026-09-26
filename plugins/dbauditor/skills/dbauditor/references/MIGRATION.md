# MIGRATION: Migrations and Schema Evolution

Weight 6. Active when migration tooling or DDL history exists.
Owns: the safety mechanics of every schema change: locks and table rewrites, index builds, destructive and breaking changes, backfills, schema changes made by the ORM at runtime, and whether the migration history can be replayed and trusted. Every other dimension owns the end state it wants; how to reach it safely is judged here.
Not here: the end state itself (the missing index, constraint, or type belongs to INDEX, INTEGRITY, CONSTRAINTS, or TYPES); a foreign key or CHECK left `NOT VALID` (INTEGRITY-R3, CONSTRAINTS-R5); backup and point-in-time recovery posture (SCALE, Also check).
Standards: PostgreSQL ALTER TABLE and CREATE INDEX docs, MySQL online DDL docs, strong_migrations, Squawk, Refactoring Databases (Ambler and Sadalage).
Read first: the migration directory in order, the migration tool's config (does it wrap each migration in a transaction?), the deploy or release script that runs migrations, and the README's table sizes. A table created in the same migration is empty: locks on it do not matter.

## Cards

### MIGRATION-R1 Index built with a blocking lock on a large existing table (quick)
- Leads: `scan.sh MIGRATION-R1` lists index builds in migrations and the settings that make them online.
- Confirm: a migration adds an index to a table that already holds data (not one created in the same migration) without the online form: PostgreSQL `CREATE INDEX` without `CONCURRENTLY` (writes block for the whole build), MySQL without `ALGORITHM=INPLACE, LOCK=NONE`, SQL Server without `ONLINE = ON`, Oracle without `ONLINE`. ORM helpers: Rails `add_index` without `algorithm: :concurrently`, Django `AddIndex` instead of `AddIndexConcurrently`, Knex `table.index()`, Alembic `create_index` without `postgresql_concurrently=True`. Also `CREATE INDEX CONCURRENTLY` inside a transaction (it errors), and a failed concurrent build left behind as an INVALID index.
- Not a finding if: the table is created in the same migration or is small by nature (cite the README or seeds); the migration runs in a documented maintenance window.
- Severity: Critical when the table is large and written in production (writes stall for the whole build, an outage); High when the size is unknown but the table grows with use (Likely); Low for small tables.
- Fix: build concurrently outside a transaction: Rails `disable_ddl_transaction!` plus `algorithm: :concurrently`; Django `AddIndexConcurrently` with `atomic = False`; Knex `exports.config = { transaction: false }` plus `knex.raw('CREATE INDEX CONCURRENTLY IF NOT EXISTS ...')`; Alembic inside `op.get_context().autocommit_block()`. Set a short `lock_timeout` and retry; after a failed build, drop the INVALID index and rebuild.
- Verify the fix: the migration's SQL is `CREATE INDEX CONCURRENTLY` outside a transaction, and on a production-size copy writes continue during the build.
- Refs: PostgreSQL docs, CREATE INDEX (Building Indexes Concurrently); strong_migrations; Squawk require-concurrent-index-creation

### MIGRATION-R2 Schema change that rewrites or scans a large table under an exclusive lock (quick)
- Leads: `scan.sh MIGRATION-R2` lists ALTER statements, column type and default changes, NOT NULL changes, and constraint additions in migrations.
- Confirm: on a table that already holds data, a migration changes a column type (`ALTER COLUMN TYPE`, `INT` to `BIGINT`, narrowing, `change_column`), which rewrites the table under an exclusive lock; adds a column with a volatile default (`gen_random_uuid()`, `random()`, `clock_timestamp()`), or with any default on PostgreSQL before 11 (on MySQL before 8.0.12 every `ADD COLUMN` rebuilds the table); runs `SET NOT NULL` on a populated column (a full scan under the lock); or adds a foreign key or CHECK and validates it in one statement (no `NOT VALID`). Also any statement that needs an exclusive lock with no `lock_timeout`: it queues behind a long query and every later query queues behind it.
- Not a finding if: the table is new or small; the step already uses the safe form below; PostgreSQL 11 or later with a non-volatile default (`now()` is stable and does not rewrite); PostgreSQL 12 or later with a validated `CHECK (col IS NOT NULL)` in place before `SET NOT NULL`.
- Severity: Critical when the table is large and written in production; High when the size is unknown but grows (Likely); Low for small tables.
- Fix: type change: new column, dual-write, batched backfill, swap, drop later. Default: add the column without a default, set the default, backfill in batches. NOT NULL: `ADD CONSTRAINT ... CHECK (col IS NOT NULL) NOT VALID`, `VALIDATE CONSTRAINT`, `SET NOT NULL`, drop the CHECK. Constraints: `NOT VALID`, then `VALIDATE` in a separate migration. Run every step with `SET lock_timeout = '5s'` and a retry.
- Verify the fix: the migration shows the multi-step form, and on a production-size copy concurrent writes continue during each step.
- Refs: PostgreSQL docs, ALTER TABLE (notes); strong_migrations; Squawk constraint-missing-not-valid and changing-column-type

### MIGRATION-R3 Destructive or breaking change shipped in one step, or with no way back (quick)
- Leads: `scan.sh MIGRATION-R3` lists drops, renames, and down migrations.
- Confirm: a migration drops or renames a column or table in the same deploy as the code change, so running instances that still use the old name fail until the rollout ends and a rollback cannot restore it; or a destructive step (drop, narrowing, data delete) has no reverse path and no backup gate: Rails `remove_column` or `drop_table` in `change` without the column type, an Alembic `downgrade` that is `pass`, a missing `.down.sql`, `IrreversibleMigration` with no backup step.
- Not a finding if: expand-contract was followed (the code stopped using the column in an earlier deploy, for example Rails `ignored_columns`) and the data was archived or is disposable; the README requires and describes a verified backup before destructive migrations.
- Severity: Critical when data is dropped with no backup gate and no reverse path; High when a rename or drop breaks running instances during a deploy; Medium otherwise.
- Fix: expand-contract across deploys: add, dual-write, backfill, move reads, stop writes, then drop behind a tombstone; take and verify a backup before destructive steps; write a real down migration or a documented forward fix.
- Verify the fix: history shows the drop in a later deploy than the code that stopped using it, and the down migration round-trips on a copy.
- Refs: strong_migrations (removing and renaming columns); Refactoring Databases (Ambler and Sadalage)

### MIGRATION-R4 Data backfill inside the schema change's transaction or in one unbatched statement (quick)
- Leads: `scan.sh MIGRATION-R4` lists UPDATE statements, data migrations, and batch helpers in migrations.
- Confirm: a migration updates existing rows in the same transaction as DDL (the DDL's exclusive lock is held for the whole backfill), or in one `UPDATE` over a large table (every row locked, WAL and replica lag spike, bloat); or a backfill guarded by `WHERE col IS NULL` runs after a `NOT NULL DEFAULT` already filled the column, so it updates nothing.
- Not a finding if: the table is small; the backfill runs outside the DDL transaction in batches with a commit per batch.
- Severity: Critical when it runs inside the DDL transaction on a large production table; High when unbatched on a large table; Medium otherwise.
- Fix: separate the backfill from the DDL; batch by primary key range (1,000 to 10,000 rows per statement) with a commit and a short pause per batch; run long backfills as a job.
- Verify the fix: no UPDATE shares a transaction with ALTER, and a dry run on a copy shows short lock times.
- Refs: strong_migrations (backfilling data); PostgreSQL docs, Explicit Locking

### MIGRATION-R5 Schema changed at application startup by the ORM instead of reviewed migrations (quick)
- Leads: `scan.sh MIGRATION-R5` lists ORM sync and auto-migrate settings and schema push commands.
- Confirm: production code or config lets the ORM change the schema: TypeORM `synchronize: true`, Sequelize `sync({ alter: true })` or `sync({ force: true })`, Hibernate `hbm2ddl.auto` or `spring.jpa.hibernate.ddl-auto` set to `update`, `create`, or `create-drop`, SQLAlchemy `create_all()` at startup beside migrations, GORM `AutoMigrate` in the serving path, `prisma db push` in a deploy script.
- Not a finding if: the setting applies only to tests or local development (read the environment switch).
- Severity: Critical when it can drop tables or columns in production (`force: true`, `create`, `create-drop`, `synchronize` after a field is removed, `db push --accept-data-loss`); High when it only adds objects (unreviewed drift).
- Fix: disable the sync outside development and ship every change as a reviewed migration.
- Verify the fix: production config has the sync off, and the deploy runs only the migration tool.
- Refs: TypeORM docs (synchronize); Hibernate docs (hbm2ddl.auto); Prisma docs (db push)

### MIGRATION-R6 Migration history that cannot be replayed or trusted
- Leads: `scan.sh MIGRATION-R6` lists idempotency guards, revision links, and migration checks in code and CI.
- Confirm: raw DDL without `IF NOT EXISTS`, or seed inserts without upsert, in a tool that can re-run or partially apply; several heads (Alembic branches, conflicting Django leaf migrations); an already-applied migration edited in place (checksum drift: Flyway `validate` fails and environments diverge); or DDL applied outside the tool (console changes, drift between `schema.rb` or `structure.sql` and the migrations).
- Not a finding if: the tool verifies checksums and CI fails on drift; a merge migration joins the heads.
- Severity: High when an applied migration was edited or production drifts from the history; Medium otherwise.
- Fix: never edit applied migrations; add forward migrations; gate CI with a single-head check, `makemigrations --check`, `alembic check`, `prisma migrate diff`, or Flyway `validate`, an up-then-down round trip, and a lint (strong_migrations, Squawk).
- Verify the fix: CI fails on a deliberately edited applied migration or a second head.
- Refs: Flyway docs (validate); Alembic docs (branches, check); Django docs (makemigrations --check)

## Also check
- No migration safety gate in CI on a project whose CI runs migrations (no dry run, no strong_migrations or Squawk lint, no single-head check, no up-then-down round trip): file under MIGRATION-R6.
- Seed or fixture files that change the schema, or seed data used as a migration.

## Paper controls (look protective, protect nothing)
- A foreign key or CHECK added `NOT VALID` whose `VALIDATE` step was never written: file under INTEGRITY-R3 or CONSTRAINTS-R5.
- A down migration that exists but is wrong or never run.
- A transaction that looks like atomic rollback while it contains `CREATE INDEX CONCURRENTLY` (not allowed in a transaction) or runs on MySQL or Oracle, where each DDL statement commits implicitly.
- A `lock_timeout` set for the app role but not for the migration session.
- `safety_assured { }` or a linter allowlist waving through the exact dangerous operation.
- A backfill guarded by `WHERE col IS NULL` after a NOT NULL default filled the column (MIGRATION-R4).
