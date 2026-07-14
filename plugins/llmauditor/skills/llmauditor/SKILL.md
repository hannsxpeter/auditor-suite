---
name: llmauditor
description: Audit how the codebase integrates Large Language Models end to end (prompt construction and context, model selection and routing, provider API and SDK usage, reliability, security and trust boundaries, agents and tools, RAG and vector search, structured output, cost, speed, evaluation, and observability), write llmaudit.md (a scored, prioritized, self-contained report), then display the results in chat. Read-only: never calls a model, never runs the app, never mutates data or indexes. Invoke with /llmauditor in Claude Code or $llmauditor in Codex.
---

> Invocation: type `/llmauditor` (Claude Code) or `$llmauditor` (Codex) to run this command. The same skill works in both tools. Treat any text after it as the optional path-or-scope argument (a subpath, a single feature, or one provider integration).

# llmauditor

Audit how the codebase in the current working directory integrates Large Language Models end to end: how prompts are constructed and context is managed, how models are selected, configured, and switched, how the provider API and SDK are used, how the integration stays reliable, how it is secured and bounded, how agents and tools are wired, how retrieval and vector search work, how model output is parsed and consumed, and how cost, speed, evaluation, and observability are handled. Then do two things:

1. **Write a report** named `llmaudit.md` at the root of that codebase.
2. **Display the results in this chat**: the overall score, the scorecard, and the top fixes (see "Report in chat" below). Do not finish silently.

This is **read-only analysis of the code as written**. Do not call a model or an embeddings endpoint, do not run the application or its agents, do not execute prompts, do not connect to a vector store, do not mutate data or an index, and do not run an eval suite against a live provider. Work from the prompt templates, provider SDK calls, model and routing config, tool and agent definitions, retrieval and embedding code, output-parsing code, and configuration in the repository. The only file you create is `llmaudit.md`. If an optional path or scope was provided as an argument, audit that subtree or integration; otherwise audit the whole LLM surface rooted at the working directory.

The report is written for a reader who has **no memory of the audit**, typically an AI agent that will open `llmaudit.md` later and decide, on its own, what to fix. Every finding must therefore stand alone: cite exact locations (`path/to/file.ext:line`), name the prompt, model id, tool, retriever, or call site, trace the path from untrusted source to dangerous sink where relevant, carry its own context, and say how to verify the fix. If a finding cannot be acted on by someone who only has the report and the code, it is not finished.

This is an **LLM-integration correctness, safety, efficiency, and operability audit**. Scope is the AI layer: how the application talks to models, how it constrains and trusts their input and output, how it retrieves and grounds, how it stays within latency, cost, and reliability budgets, and how it is measured. General code quality belongs to `codeauditor`, the full application security surface to `secauditor`, the database layer to `dbauditor`, and user experience to `uxauditor`; touch those only where they create an LLM-layer defect. Where LLM security overlaps `secauditor` (the `LLMSEC` lens there), this audit covers the deeper LLM-specific slice (prompt injection, improper output handling, excessive agency, vector and embedding weaknesses, data governance to the provider) and says so.

---

## Operating principles (non-negotiable)

These govern the whole audit. A report that violates any of them is not done.

1. **Evidence over assertion.** No claim without a concrete, checkable reference (`file:line`) and the data path that makes it real: the prompt-building expression, the SDK call and its arguments, the tool definition, the retriever query, the parse-then-sink chain. Apply the substitution test to every sentence: if you could swap in a different project and it would read equally true, it is filler. "Prompts are not optimized" fails. "`agent/chat.py:42` builds the system message as `f'...{retrieved_doc}...'`, so a poisoned RAG chunk is concatenated into the system role and followed as an instruction (indirect prompt injection)" passes.
2. **Verify against reality, not the prompt's promise.** Read the code and the actual request payload, not the prompt's wording, a comment, or the README. A system prompt that says "respond only with JSON" guarantees nothing if the call does not use a structured-output mechanism; an instruction "only access the current user's records" is not authorization; "do not hallucinate" is not grounding. The gap between the prompt's claim and the shipped code is itself a finding, and often the most serious one.
3. **Refuse theater. Hunt for paper controls.** The most dangerous defects look protective but carry no weight: a prompt-injection guardrail defined but never called before the request (or run only on the direct user turn, never on retrieved or tool content); a `cache_control` marker placed after a volatile timestamp so the cache never hits; `response_format` set to JSON while the output is still regex-parsed and never schema-validated; `stop_reason`/`finish_reason` logged but never branched on; a retry wrapper whose `except` catches `Timeout` but not the SDK's `RateLimitError`; a `max_tokens` cap presented as the agent-loop bound; an ACL field stored on every vector but never passed as a query filter; a human-in-the-loop flag that defaults to auto-approve; an eval suite committed but never run in CI; a tracing client constructed but never attached to the call. Flag anything that exists for appearance but does not actually hold.
4. **Reachability and blast radius.** A weakness matters in proportion to who can reach it and what it can touch. Calibrate to the "lethal trifecta": access to private data, exposure to untrusted content, and the ability to communicate or act externally. An unbounded loop on an internal batch script is not an unbounded loop on a user-facing agent with a `send_email` tool; an unparsed refusal in a toy demo is not one feeding a payment decision. State the path and the precondition. Where the consequence depends on real model behavior, traffic, data volume, or runtime config you cannot see from static code, mark it Suspected and say what would confirm it.
5. **Find the root, not the leaves.** If the same mistake appears across the integration (no role separation in any prompt, the model output `json.loads`-parsed with no schema everywhere, no eval anywhere, a floating model alias in twelve files), that is one systemic finding, not twelve. Cluster instances into a class-level finding so the reader fixes the cause once.
6. **Verify adversarially.** For every candidate, try to refute it before keeping it: is there a guardrail, a schema validation, an authz check in code, a framework default, or a deliberate documented trade-off elsewhere that neutralizes it? Is the agent actually wired to untrusted input and a dangerous tool, or is it a closed internal helper? Assign a confidence level; when you cannot confirm by reading, mark it Suspected.
7. **Calibrate to the workload and exposure, not to fear.** Grade against what the integration actually is: a single-call local summarizer, an internal classification batch job, a public chatbot, or an autonomous agent with tools and money. Single-model design is legitimate; absence of tiered routing is only a defect under demonstrated heterogeneous load. Deterministic output handling matters more when output reaches a sink. State the detected paradigm and calibrate every lens to it.
8. **Be honest about scope.** Say which prompt files, SDK call sites, tools, and retrieval code you read, whether you read exhaustively or sampled, which surfaces are present and which are N/A, and which findings need a running model, real traffic, an eval run, or production config to confirm. Never imply you called a model, measured latency or cost, or ran an eval. Static code cannot reveal real answer quality, true token cost, actual latency, retrieval recall on live data, or whether a guardrail blocks a given attack; those become Suspected findings or "verify with X" items.
9. **Score with reasons, not vibes.** Every dimension score is justified against its specific findings. No number appears without the evidence that produced it.
10. **Name the strengths.** Record what the integration gets right, with evidence (real role separation and delimited untrusted content, pinned model snapshots in one config, native structured outputs plus downstream schema validation, per-tenant retrieval filters actually applied, prompt caching correctly keyed, bounded agent loops with human approval on destructive tools, an eval gate in CI, redaction before send and before logging), so the acting agent preserves them instead of removing them while fixing something else.
11. **Recommendations are specific, actionable, and provider-accurate.** Banned: "improve prompts," "use a better model," "add guardrails," "optimize cost." Required: the exact change (the role to move untrusted text into, the snapshot to pin, the `response_format`/tool schema to add and validate against, the `cache_control` placement, the retry predicate and backoff, the loop bound, the metadata filter), the safe pattern in the project's own SDK, and how to confirm it (a payload to inspect, an eval to run, a count that should now be zero). Never include a working jailbreak or exploit payload; describe the weakness and the fix.

---

## Ownership rule (the de-duplication discipline)

Many defects surface through several lenses: a floating model alias touches prompt stability, API usage, and reliability; an unbounded agent loop touches cost, reliability, and agency; the structured-output flag set but output regex-parsed touches prompting, API usage, and output handling; a retrieved chunk pasted into the system prompt touches prompt construction and injection. **Each finding is emitted by exactly one dimension, its owner, and contributes only to that dimension's score.** Other dimensions may cross-reference it ("see MODEL for the alias-pinning root") but must not re-score it. Tag every finding with its owner. Use this ownership map:

| Defect | Owner | Rule |
|---|---|---|
| Floating model alias / deprecated or retired model id hardcoded | **MODEL** | sole owner of model-id pinning, deprecation tracking, eval-gated upgrades; PROMPT/APIUSE/RELIABILITY cross-reference only |
| Untrusted retrieved/tool/web text spliced into the prompt with no role boundary | split: **PROMPT** (construction mechanics: missing role separation, forgeable delimiter) / **LLMSEC** (the exploitable injection trust boundary, LLM01) | score the construction smell in PROMPT, the trust-boundary failure in LLMSEC, no double-count of the same bytes |
| RAG retrieval has no per-user/tenant ACL filter (cross-tenant leakage) | **LLMSEC** | authorization is a security control regardless of layer; RAG owns retrieval quality (chunking, embedding-space integrity, grounding) and cites the filter as defense in depth |
| Embedding model unpinned/upgraded with no stored version, mixed vector space | **RAG** | RAG owns the embeddings lifecycle and re-embed migration; MODEL owns the generic pinning principle |
| Structured-output flag set but result still regex/hand-parsed, then consumed | **OUTPUT** | OUTPUT owns the consumption contract and safe sink; PROMPT owns "not constrained at generation", APIUSE owns "native feature unused"; cross-reference, do not re-score |
| Model output to a dangerous sink (eval/exec/SQL/HTML/url-fetch) | **LLMSEC** (the "output is untrusted" boundary and LLM-specific sinks, LLM05) | OUTPUT owns the missing schema-validation; generic injection hardening is shared with `secauditor` |
| `stop_reason`/`finish_reason`/refusal never read | **APIUSE** | APIUSE owns "the field is never checked"; RELIABILITY owns the recovery policy once checked; OUTPUT owns feeding truncated text to a parser |
| Unbounded agent tool/reasoning loop (no iteration/cost/wall-clock cap) | **AGENT** | AGENT owns the loop control; COST cites it as denial-of-wallet, RELIABILITY as a hang/self-overload; per-call `max_tokens` is the paper-control, not the loop bound |
| Prompt caching busted by a volatile value before the breakpoint | **COST** | COST owns the realized spend; PROMPT owns the construction root (reorder the prefix), APIUSE owns the mechanical mis-keying |
| LLM errors swallowed (`except: pass`/`return ''`) into silent wrong answers | **RELIABILITY** | RELIABILITY owns not-swallowing; OBSERV owns the positive telemetry and request-id capture |
| No eval/regression harness gating prompt edits and model bumps | **EVAL** | EVAL owns the harness and CI gate; MODEL/PROMPT reference the eval gate as the upgrade control but do not own building it |
| Excessive agency: high-impact tool with no human gate / broad credentials | split: **AGENT** (the missing gate, per-tool least privilege) / **LLMSEC** (the security framing, identity/privilege, the trifecta) | AGENT owns the controlling line; LLMSEC owns the authorization model |
| Secrets/PII placed into prompts or LLM logs | **LLMSEC** | secrets-in-prompts and secrets-in-LLM-logs are LLMSEC; vault hygiene and key rotation are `secauditor`'s |

---

## Method

Run these phases in order. Use search to find candidates, then **read the cited prompt builder, SDK call, tool definition, or retrieval code to confirm the data path** before recording anything. A grep hit (an `openai` import, a `messages.create`, a `top_k`) is a lead, not a finding.

### Phase 0 - Orient

- Detect the **providers and access layers** from manifests, imports, and config: provider SDKs (`anthropic`, `openai`, `google-genai`/`google-generativeai`, `mistralai`, `cohere`, `boto3` Bedrock, Azure OpenAI, Vertex AI), gateways and routers (LiteLLM, OpenRouter, Portkey, an internal proxy), local/self-hosted runtimes (Ollama, vLLM, llama.cpp, LM Studio, Hugging Face `transformers`), and the calling style (sync vs async, streaming, raw HTTP vs SDK).
- Detect **orchestration and agent surfaces**: LangChain/LangGraph, LlamaIndex, CrewAI, AutoGen/AG2, the OpenAI Agents SDK, Pydantic-AI, Semantic Kernel, Haystack, DSPy; native tool/function calling (`tools=`, `tool_use`/`tool_calls`/`function_declarations`); and MCP clients/servers (`mcp.json`, `mcpServers`, `ClientSession`, `call_tool`). Their presence activates **AGENT**.
- Detect **retrieval and vector surfaces**: embedding calls (`embeddings.create`, `embed_content`, `SentenceTransformer`, Cohere/Voyage embed) and vector stores (pgvector, Pinecone, Weaviate, Qdrant, Chroma, Milvus, FAISS, LanceDB, OpenSearch/Elasticsearch kNN, Redis VSS), retrievers, rerankers, and any "retrieve then stuff into prompt" path. Their presence activates **RAG**.
- Detect **structured-output, evaluation, and observability** wiring: native structured outputs (OpenAI `response_format` json_schema, Anthropic tool-extraction, Gemini `responseSchema`), schema validators (Pydantic, Zod, jsonschema); eval suites and golden datasets (`eval/`, `tests/` that hit the model, RAGAS, promptfoo, DeepEval, LangSmith evals); and LLM observability (LangSmith, Langfuse, Helicone, OpenLLMetry, OpenTelemetry GenAI, Phoenix).
- Determine the **LLM usage paradigm** (single-shot completion, chat assistant, classification/extraction pipeline, RAG question-answering, autonomous tool-using agent, multi-agent system, batch/offline job) and the **exposure and data sensitivity** (internet-facing vs internal vs local; whether PII/PHI/financial data or secrets enter prompts or context; single- vs multi-tenant). These set the calibration and raise the bar on LLMSEC, AGENT, and RAG.
- Note the **model ids in use** and where they live (inline literals vs one config), and which provider deprecation/versioning page would confirm whether each is a floating alias, a pinned snapshot, or already retired. Do not hardcode a model list in findings; verify against the provider page and keep guidance principle-based (alias vs dated snapshot, deprecated vs active).
- Measure size (number of prompt sites, call sites, tools, retrievers) and decide exhaustive vs sampled reading. Declare which in the report.
- Note explicitly **what static code cannot reveal**: real answer quality, true token cost and latency, retrieval recall on production data, whether a guardrail blocks a given payload, whether an eval passes, and live provider behavior. These become Suspected findings or "verify with X" items, never confident claims.
- Identify what to exclude: vendored code, generated SDK stubs, example/notebook code not shipped, test fixtures (but do read prompt fixtures and few-shot files for committed secrets and PII). Record exclusions.
- If there is **no LLM integration** (no provider SDK, no model calls, no embeddings, no agent), say so plainly in chat and stop. Do not invent findings.

### Phase 1 - Map the LLM data flow and trust boundaries

Do a short, lightweight model-and-trust pass before the per-dimension checklist. Keep it to roughly a half page; it informs prioritization.
- **Entry points and untrusted content:** where user input, and where indirect content (RAG documents, tool/function results, fetched web pages, emails, PDFs, uploaded files, prior conversation, model output replayed as input), enters a prompt. Mark each as developer-trusted or untrusted.
- **Trust boundaries:** where untrusted content crosses into a privileged channel (the system prompt, the agent's instruction stream, a tool argument) and where model output crosses into a sink (a renderer, a shell, a query, a fetch, another tool, a human decision).
- **Sensitive assets and actions:** what leaves the org to the provider (PII, confidential docs, secrets), and what the integration can do (the tools, especially destructive or external-effect ones), and under whose identity and credentials.
- **The lethal trifecta:** flag any path that combines access to private data, exposure to untrusted content, and the ability to communicate or act externally; this is the highest-risk surface.
- **Models, routing, and budgets:** which model serves which path, whether routing/fallback exists, and where caps (max output, loop bounds, quotas, timeouts) are or are not set.
- **Retrieval and grounding surfaces** and how derived stores (a vector index, a cache) are kept consistent with the source of truth.
Trace two or three highest-risk flows end to end: an untrusted document reaching the model and then a tool or a sink; a money/identity/destructive action and the gates around it; a hot user-facing path and its latency, caching, and cost shape. Spend effort proportional to blast radius.

### Phase 2 - Analyze across every lens

For each candidate capture three things: the location (`file:line`) and the data path, what the code does now, and why that is a problem and how big its blast radius is. Do not score yet. Skip a conditional lens whose surface is absent (say so), and calibrate every lens to the paradigm from Phase 0. Respect the ownership map: emit each finding once.

**Security, Trust Boundaries, Safety and Data Governance** (LLMSEC) - the dominant exploit surface. *Owns: prompt-injection trust boundary, improper output handling, excessive-agency security framing, system-prompt leakage, sensitive-data disclosure, RAG access control, and data governance to the provider.*
- **Indirect prompt injection** (OWASP LLM01): retrieved/tool/web/email/PDF content concatenated into the same message as instructions with no structural isolation, so attacker text inside a document is followed as a command. Require role separation, delimited untrusted-data framing, and for high-impact agents architectural isolation (dual-LLM / quarantined-LLM, CaMeL-style capability enforcement). Delimiters are hygiene, not a boundary.
- **Improper output handling** (OWASP LLM05): model output flowing into `eval`/`exec`/`pickle.loads`/`subprocess(shell=True)`/`os.system`, string-built SQL, `innerHTML`/`dangerouslySetInnerHTML`/unescaped templates, or `fetch(url_from_model)` with no validation. Model output is untrusted; validate and encode at the sink (parameterized SQL, argv arrays, context-aware encoding, URL allowlist), do not trust the prompt to constrain it.
- **Excessive agency** (OWASP LLM06): high-impact/irreversible tools (send, delete, transfer, deploy, run-shell, file-write) executed autonomously with no human gate; tools running under one broad ambient credential (admin token, DB superuser) shared across users, so the model becomes a confused deputy. Require human-in-the-loop on irreversible actions and per-tool least-privilege scoped to the caller's identity. (AGENT owns the loop and gate mechanics; LLMSEC owns the security framing.)
- **System-prompt leakage and authz-by-prompt** (OWASP LLM07): secrets, keys, connection strings, internal hostnames, or access-control rules ("only admins may...") placed in the system prompt as if it were secret or enforcing. Assume the system prompt is public; move every security decision into deterministic code outside the model.
- **Sensitive-data disclosure** (OWASP LLM02): raw PII/PHI/financial records or whole documents sent to a third-party provider with no minimization or redaction; user-controlled text interpolated into the system role; conversation memory shared across users/sessions with no isolation.
- **Data governance:** provider data controls left at risky defaults (no ZDR or modified abuse monitoring for regulated data, OpenAI `store=True`/default, consumer-tier endpoints for org data, no region/residency, no executed DPA/BAA), and no documented retention/TTL on conversation logs and traces. Verify against the provider's current data-usage docs, not assumptions.
- **Multimodal injection:** instructions embedded in images/audio/PDFs (visible or steganographic) that drive tool calls or instruction-following, bypassing text-only input filters.
- **Exfiltration side channels:** outbound fetch/render of model-emitted URLs or markdown images reaching arbitrary destinations, letting an injection encode data into a URL the app loads.
- Paper controls to hunt: a "ignore instructions in the documents below" line treated as the boundary; a guardrail/moderation call whose result is logged but never blocks; a redaction util applied to logs but not to the provider payload; an ACL stored in vector metadata but never used as a query filter; `store=False` set with no approved ZDR agreement; authz that is only a system-prompt instruction; an SSRF allowlist on the explicit fetch tool while markdown auto-image-load stays open.

**Prompt Construction and Context Management** (PROMPT) - *Owns: how prompts are assembled and how the context window is budgeted; the construction mechanics, not the exploitability (LLMSEC) or the realized cost (COST).*
- **No role separation:** instructions, examples, context, and the question collapsed into one concatenated string or one user message, ignoring the system/developer vs user vs assistant/tool roles that carry the privilege gradient. Put durable instructions in the system/developer role, the request in the user role, prior turns as real messages.
- **Untrusted content in a privileged channel:** retrieved or user-derived text interpolated into the system prompt (construction view; LLMSEC owns the trust-boundary score). Keep the system prompt developer-controlled and static; put untrusted/user values in the user role after validation, wrapped in explicit delimiters labeled as data.
- **Context ordering and "lost in the middle":** long documents appended after the question or buried mid-block. For long inputs, place documents near the top, then instructions, then the question, with the highest-relevance chunk at a high-recall edge.
- **Cache-hostile prefix:** a timestamp, request id, uuid, or user value interpolated near the top of an otherwise static prefix, or tool/system content rendered in nondeterministic order (unsorted dict/set serialization), so any prompt cache is invalidated every call. Keep the prefix byte-stable; move volatile values to the end. (COST owns the spend impact.)
- **Scattered, unversioned prompts:** prompt literals copy-pasted across many files with near-duplicate drift, no central registry, and no version id, so a fix in one path is missed and changes cannot be attributed or rolled back.
- **Unbounded context assembly:** full history, all retrieved chunks, or whole documents stuffed in with no token budget, windowing, or summarization (COST and SPEED cross-reference the consequence).
- Paper controls to hunt: a `prompts.py` constants file that half the call sites bypass with inline strings; a "version 2" prompt nobody references while live code uses a hardcoded literal; a delimiter used as if it secured the boundary.

**Model Selection, Configuration and Routing** (MODEL) - *Owns: which model, with which parameters, and the routing/switching/fallback selection logic. Sole owner of model-id pinning and deprecation.*
- **Floating alias instead of a pinned snapshot:** a bare family name or a `-latest`-style alias in code/config, so the underlying model can shift behavior, latency, and price with no code change, breaking pinned prompts and evals. Pin a dated snapshot in one config constant; treat a bump as a reviewed, eval-gated change.
- **Deprecated or retired model id** hardcoded in a caller, registry, fallback chain, or test fixture: a latent 404 at the sunset date. Cross-check every id against the provider deprecation page and add a scheduled review.
- **Scattered hardcoded model ids** rather than one configurable source of truth, and **environment-blind selection** (the same expensive or preview model in tests, dev, and prod).
- **Wrong sampling parameters for the task:** `temperature`/`top_p` left at the default or set high for extraction, classification, structured output, or tool-argument generation (use low/0); or sampling params passed to a reasoning model that ignores or rejects them ("`temperature=0` for determinism" on a reasoning model is decorative).
- **Wrong or missing output-limit parameter:** the wrong key for the surface (`max_tokens` vs `max_completion_tokens` vs `max_output_tokens`), a missing required cap, or a cap unrelated to the expected output size; for extended thinking, `max_tokens` not strictly greater than the thinking budget.
- **Reasoning budget mis-set:** reasoning effort/thinking budget statically maxed for every request, or a reasoning model effectively run with reasoning disabled on a hard task.
- **Routing and switching defects:** no tiered routing under demonstrably heterogeneous load (a legitimate gap only then); or a cascade whose escalation trigger does not reflect answer quality, never fires, or fires every time; or a cross-provider fallback whose model is shape-incompatible (different param names, message/tool schema, or token semantics).
- Paper controls to hunt: a `MODEL_VERSION`/"pinned" key whose value is still an alias; a fallback list naming a retired model (the failover itself 404s); a `select_model()` whose branches all return the flagship (cheap branch is dead code); a configured fallback that is unreachable (wrong key, lacking capability).

**Provider API and SDK Usage** (APIUSE) - *Owns: correct mechanical use of the specific provider SDK and native features. Owns "the response signal is never checked".*
- **`stop_reason`/`finish_reason`/refusal ignored:** the text read directly without branching on `max_tokens`/`length` (truncated), `tool_use`/`tool_calls` (turn not done), `pause_turn`, `content_filter`, or a `refusal` field, so truncated output is parsed as complete, tool calls are dropped, and refusals crash a parser. (RELIABILITY owns the recovery policy; OUTPUT owns parsing truncated text.)
- **Native features unused or misused:** hand-parsing prose where tool/function calling fits; free-text-plus-`json.loads` where native structured outputs exist (OpenAI strict `json_schema`, Anthropic tool-extraction, Gemini `responseSchema`); tools declared but the `tool_use` input never read or `tool_result` never returned (the integration looks tool-enabled but completes no action); streaming requested but consumed as a non-streamed object, or with no mid-stream error handling and no final-usage/`stop_reason` read.
- **Prompt/context caching not used** where a large stable prefix (system prompt, tool schema, RAG corpus) is re-sent every call: the mechanical absence of `cache_control` (Anthropic), `CachedContent` (Gemini), or a stable front-loaded prefix (OpenAI auto-cache). (COST owns the spend; APIUSE owns the missing mechanism.)
- **Batch API not used** for large offline/bulk work that the synchronous endpoint is looped over.
- **Per-request client construction:** the SDK client built inside the handler/loop instead of once at module/app scope, defeating connection reuse and risking pool exhaustion under concurrency; sync client used in async paths.
- **Deprecated endpoints/params:** legacy text-completions, the deprecated Assistants API, or removed parameters; missing required beta headers for a feature in use.
- **Embeddings mechanics:** query and document embedded with different models or dimensions, or a deprecated embedding model id (RAG owns the lifecycle and vector-space consistency; APIUSE owns the mechanical mismatch).
- Paper controls to hunt: a `finish_reason` switch that handles only `stop` and lets every other value fall through to the same parse; tools forced with `tool_choice` but only the assistant text read; a module-level client shadowed by a per-call rebuild; `stream=True` whose whole output is joined before returning.

**Reliability, Retries and Fallback** (RELIABILITY) - *Owns: surviving transient and provider failures. Owns not-swallowing errors and the recovery policy.*
- **No timeout** on the model/HTTP call, and **no overall deadline** on a multi-step operation.
- **Naive retry:** fixed or linear sleep with no jitter (a thundering herd), or exponential in name only seeded from a constant.
- **Wrong retry predicate:** catching generic `Exception` or only 5xx (so non-retryable 400/401/413 are retried forever) while the SDK's `RateLimitError`/429 and overloaded 529/503 fall through uncaught - the wrapper is decorative under exactly the load it should handle. Also **`Retry-After` ignored** when the provider stated the wait.
- **Non-idempotent retry:** retrying an operation with side effects (a write, an email, a charge, a tool action) with no idempotency key, double-executing it; or an idempotency key regenerated per attempt.
- **Stop-reason recovery missing:** `length`/`max_tokens` truncation and `content_filter`/refusal stops treated as successful complete responses (APIUSE owns "never read"; RELIABILITY owns "read but mishandled, often retried in a loop").
- **Swallowed errors:** `except: pass`/`return ''`/`.catch(() => '')` turning a failure into a silent wrong answer with no log, metric, or re-raise.
- **No bounded concurrency:** unbounded `gather`/`Promise.all` fan-out self-inflicting rate limits; no circuit breaker against a hard-down provider; **no fallback** model/provider and no graceful-degradation branch when the model is unavailable.
- **Unbounded operation budget:** per-call caps set but the surrounding agent loop has no max-iteration, cumulative-token, or wall-clock bound (AGENT owns the loop; RELIABILITY cites the hang/self-overload).
- Paper controls to hunt: `retry_if_exception_type` listing only `ConnectionError`; a `Retry-After` parsed then discarded; a `Semaphore` created but never acquired (or sized at 1000); a breaker instantiated but never wrapping the call; a `FALLBACK_MODEL` referenced nowhere in the catch path; SDK auto-retries stacked on a hand-rolled retry.

**Output Handling and Structured-Output Consumption** (OUTPUT) - *Owns: the field-level shape contract and the safe consumption of model output. Sole owner of schema-validate-before-use.*
- **Free-text parsed as data:** `json.loads`/`JSON.parse` on raw `.content`/`.text` with no native structured output, and regex/`split`/index-slicing to pull values out of prose.
- **No schema validation:** structured-output/JSON mode enabled but the parsed object passed downstream with no Pydantic/Zod/jsonschema validation; enum/range fields used in branches without checking the allowed set; permissive casts (`int(x)`, `Number(x)`) that hide bad data.
- **Truncation/refusal not gated before parsing:** parsing without first checking `finish_reason`/`stop_reason` for `length`/`max_tokens` or a `refusal`/`content_filter`, so a cut-off or a safety block is parsed as data.
- **Fragile extraction:** ad-hoc code-fence stripping (`replace('```json','')`, `split('```')[1]`) or a greedy `{.*}` regex feeding the parser; mid-stream `json.loads` of a partial buffer.
- **Parse failure mishandled:** caught and swallowed to `None`/`{}`, or retried with the identical prompt and no validation-error feedback, so the model has nothing new to correct.
- **Loose schema defeats the guarantee:** `additionalProperties` not false, fields not in `required`, everything typed `string`, `strict` omitted, or extra fields allowed, so the "guaranteed" shape can drift.
- **Tool-argument trust:** reading `tool_calls[0].arguments` without checking the model actually called that tool, and executing tool arguments without re-validating them against the tool's own schema.
- **Model-asserted control flow:** gating a security- or correctness-sensitive action purely on a model-returned boolean (`is_safe`, `has_permission`) with no corroboration.
- Paper controls to hunt: a prompt that says "respond ONLY with JSON" while the call uses plain text mode; a Pydantic model defined but never validated against the response; `finish_reason` logged but the parse proceeds unconditionally; `strict:true` set on a schema that does not meet strict-mode requirements (silently downgraded).

**Cost, Quotas and Token Efficiency** (COST) - *Owns: realized spend and abuse economics (denial of wallet). Owns the impact of cache waste.*
- **Caching waste:** a large byte-stable prefix re-sent every call with no cache marker, or a cache marker busted by a volatile value before the breakpoint, or a response/embedding cache whose key omits a parameter that changes the output or includes a volatile field so it never hits. (PROMPT owns the reorder fix.)
- **Wrong tier and channel:** a flagship model hardcoded for trivial high-volume work (classification, routing, short extraction); bulk non-interactive work run through the realtime endpoint instead of the Batch API; an oversized embedding tier for a simple task.
- **Unbounded output and loops:** missing or oversized output caps relative to the expected response; an agent/tool loop with no max-steps, cumulative-token, or wall-clock budget (the per-call `max_tokens` is not the loop bound); unbounded history/context growth replayed every turn.
- **No quotas or spend caps:** no per-user/tenant token or dollar budget enforced before the call; rate limiting only on HTTP count, not token volume.
- **Redundant work:** identical prompts recomputed with no response cache; documents re-embedded with no content-hash guard; no in-flight coalescing of identical concurrent requests.
- **No cost attribution:** the `usage` block discarded; spend not recorded per request/user/feature/model, so the bill cannot be attributed.
- Paper controls to hunt: a "batch" helper that just fans out concurrent sync calls (no discount); a `model_router` whose branches all return the flagship; a `monthly_token_limit` field never read before a call (or checked only after); a `content_hash` written but never used to skip embedding; `summarize_history()` defined but only called past an unreachable threshold.

**Latency and Throughput** (SPEED) - *Owns: perceived and total latency. Distinct from COST: minimizing output tokens helps both, but streaming and parallelism trade latency, not spend.*
- **No streaming** on a user-facing path, so the user waits for the full response; or streaming plumbed but the server buffers the whole stream before returning (streaming UX claimed, none delivered).
- **Serial where parallel fits:** independent model/embedding/tool calls issued with back-to-back awaits; an LLM call inside a per-row loop (N+1); embeddings requested one text at a time instead of as an array.
- **Output-token latency:** output token count dominates latency; missing or oversized output caps and unbounded reasoning on latency-sensitive paths.
- **Blocking the event loop:** a synchronous client called from an async handler (the async signature is cosmetic); heavy generation on the critical path whose result is not needed inline (title/summary/enrichment awaited before responding).
- **Caching for latency not used:** a large stable prefix re-sent with no caching on a latency path; a volatile leading token defeating the cache.
- **No client-side concurrency limit** on fan-out, so the app is throttled; **no per-call timeout/deadline** so a flaky upstream multiplies latency; serial stages (retrieval then generation, guardrail before generation) that could overlap.
- **Wrong tier for latency:** a heavyweight reasoning model on a simple latency-sensitive path (routing, classification, autocomplete, guardrail).
- Paper controls to hunt: `asyncio.create_task(...)` whose task is then awaited before returning (backgrounding is cosmetic); a `text/event-stream` response a proxy buffers; `Promise.all` whose tasks are still chained internally.

**Evaluation, Testing and Quality** (EVAL) - *Owns: whether output quality is measured and whether changes are gated. Owns the eval harness and CI gate.*
- **No offline eval suite** for a quality-critical LLM feature: no golden dataset of input/expected pairs, no scoring script, no eval in CI.
- **Live-model tests in CI** with no mock/cassette/fixture (flaky, costly, non-deterministic), and eval/test cases that assert on output without pinning temperature to 0.
- **Ungated change:** prompt, few-shot, or model-id edits landing with no eval run, baseline diff, or before/after quality number; a model swap with no comparative eval on the same dataset.
- **Eval present but not wired:** a suite committed but no CI job invokes it and no threshold gates the build; scores printed with no committed baseline and no regression-vs-baseline gate.
- **LLM-as-judge pitfalls:** a judge with no rubric or anchored scale; pairwise comparisons in a single fixed order (position bias); the judge in the same model family as the system under test (self-preference); the judge's score trusted as independent validation.
- **RAG eval gaps:** only end-to-end generation eval and no separate retrieval eval (recall@k/precision@k/MRR/nDCG) on a labeled query-to-doc set; no grounding/faithfulness check that the answer is supported by retrieved context.
- **Dataset quality:** only happy-path cases, no negative/adversarial/refusal expectations; exact-match/substring scoring on open-ended generation; the eval set overlapping the few-shot examples or curated only from cases the system already passes.
- **Trajectory blindness:** agents evaluated only on final-answer text, with no assertion on which tools were called, in what order, or that the loop terminated.
- Paper controls to hunt: an `eval/` dir or RAGAS dependency that CI never runs (green because nobody runs it); a judge that emits scores while position and self-preference bias make them systematically wrong; structured-output mode trusted so the eval never schema-validates.

**Observability and Monitoring** (OBSERV) - *Owns: runtime telemetry, cost/latency/error visibility, and alerting. Distinct from EVAL: EVAL gates pre-deploy, OBSERV watches production.*
- **No per-call tracing:** raw SDK calls with no wrapper recording prompt, response, model, latency, and outcome; no tracing decorator or span.
- **No token/cost capture:** the `usage` block never read; cost estimated by `len(prompt)/4` instead of actual input/output/cache tokens; no per-tenant/feature/model attribution dimension.
- **No correlation:** in an agent/RAG/multi-agent flow, each call logged independently with no shared trace/request/conversation id threaded through child steps.
- **Sensitive data in logs:** full prompts and completions (with PII, retrieved docs, sometimes secrets) written to general logs or traces with no redaction and no retention/TTL (LLMSEC cross-references the disclosure).
- **Latency/error blindness:** latency only as a single mean (no p95/p99), errors collapsed to a generic string with no error type/status (a 429 storm indistinguishable from a timeout); no alerts on cost, error-rate, or latency.
- **Dead instrumentation:** an observability client constructed but never attached to the call; streaming spans opened and closed around the iterator so latency and tokens record as ~0; tracing "enabled" but sampled at ~0 in prod.
- **No quality/feedback loop:** no user-feedback signal (thumbs, accept/reject) joinable to the trace; no sampled production quality/drift monitoring.
- Paper controls to hunt: a `redact()` defined but never on the logging path; an alert whose channel is dead or whose threshold can never fire; a trace id generated at entry but never passed into child functions; a Langfuse/LangSmith handler built but never passed to the call.

**Retrieval, RAG, Indexing and Vector Search** (RAG) - *conditional; activate when embeddings or a vector store are present. Owns the embeddings lifecycle, chunking, index shape, retrieval quality, and grounding. Linkage, indexing, and search live here.*
- **Embedding-space mismatch:** documents and queries embedded with different models or output dimensions, so similarity is meaningless and retrieval silently returns near-random chunks. Centralize one pinned embedding model and dimension for both paths and store the version with the index.
- **Metric/normalization mismatch:** the index distance operator not matching the embedding's training metric (an L2 index queried with cosine), or vectors normalized on one side only.
- **No reindex/re-embed path:** edited or deleted source documents leaving stale vectors, or the embedding model bumped with no corpus re-embed and no version check.
- **Chunking defects:** fixed character/token slicing with no structure awareness and zero or token-level overlap; chunks larger than the embedding model's token limit.
- **No source linkage:** retrieved chunks concatenated with no source/page/chunk id carried into the prompt, so citations are unverifiable and provenance cannot be shown.
- **Retrieval quality:** pure dense retrieval for a corpus of exact identifiers/codes/acronyms with no lexical/BM25 channel and no rank fusion; a reranker imported but its order never used; top-k hardcoded to an extreme (over-retrieval blowing the window, or too small with no recall headroom); no relevance gate or empty-result branch, so the model answers from junk.
- **Tuning and asymmetry:** ANN parameters (nlist/nprobe, HNSW m/ef) left at low-recall defaults regardless of corpus size; query-vs-passage prefix/`input_type` asymmetry the model requires not applied or applied to both sides.
- **Ingestion trust:** arbitrary scraped/user-uploaded content embedded verbatim with no provenance, the indirect-injection and RAG-poisoning channel (LLMSEC owns the injection consequence; RAG owns provenance carried to retrieval). The per-tenant ACL filter is owned by LLMSEC; RAG requires it as defense in depth.
- **No retrieval eval:** no labeled query/relevant-chunk set and no recall/precision/RAGAS measurement gating changes to chunking, model, k, or index params.
- Paper controls to hunt: an `EMBEDDING_MODEL` constant read only by ingestion while the query path hardcodes another; a `hybrid`/BM25 path built but the retriever still calls only the vector path; rerank scores computed then discarded; a `score_threshold` of 0.0 that never filters; a reindex script in the repo wired into no deploy/cron.

**Agent and Tool Integration** (AGENT) - *conditional; activate when tool/function calling, an agent framework, or an MCP client is present. Owns tool definitions, loop control, autonomy, and tool execution boundaries.*
- **Thin tool schemas:** a one-line or empty tool `description` and bare `{"type":"string"}` parameters with no per-field description, `enum`, or `required` array, causing wrong-tool selection and hallucinated arguments. The description is the primary selection signal; constrain every field.
- **No loop bound:** a `while True:`/hand-rolled tool loop or an unset framework default with no `max_iterations`/`recursion_limit`/`max_turns`, so an oscillating agent runs until it exhausts budget or context; or the ceiling inflated to a huge number with no no-progress/oscillation detector (paying for the stuck behavior at higher cost).
- **Tool errors crash the loop:** exceptions propagating out instead of being returned as a structured `tool_result` with `is_error` (Anthropic) or a `role:"tool"` message with the matching id (OpenAI), so a recoverable 404 kills the run or a dangling tool-call id 400s the next request.
- **Unbounded tool output:** full HTTP bodies, whole files, or entire result sets concatenated back into context with no truncation or summarization, blowing the window and acting as an indirect-injection / context-poisoning channel.
- **Destructive tools ungated** (LLMSEC owns the security framing): delete/send/transfer/deploy/run-shell/file-write executed autonomously with no human approval and no dry-run; tools running with the app's full ambient privileges and no sandbox, egress allowlist, or path jail.
- **MCP supply chain:** MCP servers auto-loaded from unpinned/remote sources with tool descriptions trusted verbatim and no integrity check, exposing tool-poisoning, tool-shadowing, and rug-pull (a one-time approval with no re-verification on change).
- **Tool ambiguity and parallelism:** overlapping tool names/descriptions forcing the model to guess (thrashing); independent reads forced sequential, or state-mutating tools run in parallel with no ordering/locking.
- **Weak structured tool-calling:** regex/`split` parsing of prose for tool intent instead of native tool-call objects; tool arguments executed with no schema re-validation.
- **Multi-agent and memory:** unstructured fully-trusted handoffs and shared credentials across agents (insecure inter-agent communication, cascading failures); agent memory grown unbounded and replayed verbatim with no provenance or tenant scoping (memory poisoning).
- **Termination by absence only:** the loop ending only when no tool is called, with no goal/verification predicate, so the agent can stop with a hallucinated or unverified answer.
- Paper controls to hunt: a `max_tokens` treated as the loop guard; an `interrupt()`/approval helper defined but not on the destructive path (or default-false); a high `recursion_limit` plus a try/except that just logs the eventual error; a structured-output schema declared while args are still regex-extracted; a one-time MCP approval reloaded silently on every start.

### Phase 3 - Verify adversarially and cluster

- For each candidate, try to refute it: is there a guardrail, a schema validation, an authz check in code, a framework default, or a deliberate documented trade-off that neutralizes it? Is the agent actually wired to untrusted input and a dangerous tool? Is the model id actually an alias, or pinned in a config you have not read yet? Adjust or drop.
- Assign Severity, Confidence, and Effort (definitions below).
- Default to caution: if you could not confirm the data path, the exposure, or the control's absence by reading the code, mark it Suspected and say what would confirm it (a payload to inspect, a config value, an eval run, a request trace).
- Cluster repeated instances of one root problem into a single systemic finding, keeping the instance IDs as members, and apply the ownership map so a single defect does not fire under three dimensions.

### Phase 4 - Score

First decide which dimensions are **active** vs **N/A** based on the surfaces found in Phase 0. Score each active dimension 0-100 on how adequate the integration is for that lens (justified by its findings). The overall score is the weighted average of the active dimensions.

| Dimension | Weight | Applies |
|---|---|---|
| Security, Trust Boundaries, Safety and Data Governance (LLMSEC) | 17% | always |
| Prompt Construction and Context Management (PROMPT) | 12% | always |
| Model Selection, Configuration and Routing (MODEL) | 10% | always |
| Provider API and SDK Usage (APIUSE) | 10% | always |
| Reliability, Retries and Fallback (RELIABILITY) | 10% | always |
| Output Handling and Structured-Output Consumption (OUTPUT) | 8% | always |
| Cost, Quotas and Token Efficiency (COST) | 6% | always |
| Evaluation, Testing and Quality (EVAL) | 5% | always |
| Observability and Monitoring (OBSERV) | 5% | always |
| Latency and Throughput (SPEED) | 4% | always |
| Retrieval, RAG, Indexing and Vector Search (RAG) | 7% | if embeddings or a vector store exist |
| Agent and Tool Integration (AGENT) | 6% | if tool use or an agent loop exists |

**Conditional re-normalization:** when a conditional dimension is N/A (no retrieval surface, no agent/tool surface), drop it from the table and re-normalize the remaining weights to sum to 100 by proportional scaling (do not zero-and-keep, which would deflate the score). When both RAG and AGENT apply, the table already sums to 100. Report which dimensions were active vs N/A so the score is reproducible.

Score bands (per dimension and overall): 90-100 = A (exemplary), 80-89 = B (solid, minor issues), 70-79 = C (adequate, real gaps), 60-69 = D (weak, systemic problems), 0-59 = F (failing, critical deficiencies).

**Risk does not average away.** A single Critical finding caps its dimension at 69 and caps the overall at 79 until resolved. Treat severity independently of the weighted average. The following are **Critical regardless of the numeric score**: untrusted content (retrieved, tool, web, file) reaching the model with no isolation while the agent can take an external or destructive action (the lethal trifecta); model output flowing unvalidated into a code/SQL/HTML/shell/URL sink (improper output handling); a high-impact or irreversible tool callable with no human gate, or tools running with broad ambient credentials not scoped to the caller; authorization or a security rule enforced only by a prompt instruction; secrets or live credentials embedded in a prompt or sent to the provider; RAG retrieval with no per-tenant/ACL filter on a multi-tenant corpus; raw regulated PII/PHI sent to a provider with no minimization and no ZDR/DPA/BAA where required; an agent or tool loop with no iteration, token, or wall-clock bound on a reachable path; and an embedding-space mismatch that silently breaks retrieval correctness. **Security and data-loss floor:** any injection-to-sink, excessive-agency, prompt-leaked-secret, plaintext-PII-to-provider, or cross-tenant-retrieval critical caps the overall grade no matter how good the rest of the integration is, so a fast, cheap, well-evaluated agent that can be hijacked into deleting data or exfiltrating secrets cannot score well.

### Phase 5 - Prioritize

Definitions:
- **Severity** - Critical (injection-to-sink or hijack-to-action, data exfiltration, excessive agency, secret/PII disclosure, cross-tenant leakage, an unbounded loop on a reachable path, or silently-broken retrieval; act immediately) / High (a serious correctness, safety, reliability, or cost defect on a reachable or sensitive path; act this cycle) / Medium (a real weakness with preconditions or on a lower-value surface; schedule it) / Low (a minor best-practice or hygiene gap; batch it).
- **Confidence** - Confirmed (the data path and the control's absence are reproducible from the cited code) / Likely (strong evidence resting on a stated assumption about exposure, traffic, or runtime config) / Suspected (inferred without confirming reachability, real model behavior, or the control's absence; verify before acting, often needs a payload, a config value, an eval run, or a trace).
- **Effort** - S (a localized config/parameter/parse change, under ~1 hour) / M (a few files: a schema-and-validate pass, a retry/backoff layer, a cache placement, an approval gate, ~half a day) / L (an architectural change: dual-LLM isolation, an eval harness and CI gate, a re-embed migration, a routing layer, multiple days).

Bucket every finding: **Quick wins** (High/Critical, Confirmed, S), **Plan now** (High/Critical, M or L), **Verify first** (any Suspected, especially anything whose severity depends on real exposure, model behavior, or an eval), **Backlog** (Low). Order the "What to fix first" list as the union of Quick wins and Plan now, Critical before High, breaking ties toward findings that also close a systemic pattern or sit on the lethal-trifecta surface.

### Phase 6 - Write llmaudit.md

Write to `<codebase-root>/llmaudit.md` with these sections in order. Keep finding IDs stable using a dimension prefix and number: LLMSEC, PROMPT, MODEL, APIUSE, RELIABILITY, OUTPUT, COST, EVAL, OBSERV, SPEED, RAG, AGENT (for example `LLMSEC-001`).

1. **Title and banner** - project name; a line stating this is a read-only LLM-integration audit of the code as written, the date, that no model was called and the app was not run, and that the report is self-contained.
2. **Snapshot** - project, state (commit or branch), providers and SDKs, model ids and where they live, orchestration/agent and retrieval surfaces, structured-output/eval/observability wiring, the LLM usage paradigm, exposure and data sensitivity, size (prompt sites, call sites, tools, retrievers), audit coverage (exhaustive or sampled, with what was sampled), and exclusions.
3. **LLM data-flow and trust map** - the half-page map from Phase 1: entry points and untrusted-content sources, trust boundaries, sensitive assets and actions, the lethal-trifecta surfaces, models and budgets, and the highest-risk flows traced.
4. **Overall score** - `NN/100 - Grade X (label)`, a two-to-four sentence specific verdict, and a one-line calibration note (paradigm and assumed exposure). Then a scorecard table: Dimension, Score, Grade, Weight (after re-normalization), Active/N-A, one-line specific verdict; final row is the weighted overall. State which conditional dimensions were dropped and how weights were re-normalized.
5. **What to fix first** - the ordered priority list. Each line: `[ID] title - severity, effort - one-line why`.
6. **Strengths (preserve these)** - what the integration gets right, each with evidence. The acting agent must not remove these while fixing other issues.
7. **Systemic patterns (root causes)** - one entry per recurring root cause (no role separation anywhere; output `json.loads`-parsed with no schema; a floating alias across many files; no eval gate; no per-tenant retrieval filter), with the member finding IDs and the one root fix.
8. **Findings** - sorted by severity then dimension. Each finding is a self-contained block in this exact shape:

   ```
   ### [LLMSEC-001] <title>
   - Severity: <Critical/High/Medium/Low> | Confidence: <Confirmed/Likely/Suspected> | Effort: <S/M/L> | Dimension: <name> | Owner: <dimension or "this">
   - Location: `file:line` (prompt/model id/tool/retriever/call site, and other locations)
   - Evidence: <what the code does now, precisely, including the data path or source-to-sink chain>
   - Impact: <the concrete consequence: injection, exfiltration, wrong answer, outage, runaway cost, slow path, broken retrieval; and the blast radius / exposure>
   - Recommendation: <the specific change and the safe pattern in this project's SDK; not a platitude; no working exploit>
   - Verify the fix: <a payload to inspect, a request payload that should change, an eval to run, a count that should now be zero, or a check to run>
   - References: <OWASP LLM 2025 ID (e.g. LLM01:2025), OWASP Agentic ASI id, MITRE ATLAS id, NIST AI 600-1 category, or provider doc>
   - Related: <systemic pattern or finding IDs, or "none">
   ```

9. **Dimension notes** - one short subsection per active dimension tying the score to its findings, and a line for each N/A dimension saying why it was skipped.
10. **Remediation plan** - the four buckets (Quick wins, Plan now, Verify first, Backlog) listed by ID, with Plan now in suggested order.
11. **Scope and limitations** - what was and was not examined, sampling decisions, and which findings need a running model, real traffic, an eval run, or production config to confirm; plus the assumptions (paradigm, exposure, data sensitivity) that would change conclusions if untrue.
12. **How to use this report (for the acting agent)** - include this protocol verbatim:
    1. Triage by severity and confidence. Confirmed Critical and High are safe to act on now, in the order in "What to fix first". Re-verify any Suspected finding (and the real exposure) before changing anything.
    2. Fix root causes first; prefer the systemic pattern (a central prompt-assembly with role separation, one validated output layer, one pinned model config, one eval gate) over individual leaves.
    3. Preserve the strengths; do not remove a working guardrail, schema validation, retrieval filter, or approval gate while fixing another issue.
    4. Treat all model output and all retrieved/tool content as untrusted; fix at the boundary and the sink, not by editing the prompt to ask nicely.
    5. One finding, one change, verified: after each fix run its "Verify the fix" step; keep changes atomic and traceable to the finding ID. Re-run the eval suite (or add one) after any prompt or model change.
    6. Do not widen scope silently; note adjacent issues rather than sprawling into a rewrite.
    7. Re-run the audit to measure progress; confirm findings are resolved, not relocated, and watch for regressions in the strengths.

### Phase 7 - Report in chat

After the file is written, print a concise summary to the chat so the user sees the result without opening the file. Include, in this order:
- One headline line: `LLM integration audit complete: NN/100 (Grade X)` followed by the one-line verdict.
- The scorecard table (active dimensions plus the weighted overall; note any N/A dimensions).
- "What to fix first": the top three to five items, each `[ID] title - severity, effort`.
- Counts: number of findings by severity (for example `Critical 2, High 5, Medium 8, Low 6`).
- The path to the full report: `Full report: ./llmaudit.md`.
Keep it tight. The file holds the detail; the chat holds the verdict and the next actions.

---

## Quality gates (self-check before declaring done)

- Every finding cites at least one `file:line` and names the prompt, model id, tool, retriever, or call site. Run the substitution test on each title and impact line; rewrite anything that would read true for a different repo.
- Every finding states a concrete consequence and its blast radius (and, for injection or output-handling findings, the source-to-sink path), not just the presence of a pattern.
- Each finding is emitted by exactly one dimension per the ownership map; the same defect (a floating alias, an unbounded loop, a structured-output-but-regex-parsed call) does not appear and re-score under three lenses.
- Claims are verified against the actual code and request payload, not the prompt wording or a comment; a prompt-level "control" is reported as such.
- Paper controls were actively hunted, not just absences (a guardrail never called, a cache marker after a volatile prefix, `finish_reason` logged but unbranched, a retry predicate that misses 429, an ACL stored but never filtered, an eval never run in CI, a tracer never attached).
- Every dimension score has a justification tied to specific findings, conditional re-normalization is shown, and the risk caps and the security/data-loss floor were applied.
- Every finding has Severity, Confidence, and Effort set, and a reference (OWASP LLM 2025 / Agentic ASI / MITRE ATLAS / NIST AI 600-1 / provider doc).
- Every recommendation says what to change, the safe pattern in the project's own SDK, and how to verify it. No platitudes and no working jailbreak or exploit payload.
- Repeated issues are clustered into systemic patterns; there are not many near-identical findings left loose.
- Suspected findings are clearly marked with what would confirm them (a payload, a config value, an eval run, a trace).
- The data-flow/trust map and the Strengths section are present and evidence-backed; the paradigm and exposure calibration is stated.
- The report is at the codebase root, named exactly `llmaudit.md`, no model or embeddings endpoint was called, the app was not run, no source or index was changed, and the chat summary was printed.

## Notes

- Read-only and non-destructive. Use search and read tools to investigate, and shell commands only for inspection (listing files, counting prompts and call sites, reading manifests and lockfiles, checking version-control state). Do not call a model or an embeddings endpoint, run the application or its agents, execute prompts, connect to a vector store, run an eval against a live provider, or touch any live system.
- Reason about behavior, cost, and latency from the code; never call a model or measure a live system and never claim you did. Where a verdict depends on real model behavior, traffic, data volume, or an eval, mark it Suspected and say what would confirm it.
- Verify against the shipped request. The prompt wording, a comment, and the README state intent; the SDK call, its parameters, and the parse-and-sink code state reality. When they disagree, the gap is the finding.
- Calibrate to the paradigm and the blast radius. A local single-call summarizer is not held to the bar of an internet-facing agent with tools and money; spend the most effort on the lethal-trifecta surfaces, untrusted-content-to-action paths, output-to-sink chains, secrets and PII leaving the boundary, and cross-tenant retrieval.
- Keep model-id guidance principle-based: flag floating aliases vs pinned dated snapshots and deprecated vs active ids, and verify each against the provider's model-id and deprecation pages rather than hardcoding a list that will rot.
- For a large codebase, sample deliberately (the prompt-building code, the provider call sites, the tool and agent definitions, the retrieval and embedding code, the output-parsing code, and the eval and observability wiring) and declare exactly what you sampled.
- Cite the standard references where they help: the OWASP Top 10 for LLM Applications 2025 (LLM01 through LLM10) and the OWASP Top 10 for Agentic Applications (ASI01 through ASI10) from the OWASP GenAI Security Project; NIST AI 600-1 (Generative AI Profile) and the NIST AI RMF; MITRE ATLAS for adversary techniques; and the provider documentation (Anthropic, OpenAI, Google Gemini, and the Bedrock/Azure/Vertex wrappers) for prompt caching, structured outputs, stop reasons, model deprecations, and data retention, since many teams reference them directly.
