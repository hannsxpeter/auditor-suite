# PERF: Performance and Efficiency

Weight 8. Always active.
Owns: work the code does that it does not need to: quadratic algorithms on hot paths, queries or remote calls inside loops, unbounded loads, in-memory state that grows without bound, caches that never invalidate, blocking work on event loops, and chatty or oversized network use.
Not here: missing timeouts (ERR-R3); schema, index design, and query plans in depth (dbauditor); frontend bundle and rendering performance (uiauditor).
Standards: CWE-407, CWE-1050, CWE-1060, CWE-770.
Read first: the hot paths on your Map (the most frequent requests and jobs), the data-access code they call, and any cache setup.
Evidence rule for this dimension: you cannot profile, so every card below says when a finding may be Confirmed. Otherwise record it as Likely, stating the data-size assumption, or as Suspected, and name in Verify the fix the measurement that would confirm it (a query count, a timing, a memory graph).

## Cards

### PERF-R1 Quadratic or worse work on a hot path
- Leads: `scan.sh PERF-R1` lists lookups inside loops and comprehensions (`.find`, `.includes`, `.indexOf`, `in` on a list).
- Confirm: on a request path or frequent job, code loops over one collection and scans another inside the loop (nested loops, `list.includes` or `x in some_list` inside a loop, repeated sorting), so the work grows with the product of their sizes, and at least one collection grows with users or data.
- Not a finding if: both collections are small and bounded in code (a fixed list of plans, a page size); the inner lookup is a dict, set, or Map.
- Severity: High when both collections grow with stored data on a request path; Medium otherwise. Confidence: Confirmed only when the code shows both come from unbounded queries; otherwise Likely, or Suspected when the sizes depend on data you cannot see.
- Fix: index the inner collection once (a set, or a map keyed by ID) before the loop.
- Verify the fix: a timing test with 10,000 and 20,000 items shows the time about doubling, not quadrupling.
- Refs: CWE-407

### PERF-R2 Query or remote call inside a loop (N+1)
- Leads: `scan.sh PERF-R2` lists lookups keyed by another record's ID and `map(async ...)` calls. Read the loop around each lead.
- Confirm: a loop over records makes one database statement or remote call per item (`Model.query.get(item.owner_id)` in a loop, a lazy-loaded relation touched per row, an INSERT per row outside a transaction, `await fetch(...)` per item), so one request makes N+1 round trips.
- Not a finding if: the loop runs over a small fixed set; the relation is eager-loaded (`joinedload`, `selectinload`, `include`, `prefetch_related`); the loop pages through results in fixed-size batches (one query per page, not per row).
- Severity: High when N grows with users or data on a request path; Medium on admin reports and batch jobs. Confidence: Confirmed when the loop runs over an unbounded query result; otherwise Likely, or Suspected when the cost depends on input sizes or settings you cannot see.
- Fix: load the related rows in one query (a join, `IN (...)`, or eager loading), batch the remote calls, or run per-row writes inside one transaction, then look rows up in a map inside the loop.
- Verify the fix: a test that counts queries (Django `assertNumQueries`, a SQLAlchemy event listener, a query log) sees the same count for 1 and 100 records.
- Refs: CWE-1050, CWE-1060

### PERF-R3 Unbounded load: whole tables, files, or responses pulled into memory
- Leads: `scan.sh PERF-R3` lists `.all()`, `findAll()`, `SELECT *` with no `LIMIT`, `fetchall()`, and whole-file reads.
- Confirm: a request path or job loads every row of a table that grows (no `LIMIT`, pagination, or streaming), reads a file or response body of unbounded size into memory, returns an unpaginated list to clients, or sums or counts rows in code instead of in the database.
- Not a finding if: the table is small by nature (settings, plans, countries); the query is filtered to one user's bounded rows; the caller streams or paginates.
- Severity: High when a public or frequent endpoint loads a table that grows with users; Medium otherwise. Confidence: Likely when the code shows no bound; Suspected when you cannot tell whether the table grows.
- Fix: paginate with a limit and a cursor, stream large files and responses, and aggregate in the database (`SUM`, `COUNT`).
- Verify the fix: the endpoint returns at most one page, and memory stays flat when the table grows tenfold.
- Refs: CWE-770, CWE-1049

### PERF-R4 In-memory state that grows without bound, or a cache that never invalidates
- Leads: `scan.sh PERF-R4` lists module-level caches, memo tables, and unbounded `lru_cache`.
- Confirm: a module-level dict, list, Map, or cache gains entries per request or per user and nothing evicts them (memory grows until the process dies); a cache keeps serving data after the source changed because no write path clears it (stale prices, permissions, or balances); or event listeners and intervals are added per request and never removed.
- Not a finding if: the keys come from a small fixed set; the cache has a size bound or TTL and every write path that changes the data clears the entry.
- Severity: High when growth is per request in a long-running server, or when stale data affects money or permissions; Medium otherwise. Confidence: Confirmed for a missing invalidation you can trace to a write path; Likely for growth, or Suspected when you cannot see how long the process lives.
- Fix: bound the cache (an LRU with a maximum size, a TTL), clear it on every write path, or move shared caches to a store with expiry such as Redis.
- Verify the fix: memory stays flat over a load test, and a test that updates the source and then reads through the cache sees the new value.
- Refs: CWE-401, CWE-770

### PERF-R5 Blocking work on an event loop or request thread
- Leads: `scan.sh PERF-R5` lists synchronous file, process, and crypto calls and sleeps.
- Confirm: in a Node.js server or a Python async handler, the request path makes a blocking call (`readFileSync`, `execSync`, `bcrypt.hashSync`, `pbkdf2Sync`, `requests` or `time.sleep` inside `async def`) or runs long CPU work, stalling every other request on that process.
- Not a finding if: the call runs once at startup; the handler is synchronous in a threaded server (Flask, Django) where blocking I/O is the model; the work is offloaded (`run_in_executor`, a worker thread, a job queue).
- Severity: High on a hot path of an event-loop server; Medium elsewhere. Confidence: Confirmed when the call sits inside an async request handler; otherwise Likely, or Suspected when you cannot tell which path calls it.
- Fix: use the async API (`fs.promises`, `bcrypt.hash`, `httpx.AsyncClient`, `asyncio.sleep`) or move CPU work to a worker.
- Verify the fix: under concurrent load, a cheap endpoint's latency stays flat while the heavy one runs.
- Refs: none

## Also check
- Caching absent where the same expensive computation or remote call repeats per request with the same inputs.
- Over-fetching and chatty calls: `SELECT *` or whole objects when a few fields are used, responses carrying whole records, or a screen that needs many round trips.
- Query shapes that imply a missing index (filtering or sorting on a column with no index in the schema or migrations); name dbauditor for depth.

## Paper controls (look protective, protect nothing)
- A cache layer that the hot path bypasses, or whose key includes a timestamp or random value so it never hits.
- Pagination parameters read from the request and never passed to the query.
- A connection pool configured while each request builds a new client.
