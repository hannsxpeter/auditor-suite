# QUERY: Query Performance and Access Patterns

Weight 12. Always active.
Owns: the shape and lifecycle of queries, including the ORM layer: N+1 loops, unbounded results, pagination, sargability and implicit casts, over-fetching, logically wrong results, statement timeouts, and connection and session handling per request.
Not here: injection (DBSEC-R1); a missing or unusable index (INDEX); substring or full-text search behind a search feature (SEARCH-R1, SEARCH-R2); growth over time and retention (SCALE-R2); pool capacity against `max_connections` and pooler modes (SCALE-R5).
Standards: Use The Index, Luke and SQL Performance Explained (Winand), SQL Antipatterns (Karwin), ORM docs on eager loading.
Read first: the repositories, DAOs, or query-builder calls behind each hot path in the Map, the serializers that consume them, and the database client and pool setup.

## Cards

### QUERY-R1 N+1 queries: one query per row of a list
- Leads: `scan.sh QUERY-R1` lists loops that await per item; read each loop body for a database call.
- Confirm: code iterates a collection and runs a query per element: a lazy association read (`order.customer`) inside a loop or serializer, an `await db...` inside `for`, `map(async ...)`, or `each do`, with no eager-load primitive (`select_related`/`prefetch_related`, `.includes`/`preload`, `JOIN FETCH`/`@EntityGraph`, `joinedload`/`selectinload`, Prisma `include`, DataLoader). A correlated subquery run per outer row is the same defect in SQL.
- Not a finding if: the loop has a small fixed bound (a page of 10) or each lookup hits a cache first.
- Severity: High on a list endpoint or frequent job with pages of 50 or more; Medium otherwise.
- Fix: one query with the ORM's eager load, or a batched `WHERE id = ANY($1)` mapped in memory.
- Verify the fix: a test with a query counter (Django `assertNumQueries`, Rails `ActiveSupport::Notifications`, a Knex `query` event) shows a constant query count as the list grows.
- Refs: Rails guides, Eager Loading Associations; Django docs, select_related and prefetch_related

### QUERY-R2 List query with no limit on a growing table
- Leads: `scan.sh QUERY-R2` lists fetch-all calls and SQL selects with no WHERE or LIMIT.
- Confirm: a request path or job loads every row of a table that grows with use (`findAll()`, `findMany()` with no `take`, `objects.all()` serialized whole, `SELECT ... FROM orders` with no LIMIT), so memory and latency grow with the table and a large table can exhaust the process.
- Not a finding if: the table is small by nature (countries, plans, one hotel's rooms); the rows stream through a cursor in batches; a hard cap applies before loading (read it).
- Severity: High when a public or hot path can load an unbounded table into memory; Medium otherwise.
- Fix: a hard LIMIT with mandatory pagination (keyset: QUERY-R3), or a server-side cursor for exports.
- Verify the fix: the endpoint returns at most the cap in a test seeded with more rows than the cap.
- Refs: Use The Index, Luke, "Partial Results"

### QUERY-R3 OFFSET pagination over a large or growing table
- Leads: `scan.sh QUERY-R3` lists OFFSET, skip, and page-number pagination.
- Confirm: a list, sync, or export pages with `OFFSET n` (`.offset()`, `skip:`, `Pageable`, page times size) over a large or growing table, so each deeper page reads and discards every earlier row; a client that walks all pages pays a cost that grows with the square of the table.
- Not a finding if: the filtered set is small and bounded (one user's saved addresses); page depth is capped (a maximum of 10 pages).
- Severity: High when a sync, export, crawler, or public listing walks deep pages of a large table; Medium otherwise.
- Fix: keyset pagination on a unique indexed sort key: `WHERE (created_at, id) < ($1, $2) ORDER BY created_at DESC, id DESC LIMIT 100`, backed by an index on `(created_at DESC, id DESC)`. The `id` tiebreaker keeps rows with equal timestamps from being skipped or repeated.
- Verify the fix: EXPLAIN of a deep page reads about one page of index entries, and latency is flat from page 1 to page 10,000.
- Refs: Use The Index, Luke, "Paging Through Results"

### QUERY-R4 Predicate the index cannot use: wrapped column, implicit cast, or leading wildcard
- Leads: `scan.sh QUERY-R4` lists function-wrapped columns in filters and leading-wildcard LIKE.
- Confirm: a filter wraps the column in an expression that can be rewritten away (`DATE(created_at) = ?`, `EXTRACT(year FROM ...)`, `col + 0 = ?`, `COALESCE(col, 0) = ?`); compares the column with a value of another type or collation (a string against an integer or uuid column), so the engine casts the column side; or uses a leading-wildcard `LIKE '%x%'` that backs no search feature (a search feature is SEARCH-R1).
- Not a finding if: an index on the exact expression exists; the table is small; the expression is inherent to the lookup (then add the expression index: INDEX-R5).
- Severity: High on a hot path over a large table; Medium otherwise.
- Fix: rewrite to a sargable range (`created_at >= $1 AND created_at < $1 + interval '1 day'`), bind parameters with the column's type, or add the matching expression index.
- Verify the fix: EXPLAIN shows an index scan instead of a sequential scan with a filter.
- Refs: Use The Index, Luke, "Functions" and "Obfuscated Conditions"

### QUERY-R5 Query fetches far more columns than the caller uses
- Leads: `scan.sh QUERY-R5` lists `SELECT *` and select-all calls.
- Confirm: `SELECT *` or an unprojected ORM fetch loads every column, including large TEXT, BLOB, or JSON columns, on a list path or a large result, while the caller or serializer uses a few.
- Not a finding if: the table is narrow; the caller uses most columns; it is a single-row fetch off the hot path.
- Severity: Medium when large columns ride along on list paths; Low otherwise.
- Fix: project the needed columns (`.select('id', 'name')`, `.only()`, `.pluck()`, Prisma `select`), which also allows index-only scans.
- Verify the fix: the query lists explicit columns and the response or rows transferred shrink.
- Refs: SQL Antipatterns "Implicit Columns"; Use The Index, Luke, "Index-Only Scan"

### QUERY-R6 Query returns wrong rows: NOT IN over a nullable subquery, or an accidental cross join
- Leads: `scan.sh QUERY-R6` lists NOT IN subqueries, comma joins, and CROSS JOIN.
- Confirm: `NOT IN (SELECT col ...)` where `col` can be NULL (a single NULL makes the predicate unknown, so zero rows return, and it blocks an anti-join plan); or a comma join or an `ON` clause missing a key column multiplies rows, so totals double and duplicates appear.
- Not a finding if: the subquery column is NOT NULL or filtered with `IS NOT NULL`; the cross join is deliberate against a small table (a calendar).
- Severity: High when the result drives money, access, or a user-visible total; Medium otherwise.
- Fix: `NOT EXISTS (SELECT 1 ...)` or `LEFT JOIN ... WHERE right.id IS NULL`; an explicit `JOIN ... ON` with every key column.
- Verify the fix: a test with a NULL in the subquery column (or two matching child rows) returns the expected rows and totals.
- Refs: SQL Antipatterns "Fear of the Unknown" and "Spaghetti Query"

### QUERY-R7 Queries and connections without limits: no statement timeout, a connection per request, or leaked sessions
- Leads: `scan.sh QUERY-R7` lists connection creation, pool settings, and timeout settings.
- Confirm: no statement timeout exists at the role, connection, or query level (`statement_timeout`, `max_execution_time`, `queryTimeout`, `maxTimeMS`), so a runaway query holds a connection and its locks until it finishes; or code opens a new connection per request or per query with no pool; or a connection, ORM session, or transaction is not released on an exception path (no `finally`, no context manager) or is held across requests.
- Not a finding if: a timeout is set at the role default or in the connection string (cite it; when the connection string lives outside the repository, say so in Scope and limitations instead of filing); for the per-request and leak parts, the framework manages the pool and session lifecycle (Django, Rails, Prisma).
- Severity: High when a public path can trigger an expensive query or a busy service opens a connection per request; Medium otherwise.
- Fix: `ALTER ROLE app SET statement_timeout = '5s'` (longer for a separate reporting role), one pool per process, release in `finally` or a context manager.
- Verify the fix: in a test environment `SELECT pg_sleep(10)` through the app role is cancelled at the timeout, and connection counts stay flat under load.
- Refs: PostgreSQL docs, Client Connection Defaults; MySQL docs, max_execution_time

## Also check
- `OR` across different columns that no single index satisfies: split with `UNION` or give each column its own index for a bitmap OR.
- `COUNT(*)` over a large table on every paginated request: use an estimate (`reltuples`), a maintained counter, or fetch `LIMIT k + 1` to know whether another page exists.
- A `LIMIT` applied after a `DISTINCT`, `GROUP BY`, or `ORDER BY` that must first materialize the whole set.

## Paper controls (look protective, protect nothing)
- An `EXPLAIN` captured on a small development dataset cited as proof: production row counts flip the plan.
- A `statement_timeout` set per session or in app config but lost through a transaction-mode pooler, or never set at the role default (QUERY-R7).
- "Prepared statements" that are re-planned on every call behind a pooler.
- An eager load declared on the base query but dropped by a later `.where` or `.order` on the association (QUERY-R1).
- A keyset pagination index on `(created_at)` without the `id` tiebreaker (QUERY-R3).
