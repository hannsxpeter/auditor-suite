# SPEED: Latency and Throughput

Weight 4. Always active.
Owns: perceived and total latency: streaming to people who wait, parallel versus serial calls, event-loop blocking, and non-essential work on the critical path.
Not here: timeouts and deadlines (RELIABILITY-R1); concurrency limits on fan-out (RELIABILITY-R6); model tier on latency-sensitive paths (MODEL-R6); output caps and reasoning budgets (MODEL-R5); prompt caching (APIUSE-R4, COST-R1).
Standards: provider streaming and latency guides.
Read first: the user-facing handlers that call a model, their response types, and every loop over items that calls a model or an embeddings endpoint.

## Cards

### SPEED-R1 No streaming on a user-facing path, or the stream is buffered
- Leads: `scan.sh SPEED-R1` lists stream settings, streaming response types, and proxy buffering settings.
- Confirm: a chat or long-generation endpoint that a person waits on calls the model without streaming; or it streams from the provider but joins all chunks before responding; or it returns `text/event-stream` through a proxy or middleware that buffers (compression, nginx `proxy_buffering on`).
- Not a finding if: outputs are short, or code rather than a person consumes them; the client does not render incrementally by design.
- Severity: Medium. High when typical responses take tens of seconds on the main user path.
- Fix: stream end to end, and turn off buffering on the stream route (for example the `X-Accel-Buffering: no` header).
- Verify the fix: in staging, the first token reaches the client well before the model finishes.
- Refs: provider streaming guides

### SPEED-R2 Independent calls run in series, or one call per item
- Leads: `scan.sh SPEED-R2` lists embedding calls and fan-out helpers; read each loop body that calls a model.
- Confirm: independent model, embedding, or tool calls are awaited one after another; a model call sits inside a per-row loop (N+1); embeddings go one text at a time where the API takes a list; or retrieval and a guardrail check run in series although they could overlap.
- Not a finding if: each call needs the previous result; a documented rate limit requires serial calls.
- Severity: Medium. High when it multiplies latency on the main user path.
- Fix: run independent calls concurrently with a bound (RELIABILITY-R6), and send embedding inputs as a list.
- Verify the fix: a trace of one request shows the calls overlapping, and embedding requests carry lists.
- Refs: none

### SPEED-R3 Synchronous model client inside an async handler
- Leads: `scan.sh SPEED-R3` lists synchronous client constructors and synchronous HTTP calls.
- Confirm: an `async def` or async route calls a synchronous client (`OpenAI()` rather than `AsyncOpenAI()`, `Anthropic()` rather than `AsyncAnthropic()`, `requests`) directly, blocking the event loop for the whole generation.
- Not a finding if: the call runs in a thread (`asyncio.to_thread`, `run_in_executor`) or the framework runs synchronous routes in a thread pool (FastAPI `def` routes).
- Severity: High on a server with concurrent users, because one slow generation stalls every request on that worker. Medium otherwise.
- Fix: use the SDK's async client, or move the call to a thread.
- Verify the fix: a load test with a slow mocked provider shows other requests still being served.
- Refs: provider SDK READMEs

### SPEED-R4 Non-essential generation awaited on the critical path
- Leads: `scan.sh SPEED-R4` lists background-task helpers.
- Confirm: a title, summary, tag, or enrichment call whose result the response does not need is awaited before responding, or a task is started with `create_task(...)` and then awaited before returning.
- Not a finding if: the response needs the result.
- Severity: Medium. Low when it adds under a second.
- Fix: respond first, and run the extra work in a background task or a queue.
- Verify the fix: a trace shows the endpoint's latency no longer includes the extra call.
- Refs: none

## Also check
- A local model or embedding model loaded inside the request handler, so every request pays the cold start.
- A long, unchanging context re-sent on a latency-sensitive path where a cached prefix or a shorter context would cut time to first token (the caching mechanism itself is APIUSE-R4).

## Paper controls (look protective, protect nothing)
- `stream=True` whose output is joined before returning.
- A `text/event-stream` response that a proxy or compression middleware buffers.
- `asyncio.create_task(...)` whose task is awaited before the response.
- `Promise.all` over tasks that are still chained one after another inside.
