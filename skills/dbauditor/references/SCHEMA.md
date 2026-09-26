# SCHEMA: Schema Design and Data Modeling

Weight 11. Always active.
Owns: whether the model itself is right, the design choice rather than the enforcement: packed lists, missing primary keys, polymorphic pairs, entity-attribute-value tables, how state is modeled, copies of other rows' data, logic hidden in triggers and procedures, soft delete as a design choice, repeating groups, god tables, and naming.
Not here: a missing unique constraint on a natural key (CONSTRAINTS-R1); NOT NULL, CHECK, and generated columns (CONSTRAINTS); physical column types (TYPES); foreign keys (INTEGRITY); `SECURITY DEFINER` functions (DBSEC, Also check).
Standards: SQL Antipatterns (Karwin), Designing Data-Intensive Applications (Kleppmann), PostgreSQL docs.
Read first: the full table list with columns (schema dump or migrations), the entity map you wrote, and any trigger, function, or procedure definitions. In a warehouse or document store, read references/nonrelational.md first: denormalization is correct there.

## Cards

### SCHEMA-R1 Several values packed into one column (Jaywalking)
- Leads: `scan.sh SCHEMA-R1` lists FIND_IN_SET, list-shaped LIKE patterns, `*_ids` columns, and array columns of keys.
- Confirm: a `VARCHAR`, `TEXT`, JSON, or array column holds a list of references or values that code splits, searches with `LIKE '%,5,%'` or `FIND_IN_SET`, or updates by rewriting the whole list (`tag_ids = '3,7,9'`).
- Not a finding if: the list is opaque to queries (stored and returned whole, never filtered or joined); the store is a document or warehouse database where embedding is the design (nonrelational.md).
- Severity: High when the list holds references used on a hot path (no foreign key or index can apply); Medium otherwise.
- Fix: a junction table with a composite key and a foreign key on each side (the INTEGRITY-R6 shape), backfilled from the list in batches.
- Verify the fix: no query uses FIND_IN_SET or list-shaped LIKE, and the junction table has no duplicate or orphan pairs.
- Refs: SQL Antipatterns "Jaywalking"

### SCHEMA-R2 Table with no primary key
- Leads: `scan.sh SCHEMA-R2` lists table definitions and options that skip the key (`id: false`); check each table for a primary key.
- Confirm: a base table has no `PRIMARY KEY` and no unique NOT NULL key serving as one, so duplicate rows are possible and logical replication, CDC, and ORMs cannot identify a row (PostgreSQL logical replication cannot replicate UPDATE or DELETE on it without a replica identity).
- Not a finding if: it is a staging or log table loaded and truncated in bulk and never updated; a unique NOT NULL key serves as the replica identity.
- Severity: High when the table is replicated, streamed through CDC, or updated by more than one path; Medium otherwise.
- Fix: deduplicate, then add a primary key (a `bigint` identity or the natural composite key); build the unique index concurrently and attach it with `ADD CONSTRAINT ... PRIMARY KEY USING INDEX`.
- Verify the fix: the catalog shows a primary key and a duplicate insert fails.
- Refs: PostgreSQL docs, Logical Replication (replica identity)

### SCHEMA-R3 Polymorphic association that no foreign key can enforce
- Leads: `scan.sh SCHEMA-R3` lists polymorphic declarations and `*able_type` and `*able_id` pairs.
- Confirm: a pair such as `commentable_type` plus `commentable_id` (Rails `polymorphic: true`, Laravel `morphs`, Django `GenericForeignKey`) points at rows in several tables, so no foreign key can exist and deleting a parent leaves dangling references.
- Not a finding if: the parents are never deleted and an orphan check exists; the relation is low value and one framework path is the only writer (then Low).
- Severity: High when the association carries money, permissions, or ownership; Medium otherwise.
- Fix: one nullable foreign key column per parent type plus an exclusive-arc CHECK (`CHECK (num_nonnulls(post_id, photo_id) = 1)`), or one junction table per parent type.
- Verify the fix: each parent column has a foreign key, and a row with two parents fails the CHECK.
- Refs: SQL Antipatterns "Polymorphic Associations"

### SCHEMA-R4 Entity-attribute-value or catch-all properties table
- Leads: `scan.sh SCHEMA-R4` lists attribute-name and attribute-value columns.
- Confirm: rows shaped like `(entity_id, attribute_name, value)`, or a catch-all `meta` or `properties` table of string values, hold core attributes the app filters, validates, or reports on, so types, NOT NULL, and foreign keys cannot apply and every read needs a pivot.
- Not a finding if: the attributes are genuinely user-defined (custom fields) and kept in a constrained `jsonb` column or a documented typed design; the store is a document database.
- Severity: Medium; High when money or access decisions read from it.
- Fix: typed columns for the known attributes; a `jsonb` column with a CHECK or JSON schema for the open ones.
- Verify the fix: core attributes have typed, constrained columns and no report pivots the attribute table.
- Refs: SQL Antipatterns "Entity-Attribute-Value"

### SCHEMA-R5 State stored as free text, or as several flags that can contradict each other
- Leads: `scan.sh SCHEMA-R5` lists status, state, and type columns declared as text, and `is_*` flag families.
- Confirm: a `status`, `state`, or `type` column is free text with no CHECK, enum, or lookup foreign key in the DDL (it accepts `'Active'`, `'active'`, and `'ACTIVE'`); or one state is spread over mutually exclusive booleans (`is_draft`, `is_published`, `is_archived`) that can all be true at once.
- Not a finding if: a CHECK, enum type, or lookup table constrains the values in the DDL (a model-level enum does not count); the flags are independent facts, not one state.
- Severity: High when the state drives money, access, or fulfillment; Medium otherwise.
- Fix: one `state` column with a CHECK over the allowed values, or a lookup table with a foreign key for sets that change. In PostgreSQL prefer a lookup table or CHECK over a native ENUM for evolving sets: enum values cannot be removed, and reordering needs a type rebuild.
- Verify the fix: inserting an unknown state fails, and no row has two exclusive flags set.
- Refs: SQL Antipatterns "31 Flavors"; PostgreSQL docs, Enumerated Types

### SCHEMA-R6 Copy of another row's data with nothing keeping it current
- Leads: `scan.sh SCHEMA-R6` lists copied name and email columns, `*_count` columns, and cached values.
- Confirm: a column copies data from another row or table (`orders.customer_name`, `posts.comment_count`, `accounts.balance` kept beside a ledger) and nothing keeps it current: no trigger, no update in the same transaction as the source change, no reconciliation job.
- Not a finding if: the copy is a deliberate snapshot that must not change (the price or shipping address at order time); a trigger or same-transaction update maintains it (read it); the store is a warehouse or document database. A value derived from the same row is CONSTRAINTS-R5 (a generated column).
- Severity: High when drift reaches money or access (a cached balance that is spent from); Medium otherwise.
- Fix: drop the copy and join, or maintain it in the same transaction as the source (or by trigger) and monitor a reconciliation query.
- Verify the fix: a query comparing the copy with its source returns 0 mismatches.
- Refs: Designing Data-Intensive Applications (Kleppmann), Part III (derived data)

### SCHEMA-R7 Business logic hidden in triggers or stored procedures
- Leads: `scan.sh SCHEMA-R7` lists CREATE TRIGGER, FUNCTION, and PROCEDURE statements and row-level trigger clauses.
- Confirm: triggers or procedures carry business rules the application code does not show (pricing, state changes, writes to other tables), fire each other in chains or recursively, run per row on bulk DML over large tables, or have no owner, tests, or versioned source outside a one-off migration.
- Not a finding if: the logic is small, documented, tested, and deliberate (an `updated_at` or audit trigger).
- Severity: High when a hidden trigger changes money or runs per row on a bulk path of a large table; Medium otherwise.
- Fix: list every trigger in the Map, move business rules into the app or into versioned and tested functions, and use statement-level triggers for bulk paths.
- Verify the fix: every trigger and function has an owner and a test that exercises it.
- Refs: PostgreSQL docs, Triggers

## Also check
- Repeating-group columns (`phone1`, `phone2`, `phone3`; `addr_line_1` to `addr_line_4`): a child table with a position column.
- A god table with dozens of mostly NULL columns spanning unrelated subjects: split it vertically.
- Soft delete as a design choice: a `deleted_at` column with no default scope, view, or policy that hides deleted rows, so every query must remember the filter; or soft delete where an archive table or a hard delete plus an audit log fits. The dangling-children part is INTEGRITY-R7 and the unique-index part is CONSTRAINTS-R2.
- A surrogate primary key while the natural business key (`email`, `sku`, `(tenant_id, slug)`) has no unique constraint: file the enforcement under CONSTRAINTS-R1.
- Inconsistent naming across the schema (plural and singular tables, `uid`, `user_id`, and `userId` side by side): Low.

## Paper controls (look protective, protect nothing)
- An ORM uniqueness rule or association treated as a database guarantee (CONSTRAINTS-R1, INTEGRITY-R1).
- A virtual generated column relied on as if stored or indexable (PostgreSQL 18 virtual columns cannot be indexed; facts.md).
- A `DEFAULT` mistaken for `NOT NULL`: a default does not stop an explicit NULL.
