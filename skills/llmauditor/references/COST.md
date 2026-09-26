# COST: Cost, Quotas and Token Efficiency

Weight 6. Always active.
Owns: realized spend and abuse economics: prompt caches that never hit, bulk work on realtime endpoints, per-user and per-tenant spend limits, and recomputed work.
Not here: a missing caching mechanism (APIUSE-R4); model tier and routing (MODEL-R6); output caps and reasoning budgets (MODEL-R5); agent loop bounds (AGENT-R2); unbounded history (PROMPT-R5); usage capture and cost attribution (OBSERV-R2).
Standards: OWASP LLM10:2025 (Unbounded Consumption), provider pricing, caching, and batch pages (references/facts.md).
Read first: the prompt builders on high-volume paths, cache settings, batch and cron jobs, and any quota or rate-limit code in front of model calls.

## Cards

### COST-R1 Prompt cache busted by a volatile value in the prefix
- Leads: `scan.sh COST-R1` lists timestamps, IDs, and random values interpolated into prompts, plus cache markers and cache keys.
- Confirm: a timestamp, date, request or trace ID, UUID, random value, or per-user value is interpolated at or near the start of an otherwise static system prompt or tool block, before the cache breakpoint or inside the prefix the provider caches automatically; or tool or context JSON is serialized in a nondeterministic order (unsorted keys, sets), so the prefix bytes change on every call.
- Not a finding if: the volatile value sits after the last breakpoint or at the end of the last message; the prefix is below the cacheable minimum anyway (facts.md); the value changes rarely (a date that changes daily costs one miss a day: Low).
- Severity: High when the busted prefix is large and the path is high-volume. Medium otherwise.
- Fix: move volatile values to the end (the last user message), serialize deterministically (sorted keys), keep the prefix byte-identical, and place the breakpoint after the last stable block.
- Verify the fix: a unit test renders the prefix twice and gets identical bytes; in staging, the second identical request shows cached input tokens.
- Refs: OWASP LLM10:2025, provider caching guides (references/facts.md)

### COST-R2 Bulk offline work on the realtime endpoint instead of the Batch API
- Leads: `scan.sh COST-R2` lists batch calls, cron and queue jobs, and backfills.
- Confirm: a job sends thousands of independent, non-interactive requests (backfills, nightly classification, re-summaries, eval runs) through the synchronous endpoint where the provider offers a Batch API at a discount (about half price; facts.md).
- Not a finding if: results are needed within minutes; the volume is small.
- Severity: Medium. High when the job dominates spend.
- Fix: submit the job through the batch endpoint and keep the synchronous path for interactive work.
- Verify the fix: the job's requests go to the batch endpoint, and the job's line on the bill drops.
- Refs: provider batch pages (references/facts.md)

### COST-R3 No per-user or per-tenant token or spend limit before the call
- Leads: `scan.sh COST-R3` lists quota, budget, and rate-limit code.
- Confirm: a public or multi-user endpoint calls the model with no per-user, per-key, or per-tenant limit on tokens, spend, or requests checked before the call; or limits count only HTTP requests, not tokens; or usage is checked only after the call.
- Not a finding if: a gateway enforces per-key budgets (read its config); the tool is internal and single-user.
- Severity: High on an internet-facing endpoint (denial of wallet). Medium for authenticated internal use. Use Suspected when a limit may live outside the repo.
- Fix: enforce per-user and per-tenant token and spend budgets before the call, cap input size, and record actual usage after it.
- Verify the fix: a test that exceeds the budget gets a 429 with no model call.
- Refs: OWASP LLM10:2025

### COST-R4 Identical work recomputed, or a cache key that never hits or collides
- Leads: `scan.sh COST-R4` lists response caches, hashing, and deduplication code.
- Confirm: identical prompts (same model, parameters, and input) are recomputed with no response cache; documents are re-embedded on every ingest with no content-hash check; identical concurrent requests are not coalesced; or a response or embedding cache key includes a volatile field (never hits) or omits the model, parameters, or prompt version (returns wrong answers).
- Not a finding if: outputs must be fresh or personalized; the cache key covers model, parameters, prompt version, and input (read it).
- Severity: Medium. High when a colliding key returns another request's answer.
- Fix: key caches on a hash of model, parameters, prompt version, and input, and skip re-embedding unchanged content by hash.
- Verify the fix: a test calls twice with the same input and sees one model call; changing the model changes the key.
- Refs: none

## Also check
- An embedding model or dimension count far larger than the task needs, multiplying vector storage and search cost.
- Paid features left on for every call (a web-search or code tool, a long thinking budget) on paths that rarely need them.

## Paper controls (look protective, protect nothing)
- A "batch" helper that fans out concurrent synchronous calls and gets no discount.
- A `prompt_cache_key` or cache breakpoint set while a timestamp sits before it.
- A `monthly_token_limit` field that no code reads before a call.
- A `content_hash` column written but never used to skip embedding.
