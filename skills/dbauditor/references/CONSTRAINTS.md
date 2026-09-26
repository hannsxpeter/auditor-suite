# CONSTRAINTS: Constraints and Data Validation

Weight 10. Always active.
Owns: invariants the database enforces, the mechanism rather than the modeling choice: UNIQUE (including idempotency keys), NOT NULL, database defaults, CHECK, exclusion constraints, generated columns for values derived from the same row, and constraints that exist but are not enforced.
Not here: foreign keys (INTEGRITY); a free-text state column's design (SCHEMA-R5); lost updates and write skew on rules no constraint can express (TXN-R1, TXN-R5); a handler with no idempotency key at all (TXN-R3); how to add a constraint without locking (MIGRATION-R2).
Standards: PostgreSQL and MySQL constraint docs, SQL Antipatterns (Karwin).
Read first: the final DDL of each table (the last migration that touches it, or the schema dump), then the model validations and the insert paths for identity, payment, and idempotency keys.

## Cards

### CONSTRAINTS-R1 Uniqueness of an identity, payment, or idempotency key enforced only in application code (quick)
- Leads: `scan.sh CONSTRAINTS-R1` lists ORM uniqueness validations, check-then-insert lookups, and idempotency keys.
- Confirm: a key that must be unique (login email or username, `sku`, `external_id`, `(tenant_id, slug)`, a payment intent ID, an idempotency key, a webhook event ID, a dedup token) is protected only by an app `SELECT` before `INSERT`, an ORM validation, or nothing, and no unique constraint or unique index exists in the shipped DDL; two concurrent requests both pass the check. Rails `validates ... uniqueness` and Laravel `Rule::unique` never create a constraint. Django `unique=True`, Prisma `@unique`, SQLAlchemy `unique=True`, TypeORM `@Unique`, and JPA `@Column(unique = true)` create one only through a generated migration or schema tool, so check the migration.
- Not a finding if: the migration or schema dump has the unique index (a unique expression index such as `lower(email)` counts).
- Severity: Critical for sign-in identity, payment, and idempotency keys (duplicate accounts, double charges, double processing); High for other business keys; Medium for cosmetic ones.
- Fix: deduplicate, then add the constraint lock-safely (PostgreSQL: `CREATE UNIQUE INDEX CONCURRENTLY customers_email_key ON customers (email)`, then `ALTER TABLE customers ADD CONSTRAINT customers_email_key UNIQUE USING INDEX customers_email_key`), and turn the violation (SQLSTATE 23505, MySQL 1062) into a conflict response instead of trusting the pre-check.
- Verify the fix: a test fires two concurrent inserts with the same key; one fails with a unique violation and one row exists.
- Refs: PostgreSQL docs, Unique Constraints; Rails guides, Active Record Validations (uniqueness)

### CONSTRAINTS-R2 Soft-delete table with a plain UNIQUE
- Leads: `scan.sh CONSTRAINTS-R2` lists soft-delete columns; read the unique constraints of each table that has one.
- Confirm: a table with `deleted_at` or `is_deleted` has a plain UNIQUE on a natural key (`email`, `sku`, `slug`), so once a row is soft-deleted a live row with the same key cannot be created; or the unique includes `deleted_at` (`UNIQUE (email, deleted_at)`), which lets unlimited live duplicates through because every live row has `deleted_at` NULL and NULLs are distinct.
- Not a finding if: the unique index is partial on live rows; the product never re-creates a deleted key (documented).
- Severity: High when the key is an identity (a user cannot sign up again, or two live accounts share an email); Medium otherwise.
- Fix: PostgreSQL and SQLite: `CREATE UNIQUE INDEX CONCURRENTLY products_sku_live_key ON products (sku) WHERE deleted_at IS NULL`, then drop the old constraint. MySQL: a generated column that is 1 for live rows and NULL for deleted ones, unique together with the key. Upserts must then name the predicate: `ON CONFLICT (sku) WHERE deleted_at IS NULL`.
- Verify the fix: a test soft-deletes a row and re-creates its key, and a second live duplicate fails.
- Refs: PostgreSQL docs, Partial Indexes; MySQL docs, Generated Columns

### CONSTRAINTS-R3 Unique constraint that does not hold: a nullable key or a missing tenant column
- Leads: `scan.sh CONSTRAINTS-R3` lists unique constraints and unique indexes.
- Confirm: a UNIQUE covers a nullable column that the code treats as always present, so many NULL rows pass (NULLs are distinct in PostgreSQL, MySQL, SQLite, and Oracle; SQL Server allows one NULL); or in a multi-tenant schema the unique omits the tenant (`UNIQUE (email)` instead of `UNIQUE (tenant_id, email)`), wrongly rejecting a value that exists in another tenant and revealing that it exists there.
- Not a finding if: several unset rows are intended; the column is NOT NULL; `NULLS NOT DISTINCT` (PostgreSQL 15 or later) is used where one NULL is wanted.
- Severity: High when the key is an identity or payment key; Medium otherwise.
- Fix: add `NOT NULL` (lock-safe form in MIGRATION-R2), use `NULLS NOT DISTINCT` or a partial index, or rebuild the unique with the tenant column first.
- Verify the fix: a test inserting two rows with a NULL key, or the same value in two tenants, gets the intended outcome.
- Refs: PostgreSQL docs, Unique Constraints; SQL Server docs, Filtered Indexes

### CONSTRAINTS-R4 Required column left nullable, or its default set only in application code
- Leads: `scan.sh CONSTRAINTS-R4` lists nullable column options, app-side defaults, and create hooks.
- Confirm: the code always writes a column (required in the model or DTO) but the DDL allows NULL, so a second writer, a bulk import, or raw SQL can store NULL; or a default (`status = 'pending'`, `created_at = now()`) exists only in the model, a hook, or the app, with no database `DEFAULT`.
- Not a finding if: the DDL has the `NOT NULL` and the `DEFAULT` (read the migration, not the model); NULL is a real state of the column.
- Severity: High for money, identity, and state columns (a NULL `amount` or `status`); Medium otherwise.
- Fix: add the database `DEFAULT`, backfill NULLs in batches, then `NOT NULL` through the lock-safe path in MIGRATION-R2.
- Verify the fix: a raw SQL insert without the column gets the default, and an explicit NULL fails.
- Refs: PostgreSQL docs, Not-Null Constraints and Default Values

### CONSTRAINTS-R5 Row rules left to application code: no CHECK for ranges, cross-column rules, or same-row derived values
- Leads: `scan.sh CONSTRAINTS-R5` lists existing CHECK constraints and columns that carry rules (quantities, balances, discounts, start and end pairs, cancel pairs).
- Confirm: the code relies on a rule a CHECK could enforce and the DDL has none: non-negative quantity, stock, or balance; ordered ranges (`starts_at < ends_at`); `discount <= total`; formats (slug, currency code); dependent columns (`CHECK ((canceled_at IS NULL) = (cancel_reason IS NULL))`); or a value derived from the same row (`total = subtotal + tax`) stored by the app instead of `GENERATED ALWAYS AS (...) STORED`. Also a CHECK that exists but is not enforced: PostgreSQL `NOT VALID` never validated or `NOT ENFORCED` (PostgreSQL 18), SQL Server `WITH NOCHECK`, MySQL older than 8.0.16 (parsed and ignored).
- Not a finding if: the CHECK exists, is validated, and matches the rule.
- Severity: High when the rule protects money or inventory (negative balances, discounts above the total); Medium otherwise.
- Fix: `ADD CONSTRAINT ... CHECK (...) NOT VALID`, repair existing rows, then `VALIDATE CONSTRAINT`; a stored generated column for same-row derivations.
- Verify the fix: an insert that breaks the rule fails with a check violation (SQLSTATE 23514).
- Refs: PostgreSQL docs, Check Constraints and Generated Columns; MySQL docs, CHECK Constraints

### CONSTRAINTS-R6 Non-overlap rule enforced by a read before the insert
- Leads: `scan.sh CONSTRAINTS-R6` lists exclusion constraints, range types, and start and end columns.
- Confirm: bookings, reservations, shifts, price validity periods, or other rows that must not overlap are protected only by a `SELECT` for a clash followed by an `INSERT`; concurrent requests both see no clash, and no `EXCLUDE USING gist` constraint (or PostgreSQL 18 `WITHOUT OVERLAPS` key) exists.
- Not a finding if: an exclusion constraint exists; the insert runs under SERIALIZABLE with a retry, or first locks a parent row that every writer locks (`SELECT ... FROM rooms WHERE id = $1 FOR UPDATE`; read it).
- Severity: High when double bookings or overlapping periods reach customers; Medium on internal tools.
- Fix: `CREATE EXTENSION btree_gist;` then `ALTER TABLE bookings ADD CONSTRAINT bookings_no_overlap EXCLUDE USING gist (room_id WITH =, daterange(check_in, check_out) WITH &&);` and turn SQLSTATE 23P01 into a conflict response.
- Verify the fix: two concurrent bookings of the same room and dates: one fails with an exclusion violation.
- Refs: PostgreSQL docs, Exclusion Constraints and btree_gist

## Also check
- ORM or DTO validation treated as the integrity boundary while bulk imports, admin tools, or a second service write the same tables.

## Paper controls (look protective, protect nothing)
- A `UNIQUE` on a nullable column: unlimited NULL rows pass unless `NOT NULL`, `NULLS NOT DISTINCT`, or a partial index (CONSTRAINTS-R3).
- A CHECK added `NOT VALID` and never validated, or `NOT ENFORCED`; a foreign key in the same state is INTEGRITY-R3.
- A SQL Server constraint added `WITH NOCHECK`: untrusted, and the optimizer ignores it.
- A MySQL `CHECK` on a server older than 8.0.16: parsed and silently ignored.
- An `ON CONFLICT (col)` upsert whose only unique index is partial: it must repeat the index predicate or it fails at runtime.
- `UNIQUE (email, deleted_at)` meant to scope uniqueness to live rows: live duplicates pass (CONSTRAINTS-R2).
