# APIUSE: Provider API and SDK Usage

Weight 10. Always active.
Owns: correct mechanical use of the provider SDK: reading the stop reason and refusals, native structured output and tool calling, completing tool calls, the prompt-caching mechanism, client lifetime, and deprecated endpoints, SDK surfaces, and parameters.
Not here: what happens after a stop reason is read (RELIABILITY, Also check); parsed output used without validation (OUTPUT-R1); volatile values that bust a cache (COST-R1); the Batch API (COST-R2); streams that users never see and sync clients in async code (SPEED-R1, SPEED-R3); model ids (MODEL); embedding model mismatch or deprecation (RAG-R1, RAG-R3).
Standards: provider API references (references/facts.md: stop reasons, structured outputs, caching, deprecations).
Read first: the client construction, any wrapper around model calls, and every place response text or tool calls are read.

## Cards

### APIUSE-R1 Stop reason and refusal never checked before the text is used
- Leads: `scan.sh APIUSE-R1` lists reads of response text and every stop-reason check.
- Confirm: code reads, parses, stores, or returns the response text without branching on the stop reason (`stop_reason`, `finish_reason`, `finishReason`, or the Responses `status` and `incomplete_details`) or the refusal field; or a check handles one value and lets truncation (`max_tokens`, `length`), unfinished tool turns (`tool_use`, `tool_calls`, `pause_turn`), refusals, and content-filter stops fall through to the same parse.
- Not a finding if: a shared wrapper checks every documented value for all calls (read it); a stream consumer reads the final event's stop reason.
- Severity: High when truncated or refused text can be stored or acted on as a complete answer. Medium when it only fails loudly or is shown to the user.
- Fix: branch on every documented stop value before using the text, and raise typed errors for truncation and refusal (RELIABILITY decides what happens next).
- Verify the fix: unit tests with a mocked response stopped for length, and one refused, expect the error path, not a parse.
- Refs: provider API references (references/facts.md), OWASP LLM05:2025

### APIUSE-R2 JSON or actions requested in prose where a native mechanism exists
- Leads: `scan.sh APIUSE-R2` lists "respond only with JSON" prompts, JSON mode, and ReAct-style action markers.
- Confirm: the call asks for JSON or a tool action in prose, or uses JSON mode (which guarantees syntax only), and code parses the result, where the provider offers native structured output with a schema or native tool calling.
- Not a finding if: the parsed output is used without schema validation: file OUTPUT-R1 only and name the native mechanism in its Fix; the provider or model in use has no native mechanism (facts.md).
- Severity: Medium. High when prose is parsed for tool intent on a path that acts.
- Fix: native structured output with a strict schema, or native tool calls.
- Verify the fix: the request carries the schema or tool definitions, and the code reads the native field.
- Refs: provider structured-output guides (references/facts.md)

### APIUSE-R3 Tools declared but tool calls never completed
- Leads: `scan.sh APIUSE-R3` lists tool declarations, `tool_choice`, and tool-call handling.
- Confirm: tools are sent, but the code never reads the `tool_use` blocks or `tool_calls`, never returns results with the matching ID, or forces `tool_choice` and then reads only the text, so the feature looks tool-enabled and completes no action.
- Not a finding if: a framework or the SDK's tool runner executes the calls and returns the results (read its configuration).
- Severity: High when the feature depends on the tool. Medium otherwise.
- Fix: run each tool call and return a result block with the matching ID before the next model call.
- Verify the fix: a test with a mocked tool call shows the tool runs and its result reaches the next request.
- Refs: provider tool-use guides

### APIUSE-R4 Large stable prefix re-sent with no caching mechanism
- Leads: `scan.sh APIUSE-R4` lists cache markers, cache keys, and cached-token reads.
- Confirm: a system prompt, tool set, or document corpus above the provider's minimum cacheable size goes out on every call of a frequent path with no `cache_control` breakpoint (Anthropic), no explicit cache or implicit-cache-friendly prefix (Gemini), and not front-loaded for automatic caching (OpenAI).
- Not a finding if: the prefix is below the minimum (facts.md); calls come less often than the cache lifetime; caching is already in place (COST-R1 then checks that it hits).
- Severity: Medium. High on a high-volume path where the prefix dominates input tokens.
- Fix: put a breakpoint after the last stable block and keep per-request values after it.
- Verify the fix: two identical requests in staging show cached input tokens on the second.
- Refs: provider prompt-caching guides (references/facts.md)

### APIUSE-R5 SDK client constructed per request or per loop iteration
- Leads: `scan.sh APIUSE-R5` lists client constructors.
- Confirm: `OpenAI()`, `Anthropic()`, `genai.Client()`, `new OpenAI(...)`, or a framework chat model is built inside a request handler, a function called per request, or a loop, so connections are not reused and pools can run out under load.
- Not a finding if: a cached factory or module-level singleton returns the same client (read it); the code is a script that runs once.
- Severity: Medium.
- Fix: build the client once at module or application startup and reuse it.
- Verify the fix: a search shows one construction site, at module or startup scope.
- Refs: provider SDK READMEs

### APIUSE-R6 Deprecated endpoint, SDK surface, or parameter in use
- Leads: `scan.sh APIUSE-R6` lists legacy completion calls, Assistants API calls, legacy function-calling parameters, and deprecated SDK packages.
- Confirm: the code calls an endpoint, SDK package, or parameter the provider has deprecated or shut down (facts.md lists recent ones with dates), or uses a beta feature without its required beta header.
- Not a finding if: the reference is dead code; the provider lists it as supported.
- Severity: High when the shutdown date has passed or is within about 90 days. Medium otherwise.
- Fix: migrate to the named replacement API and delete the old path.
- Verify the fix: a search for the deprecated call returns nothing, and the feature's tests pass against the new call with a mocked client.
- Refs: provider deprecation pages (references/facts.md)

## Also check
- A stream consumed with no mid-stream error handling, or without reading the final event's usage and stop reason (a lost stop reason is APIUSE-R1).
- An SDK major version pinned far behind the provider's supported range, so current parameters are missing from its request types.

## Paper controls (look protective, protect nothing)
- A `finish_reason` switch that handles only `stop` and sends every other value to the same parse.
- `finish_reason` logged, and the parse runs anyway.
- `tool_choice` forced to a tool while only the assistant text is read.
- A module-level client shadowed by a per-call rebuild.
- A tool schema declared while the arguments are still regex-extracted from text.
