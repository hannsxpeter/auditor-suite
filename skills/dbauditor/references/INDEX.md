# INDEX: Indexing Strategy

Weight 13. Always active.
Owns: whether each hot query has an index it can actually use: foreign key columns, selective filters, composite column order and sort direction, index type and operator class, expression indexes, and redundant or low-value indexes.
Not here: the foreign key constraint itself (INTEGRITY-R1); a predicate that should be rewritten instead of indexed (QUERY-R4); substring and full-text search (SEARCH, or QUERY-R4 when no search feature exists); how to build an index without blocking writes (MIGRATION-R1).
Standards: Use The Index, Luke and SQL Performance Explained (Winand), PostgreSQL and MySQL index docs.
Read first: every index and unique declaration in the migrations or schema dump, then the dominant queries you listed in the Map.

## Cards

### INDEX-R1 Foreign key column with no index in an engine that does not add one
- Leads: `scan.sh INDEX-R1` lists foreign key and index declarations; match each foreign key column to an index whose first column is that column.
- Confirm: the engine is PostgreSQL, SQL Server, Oracle, or SQLite (none index the referencing column automatically; MySQL InnoDB does), no index starts with the child column, and the parent is deleted or its key updated in code, or the child is joined or filtered by that column on a hot path.
- Not a finding if: a composite index starts with the column (a second position does not count); the child table is small and not joined on a hot path; the parent is never deleted and no query filters children by it. Rails `t.references` and `add_reference` add the index by default; `add_foreign_key` does not.
- Severity: High when the child is large or joined on a hot path, or parents are deleted routinely (each delete scans and locks the child); Medium otherwise; Low for small tables.
- Fix: `CREATE INDEX CONCURRENTLY order_items_order_id_idx ON order_items (order_id);` in a migration that runs outside a transaction (MIGRATION-R1 shows the form per tool).
- Verify the fix: EXPLAIN of the child lookup by parent shows an index scan on the new index, and a parent delete no longer scans the child.
- Refs: PostgreSQL docs, Foreign Keys; Use The Index, Luke

### INDEX-R2 Hot filter, join, or sort column with no usable index
- Leads: `scan.sh INDEX-R2` lists queries that filter or sort on selective columns (email, slug, token, tenant, user, external ID, created_at).
- Confirm: a query on a request path or a frequent job filters, joins, or sorts on a selective column of a large or growing table (`user_id`, `email`, `slug`, `tenant_id`, `order_id`, `external_id`, a time range), and no index starts with that column, or with the query's equality columns followed by it.
- Not a finding if: a primary key or unique constraint already indexes it; the table is small by nature (lookup and configuration tables); the query is a rare admin report.
- Severity: High on a hot path over a large or growing table; Medium otherwise. Use Likely or Suspected when the code does not show the table size, and name what would confirm it (a row count, an EXPLAIN).
- Fix: an index shaped to the query: equality columns first, then the one range or sort column, for example `CREATE INDEX CONCURRENTLY orders_customer_created_idx ON orders (customer_id, created_at DESC)`.
- Verify the fix: EXPLAIN on production-size data uses the index.
- Refs: Use The Index, Luke; PostgreSQL docs, Indexes

### INDEX-R3 Composite index whose column order or direction the queries cannot use
- Leads: `scan.sh INDEX-R3` lists composite index declarations; compare each with the queries meant to use it.
- Confirm: the first column is one no query filters on (the leftmost-prefix rule makes the index dead for those queries), a range column precedes an equality column, or the query's `ORDER BY` direction, NULLS order, or pagination key does not match an index that also covers its filter, so the database sorts on every call.
- Not a finding if: another index serves the query; the engine can skip-scan this shape (facts.md) and the leading column has few distinct values.
- Severity: High when it is the index of a hot query; Medium otherwise.
- Fix: equality columns first, then one range or sort column, matching ASC or DESC and NULLS order (`(tenant_id, status, created_at DESC)`); build the new index concurrently, then drop the old one.
- Verify the fix: EXPLAIN shows an index scan with no separate Sort step.
- Refs: Use The Index, Luke, "The Where Clause" and "Sorting and Grouping"; PostgreSQL docs, Multicolumn Indexes

### INDEX-R4 Index type or operator class does not match the query's operator
- Leads: `scan.sh INDEX-R4` lists jsonb, array, range, and full-text columns and operators, and each index method.
- Confirm: a B-tree index (or none) backs `jsonb` containment (`@>`), array membership (`&&`, `@>`), full-text (`@@`), trigram, range overlap, or nearest-neighbor queries, none of which a B-tree serves; or a huge append-only table ordered by time carries a large B-tree on that column where BRIN fits.
- Not a finding if: the matching GIN, GiST, or BRIN index exists; the path is rare or the table small.
- Severity: High on a hot path over a large table; Medium otherwise.
- Fix: GIN for jsonb (`jsonb_path_ops` when only `@>` is used), arrays, tsvector, and trigram (`gin_trgm_ops`); GiST for ranges, exclusion constraints, and nearest-neighbor; BRIN for large append-only time columns. Build concurrently.
- Verify the fix: EXPLAIN shows a bitmap index scan on the new index for the query's operator.
- Refs: PostgreSQL docs, Index Types and Operator Classes

### INDEX-R5 Expression or case-insensitive lookup with no index on the same expression
- Leads: `scan.sh INDEX-R5` lists LOWER and UPPER calls, ILIKE, iexact, citext, and insensitive query modes.
- Confirm: an equality lookup needs an expression (`WHERE lower(email) = lower($1)`, Django `__iexact`, Prisma `mode: 'insensitive'` on `equals`) and no index exists on the identical expression, collation included, and the column is not `citext`.
- Not a finding if: an expression index or `citext` column exists; the table is small. When the query can be rewritten to use the bare column (a date range instead of `date(created_at)`), file QUERY-R4 instead.
- Severity: High on a sign-in or lookup hot path; Medium otherwise.
- Fix: `CREATE INDEX CONCURRENTLY users_lower_email_idx ON users (lower(email));` (a unique index when the email is an identity: CONSTRAINTS-R1) and make the query use the same expression, or convert the column to `citext`. Prisma's insensitive mode sends `ILIKE`, which neither index serves: use `@db.Citext` and a plain `equals`.
- Verify the fix: EXPLAIN of the lookup shows an index scan on the expression index.
- Refs: PostgreSQL docs, Indexes on Expressions; Use The Index, Luke, "Functions"

### INDEX-R6 Redundant, duplicate, or low-value indexes
- Leads: `scan.sh INDEX-R6` lists every index and unique declaration; group them by table.
- Confirm: an index is a prefix of another (`(a)` beside `(a, b)`); two are identical (an ORM auto-index plus a migration index, or a UNIQUE plus a plain index on the same column); a single-column index sits on a low-cardinality column used alone (boolean, three-value status, soft-delete flag), which the planner ignores; or a write-heavy table carries many single-column indexes where two or three composites would serve the same queries.
- Not a finding if: the shorter index is unique and enforces a constraint; the low-cardinality index is partial (`WHERE status = 'pending'`) and serves a rare value; a query needs that exact column order.
- Severity: Medium on write-heavy or large tables (every index adds write cost and bloat); Low otherwise.
- Fix: drop the redundant index with `DROP INDEX CONCURRENTLY` after checking no query needs it; fold low-cardinality columns into a composite or partial index.
- Verify the fix: `pg_stat_user_indexes.idx_scan` shows the dropped index was unused; write latency or table size drops.
- Refs: SQL Antipatterns "Index Shotgun"; PostgreSQL docs, Examining Index Usage

## Also check
- A prefix search (`LIKE 'abc%'`) in PostgreSQL under a non-C collation needs a `text_pattern_ops` or `COLLATE "C"` index; a plain B-tree is not used.
- A covering index meant for index-only scans that lacks one selected column (add it with `INCLUDE`).
- Multi-tenant tables whose indexes do not lead with `tenant_id` while every query filters by it.

## Paper controls (look protective, protect nothing)
- An index whose first column the query never filters: counted as coverage, unusable (INDEX-R3).
- A covering or `INCLUDE` index missing the one selected column, so every row still needs a table fetch.
- A partial index whose `WHERE` does not match the query's predicate exactly.
- An index on `lower(col)` while the query uses `ILIKE` or a slightly different expression (INDEX-R5).
- A MySQL `INVISIBLE` index, or a PostgreSQL `INVALID` index left by a failed `CREATE INDEX CONCURRENTLY`: maintained on every write, never used for reads.
- Text indexes built under an older glibc or ICU collation before an OS upgrade: silently corrupt until `REINDEX` (facts.md).
