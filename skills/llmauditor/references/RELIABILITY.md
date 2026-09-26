# RELIABILITY: Reliability, Retries and Fallback

Weight 10. Always active.
Owns: surviving provider and network failures: timeouts and deadlines, the retry predicate and backoff, idempotent retries, not swallowing errors, fallback and graceful degradation, circuit breaking, and bounded concurrency.
Not here: agent loop bounds (AGENT-R2); a stop reason never read (APIUSE-R1); telemetry and request-ID capture (OBSERV); a retired or incompatible fallback model (MODEL-R2, MODEL-R6); parse or validation failures swallowed (OUTPUT-R3).
Standards: provider error and rate-limit references (references/facts.md), OWASP LLM10:2025.
Read first: the client construction, any retry decorator or wrapper, and the error handling around each model call.

## Cards

### RELIABILITY-R1 Model call with no timeout, or a multi-step operation with no deadline
- Leads: `scan.sh RELIABILITY-R1` lists client construction and timeout settings.
- Confirm: neither the client nor the call sets a timeout, so the SDK default applies (often ten minutes; facts.md), or a request that makes several model and tool calls has no overall deadline.
- Not a finding if: a timeout suited to the path is set on the client or the call; a queue or platform deadline bounds the whole operation (read it).
- Severity: High on a user-facing or worker path, where hung requests pile up. Medium for batch scripts.
- Fix: set a per-call timeout sized to the expected output (stream long outputs) and an overall deadline for the operation.
- Verify the fix: a test with a mocked client that never answers fails within the deadline.
- Refs: OWASP LLM10:2025

### RELIABILITY-R2 Retry predicate misses rate-limit and overload errors, or retries non-retryable ones
- Leads: `scan.sh RELIABILITY-R2` lists retry decorators and SDK retry settings.
- Confirm: the retry wrapper catches only `ConnectionError`, a timeout, or 5xx, so the SDK's rate-limit error (429) and overload errors (529, 503) are never retried (SDK exception classes usually do not subclass Python's built-in `ConnectionError`); or it catches every `Exception` and retries 400, 401, 403, 404, 413, and 422 until attempts run out.
- Not a finding if: the SDK's own retries cover 429, 5xx, and connection errors (check that `max_retries` is not 0) and the wrapper only adds cases; the predicate names the SDK's error classes.
- Severity: High on a production path: the wrapper does nothing under exactly the load it exists for. Medium for internal scripts.
- Fix: retry the SDK's rate-limit, connection, timeout, and server errors (529 overload included); never retry 4xx input or auth errors; cap the attempts.
- Verify the fix: tests raise the SDK's rate-limit error and a 400 error from a mocked client and assert the first is retried and the second is not.
- Refs: provider error references (references/facts.md)

### RELIABILITY-R3 Backoff with no jitter, Retry-After ignored, or retry layers stacked
- Leads: `scan.sh RELIABILITY-R3` lists sleeps, wait strategies, and Retry-After handling.
- Confirm: a fixed or linear sleep, exponential backoff with no jitter, a `retry-after` header parsed and then discarded, or SDK retries left on under a hand-rolled retry so attempts multiply.
- Not a finding if: jittered backoff honors Retry-After and exactly one layer retries.
- Severity: Medium. High when many workers retry in lockstep against a shared quota.
- Fix: exponential backoff with full jitter and a cap, honor Retry-After, and keep one retry layer.
- Verify the fix: a test shows the second attempt waits for the Retry-After value, and total attempts equal the configured cap.
- Refs: provider rate-limit guides

### RELIABILITY-R4 Side-effecting step retried with no idempotency key
- Leads: no reliable pattern; read what each retry wrapper listed by `scan.sh RELIABILITY-R2` wraps.
- Confirm: a retry wraps a model call together with a write, email, charge, or tool action, or retries the action itself, with no idempotency key or duplicate check, or with a key regenerated on each attempt.
- Not a finding if: only the model call is retried and the side effect runs once after success; the side effect is idempotent by key.
- Severity: High when the repeated action moves money, sends messages, or writes records people see. Medium otherwise.
- Fix: retry only the model call, and give each side effect an idempotency key created once per logical operation.
- Verify the fix: a test that fails the first attempt after the side effect asserts the effect happened once.
- Refs: none

### RELIABILITY-R5 LLM failure swallowed into a silent empty or default answer
- Leads: `scan.sh RELIABILITY-R5` lists one-line except blocks and empty catch handlers.
- Confirm: `except: pass`, `except Exception: return ""`, `.catch(() => "")`, or a default value returned on failure with no log, metric, or re-raise, so callers cannot tell a failure from a real empty answer.
- Not a finding if: the handler logs with context and returns a typed failure the caller handles, or re-raises.
- Severity: High when the empty or default answer feeds a decision or is stored as a real result. Medium when a person sees an empty reply.
- Fix: raise a typed error or return an explicit failure, and log it with the provider request ID.
- Verify the fix: a test with a failing mocked client asserts an error result and one log line with the request ID.
- Refs: CWE-390

### RELIABILITY-R6 No fallback, degradation path, circuit breaker, or concurrency bound
- Leads: `scan.sh RELIABILITY-R6` lists fan-out, semaphores, circuit breakers, and fallbacks.
- Confirm: a user-facing flow depends on one model and provider with no fallback model and no degraded response when it is down; no circuit breaker stops calls to a hard-down provider; or fan-out (`asyncio.gather`, `Promise.all`) over user-sized lists has no semaphore or pool limit, causing self-inflicted 429s.
- Not a finding if: the feature is optional and fails visibly with a clear message; fan-out is bounded (read the limit).
- Severity: High when a core user flow has no degraded path or fan-out is unbounded. Medium otherwise.
- Fix: bound concurrency to the rate limit, add a fallback model or a cached or "try again" response, and wrap the client in a breaker.
- Verify the fix: a test forces provider errors and gets the degraded response; a load test shows no more than the configured number of concurrent calls.
- Refs: OWASP LLM10:2025

## Also check
- A stop reason read but mishandled: a truncation or refusal retried in a loop with the same input, or returned as success (APIUSE-R1 owns never reading it).
- Provider status or health checks that nothing uses to shed load.

## Paper controls (look protective, protect nothing)
- `retry_if_exception_type` listing only `ConnectionError`.
- A `Retry-After` value parsed and then discarded.
- A semaphore created but never acquired, or sized at 1000.
- A circuit breaker instantiated but never wrapping the call.
- A `FALLBACK_MODEL` setting that no error path reads.
- SDK auto-retries stacked under a hand-rolled retry.
