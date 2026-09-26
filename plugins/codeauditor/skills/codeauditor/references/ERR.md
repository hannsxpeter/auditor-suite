# ERR: Error Handling and Resilience

Weight 10. Always active.
Owns: what the code does when something fails: errors swallowed or ignored, errors that lose their cause, timeouts and retries on I/O, multi-step writes without rollback, resources leaked on error paths, and failures that vanish instead of reaching someone who can act.
Not here: stack traces or exception text sent to clients (SEC-R7); failures that propagate but are never logged or reported (OBS-R2, OBS-R3); slow code that does not fail (PERF).
Standards: CWE-755, CWE-390, CWE-252, CWE-1088, CWE-404, OWASP A10:2025 (Mishandling of Exceptional Conditions).
Read first: the error middleware or top-level handler, how the HTTP and database clients are built, the payment, messaging, and background-job code on your Map, and references/facts.md (client timeout defaults and async error behavior by framework).

## Cards

### ERR-R1 Error caught or ignored and the code carries on as if it succeeded (quick)
- Leads: `scan.sh ERR-R1` lists empty catch blocks, broad `except` clauses, promise catches that drop the error, ignored Go errors, and `forEach(async ...)`. Read the lines after each catch.
- Confirm: an error is caught and dropped (an empty catch, `pass`, or a log line and carry on) where carrying on is wrong: the code then reports success, marks a record paid or sent, or continues with missing data; or an error return or rejected promise is never checked (`_ = err`, a promise nobody awaits, `forEach(async ...)`, an Express 4 async handler with no try/catch, an `asyncio.create_task` whose result nobody keeps; see references/facts.md).
- Not a finding if: the handler logs with context and re-raises, returns an error status, or retries with a limit; the ignored error comes from a best-effort step (closing a file already read, a metrics call) and a comment says so.
- Severity: Critical when a swallowed failure loses or corrupts money or stored data and nothing else records it (no retry, no log, no other system of record); High when a failed write, payment, or message is reported as success but the failure is recorded elsewhere or retried later, or when an unhandled rejection can hang requests or stop the process on a main path; Medium on secondary paths.
- Fix: delete the empty catch or narrow it to the one expected error; on failure log the record ID and return an error or re-raise, so the caller and the user know; await every promise.
- Verify the fix: a test that makes the dependency raise expects an error result and unchanged stored state (the record is not marked paid or sent).
- Refs: CWE-390, CWE-252, CWE-1069, OWASP A10:2025

### ERR-R2 Errors rethrown or reported without their cause
- Leads: `scan.sh ERR-R2` lists wrapping that drops the cause and generic error messages.
- Confirm: a catch raises a new error without chaining the original (`raise X(...)` with no `from e`, `throw new Error(msg)` without `{ cause: err }`, Go `fmt.Errorf` with `%v` instead of `%w`), or logs only a generic message ("something went wrong") without the exception, so no log shows what failed.
- Not a finding if: the original is logged with its stack where it is wrapped; the generic text goes to the user while the details go to the log.
- Severity: High when it hides failures on money or data-write paths from the only log anyone reads; Medium otherwise.
- Fix: chain the cause (`raise PaymentError(...) from e`, `new Error(msg, { cause: err })`, `%w`) and log the original once, with context.
- Verify the fix: a test that forces the inner failure finds the original error in the raised error's cause and in the log line.
- Refs: CWE-755

### ERR-R3 Network call with no timeout
- Leads: `scan.sh ERR-R3` lists outbound HTTP calls and client constructors. Check each call and its client's default in references/facts.md.
- Confirm: a network call (HTTP, gRPC, SMTP, a database or cache client) on a request path or in a worker sets no timeout, and its client has none by default: `requests`, `axios`, `node-fetch`, Node's `http`, and Go's `http.Client{}` wait forever; Node's `fetch` waits up to 300 seconds for headers.
- Not a finding if: a shared session or client sets a default timeout (read where it is built); the call runs in a one-off script a person watches.
- Severity: High when the call is on a request path or in a worker pool, because one slow dependency then ties up every worker; Medium in background jobs that have their own watchdog.
- Fix: pass explicit connect and read timeouts (`requests.post(url, json=body, timeout=(3, 10))`, `signal: AbortSignal.timeout(10000)`), set a default on the shared client, and handle the timeout error.
- Verify the fix: a test against a stub server that never answers gets a timeout error within the configured limit.
- Refs: CWE-1088, CWE-400

### ERR-R4 Retries with no cap, no backoff, or on operations that are not safe to repeat
- Leads: `scan.sh ERR-R4` lists retry loops, retry decorators, and `while true` loops.
- Confirm: a failed call is retried in a tight loop or with a fixed short delay and no cap (a retry storm when the dependency is down), or a non-idempotent operation (a charge, an email, an insert) is retried with no idempotency key, so a retry can repeat it.
- Not a finding if: retries are capped, back off exponentially with jitter, and the operation is idempotent or sends an idempotency key.
- Severity: High when a retry can duplicate a charge or message, or when every instance retries a shared dependency in a tight loop; Medium otherwise.
- Fix: cap attempts, back off exponentially with jitter, retry only idempotent operations or send an idempotency key, and stop on errors that cannot succeed on retry (4xx).
- Verify the fix: a test with an always-failing dependency sees the capped number of attempts with growing delays, and one charge for a retried payment.
- Refs: CWE-400

### ERR-R5 Multi-step write that can stop halfway with no rollback (quick)
- Leads: `scan.sh ERR-R5` lists commits and transaction boundaries. Read each function that writes two or more records, or calls an outside service between writes.
- Confirm: a function makes several dependent writes (debit then credit, order then stock, record then file) as separate statements or commits with no enclosing transaction, or calls an outside service (payment, email, carrier) between writes with no compensation, so a failure in the middle leaves the data inconsistent.
- Not a finding if: the writes run in one transaction (`with transaction.atomic()`, `db.transaction(...)`, `BEGIN ... COMMIT`), or a reconciliation job repairs the state and you can see it scheduled.
- Severity: Critical when a routine failure between the steps (a constraint violation, a missing record, a declined call) can lose or duplicate money or records; High when only a crash or outage between the steps can; Medium for derived data that can be rebuilt.
- Fix: wrap the writes in one transaction and check each write's affected-row count; around outside calls, record the intent first and complete or undo it in an idempotent step (an outbox table).
- Verify the fix: a test that makes the second write fail finds neither write stored.
- Refs: CWE-755, OWASP A10:2025

### ERR-R6 Resource not released on the error path
- Leads: `scan.sh ERR-R6` lists files, connections, locks, and sockets acquired outside `with`, `using`, `defer`, or `try/finally`.
- Confirm: a file, database connection, pool client, lock, socket, or thread is acquired and released only on the success path, so an exception leaks it; on a hot path this drains the pool or the file handles.
- Not a finding if: the release sits in `finally`, a context manager, `defer`, `using`, or try-with-resources.
- Severity: High when it is on a request path and the pool or lock is shared, since each failing request keeps one connection; Medium otherwise.
- Fix: acquire with the language's scoped form (`with pool.connection() as conn:`, `try { ... } finally { client.release() }`, `defer rows.Close()`).
- Verify the fix: with a pool of N, a test that forces N+1 failures still gets a connection on the next call.
- Refs: CWE-404, CWE-772

## Also check
- Important outbound calls (payment capture, queue publish, webhook delivery) that fail on the first transient error with no retry at all, where a capped retry with backoff and an idempotency key would be safe.
- An error middleware exists, is registered after the routes, and async handlers reach it (Express 4 needs a wrapper; references/facts.md).
- Wrong status codes: validation failures answered with 200, or server faults answered with 4xx, so callers cannot tell what happened.
- Background jobs and queue consumers retry or dead-letter a failed message instead of acknowledging and dropping it.
- Graceful shutdown: in-flight requests and jobs finish or are requeued on SIGTERM.

## Paper controls (look protective, protect nothing)
- A retry decorator on a function that catches its own errors, so the retry never fires.
- A timeout or circuit breaker configured on one client while the calls go through another.
- An Express error handler registered before the routes, so it never sees their errors.
- A `return` inside `finally`, which silently discards the exception in JavaScript, Python, and Java.
