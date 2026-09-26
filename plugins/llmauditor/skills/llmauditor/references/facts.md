# Facts: standards IDs and provider features

Last reviewed: 2026-09-26

These facts change often. Each entry gives the date it was checked and where to check it again. An entry marked "verify" could not be confirmed at review time; confirm it before a finding depends on it. If this review date is more than six months old, say in Scope and limitations that provider facts may be stale, and prefer Suspected for findings that rest on them.

Rules for using this file:
- Cite standards with their year or edition: `LLM05:2025`, `ASI02`, `CWE-1427`.
- Never call a model id current, deprecated, or retired from memory. Use the conventions and pages below; if you cannot check, say so and use Suspected.
- Examples of model ids here are dated examples, not a list of current models.

## OWASP Top 10 for LLM Applications

2025 edition (checked 2026-09-26; verify at https://genai.owasp.org/llm-top-10/). The cards cite these IDs.

| 2025 ID | Name | 2026 ID |
|---|---|---|
| LLM01:2025 | Prompt Injection | LLM01:2026 |
| LLM02:2025 | Sensitive Information Disclosure | LLM02:2026 |
| LLM03:2025 | Supply Chain | LLM04:2026 |
| LLM04:2025 | Data and Model Poisoning | LLM05:2026 |
| LLM05:2025 | Improper Output Handling | LLM10:2026 |
| LLM06:2025 | Excessive Agency | LLM03:2026 |
| LLM07:2025 | System Prompt Leakage | LLM08:2026 (renamed Hidden Context Exposure) |
| LLM08:2025 | Vector and Embedding Weaknesses | LLM09:2026 |
| LLM09:2025 | Misinformation | LLM07:2026 |
| LLM10:2025 | Unbounded Consumption | LLM06:2026 |

2026 edition published 2026-08-03 (checked 2026-09-26; verify at https://github.com/GenAI-Security-Project/GenAI-LLM-Top10 and https://genai.owasp.org/resource/owasp-genai-llm-top-10-2026/). Every 2025 entry carries over, but the order changed and the scope of some entries changed (verify the scope before mapping a finding). The mapping column is by name. In a report, cite the 2025 ID and add the 2026 ID in parentheses when the reader works from the 2026 list.

## OWASP Top 10 for Agentic Applications (2026 edition)

Published 2025-12-09 (checked 2026-09-26; verify at https://genai.owasp.org/resource/owasp-top-10-for-agentic-applications-for-2026/): ASI01 Agent Goal Hijack; ASI02 Tool Misuse (and Exploitation); ASI03 Identity and Privilege Abuse; ASI04 Agentic Supply Chain Vulnerabilities; ASI05 Unexpected Code Execution; ASI06 Memory and Context Poisoning; ASI07 Insecure Inter-Agent Communication; ASI08 Cascading Failures; ASI09 Human-Agent Trust Exploitation; ASI10 Rogue Agents.

## Other references

- CWE-1427 Improper Neutralization of Input Used for LLM Prompting (added in CWE 4.16, 2024-11-19) and CWE-1426 Improper Validation of Generative AI Output (added 2024). Checked 2026-09-26; verify at https://cwe.mitre.org/data/definitions/1427.html and /1426.html.
- MITRE ATLAS: AML.T0051 LLM Prompt Injection (AML.T0051.000 direct, AML.T0051.001 indirect), AML.T0056 LLM Meta Prompt Extraction, AML.T0057 LLM Data Leakage. ATLAS renames and adds techniques often; verify at https://atlas.mitre.org/techniques/.
- NIST AI 600-1, the Generative AI Profile of the AI RMF (2024-07-26). Its twelve risks include Confabulation, Data Privacy, Information Integrity, Information Security, Human-AI Configuration, and Value Chain and Component Integration. Verify at https://doi.org/10.6028/NIST.AI.600-1.

## Model ids: aliases, snapshots, and deprecation pages

Checked 2026-09-26.
- Anthropic: every Claude API model id is a pinned snapshot, including the dateless ids used from the 4.6 generation on. For older models, the undated alias is a pointer that resolves to a dated id (for example `claude-haiku-4-5` resolves to `claude-haiku-4-5-20251001`). Lifecycle: Active, Legacy, Deprecated, Retired, with at least 60 days' notice before retirement. Bedrock and Google Cloud set their own dates and ids. Verify at https://platform.claude.com/docs/en/about-claude/models/overview and https://platform.claude.com/docs/en/about-claude/model-deprecations.
- OpenAI: model pages list an undated alias and dated snapshots (`name-YYYY-MM-DD`); the alias can move to a newer snapshot, and `-latest` names such as `chat-latest` are updated regularly. Pin the dated snapshot for production. Verify at https://developers.openai.com/api/docs/models and https://developers.openai.com/api/docs/deprecations.
- Google Gemini: stable ids name a fixed model; preview ids can change and are deprecated with at least two weeks' notice; `-latest` aliases (`gemini-flash-latest`, `gemini-pro-latest`) are hot-swapped with each release; experimental ids are not for production. Verify at https://ai.google.dev/gemini-api/docs/models and https://ai.google.dev/gemini-api/docs/deprecations.
- Amazon Bedrock, Google Vertex AI, and Azure OpenAI or Foundry publish their own lifecycles (verify): https://docs.aws.amazon.com/bedrock/latest/userguide/model-lifecycle.html, https://cloud.google.com/vertex-ai/generative-ai/docs/learn/model-versions, https://learn.microsoft.com/azure/ai-foundry/openai/concepts/model-retirements.

Dated retirements and shutdowns (checked 2026-09-26 on the pages above):
- Anthropic: `claude-3-7-sonnet-20250219` and `claude-3-5-haiku-20241022` retired 2026-02-19; `claude-3-haiku-20240307` retired 2026-04-20; `claude-sonnet-4-20250514` and `claude-opus-4-20250514` retired 2026-06-15; `claude-opus-4-1-20250805` retired 2026-08-05.
- OpenAI: `chatgpt-4o-latest` shut down 2026-02-17; `gpt-3.5-turbo`, `gpt-4`, `gpt-4-turbo`, `o1-2024-12-17`, and `o3-mini-2025-01-31` shut down 2026-10-23; `gpt-5-2025-08-07`, `gpt-5-mini-2025-08-07`, and `o3-2025-04-16` shut down 2026-12-11.

## Stop reasons and refusals

Checked 2026-09-26.
- Anthropic `stop_reason`: `end_turn`, `max_tokens`, `stop_sequence`, `tool_use`, `pause_turn` (resend to continue a paused server-tool turn), `refusal` (with a `stop_details` object on newer models). Check the API reference for newer values. Verify at https://platform.claude.com/docs/en/api/messages.
- OpenAI Chat Completions `finish_reason`: `stop`, `length`, `tool_calls`, `content_filter`, and the deprecated `function_call`; a structured-output refusal arrives in `message.refusal`. The Responses API reports `status` (`completed` or `incomplete`) with `incomplete_details.reason` (for example `max_output_tokens` or `content_filter`) (verify). Verify at https://developers.openai.com/api/reference.
- Gemini `finishReason`: `STOP`, `MAX_TOKENS`, `SAFETY`, `RECITATION`, `LANGUAGE`, `OTHER`, `BLOCKLIST`, `PROHIBITED_CONTENT`, `SPII`, `MALFORMED_FUNCTION_CALL`; a blocked prompt sets `promptFeedback.blockReason` and returns no candidates. Verify at https://ai.google.dev/api/generate-content.

## Structured outputs

Checked 2026-09-26.
- OpenAI: `response_format` with `type: "json_schema"` and `strict: true` (Chat Completions), `text.format` (Responses), typed helpers `chat.completions.parse` and `responses.parse`. JSON mode (`type: "json_object"`) guarantees valid JSON syntax only, not the schema. Strict mode needs every property in `required` and `additionalProperties: false` (verify). Verify at https://developers.openai.com/api/docs/guides/structured-outputs.
- Anthropic: `output_config: {"format": {"type": "json_schema", "schema": ...}}` on `messages.create` (the older `output_format` request parameter is deprecated), `client.messages.parse()` validates into a typed model, and `strict: true` on a tool definition guarantees its inputs match the schema. Verify at https://platform.claude.com/docs/en/build-with-claude/structured-outputs.
- Gemini: `response_mime_type: "application/json"` with `response_schema` or `response_json_schema` (verify). Verify at https://ai.google.dev/gemini-api/docs/structured-output.

## Prompt caching

Checked 2026-09-26.
- Anthropic: explicit `cache_control: {"type": "ephemeral"}` breakpoints (at most four) or top-level automatic caching; 5-minute TTL by default, `"ttl": "1h"` optional; prefix order is tools, then system, then messages; the minimum cacheable prefix depends on the model (512 to 4096 tokens), and shorter prefixes silently do not cache; usage fields `cache_creation_input_tokens` and `cache_read_input_tokens`. Verify at https://platform.claude.com/docs/en/build-with-claude/prompt-caching.
- OpenAI: automatic for prompts of 1024 tokens or more, in 128-token steps; usage field `prompt_tokens_details.cached_tokens`; `prompt_cache_key` groups requests for cache routing; extended retention keeps prefixes up to 24 hours (verify the parameter name per model). Verify at https://developers.openai.com/api/docs/guides/prompt-caching.
- Gemini: implicit caching is on by default for 2.5 and later models, explicit caches via `client.caches.create` (`CachedContent`); usage field `cached_content_token_count`; minimum prefix about 1024 to 2048 tokens by model (verify). Verify at https://ai.google.dev/gemini-api/docs/caching.
- All providers: any byte change early in the prefix (a timestamp, UUID, unsorted JSON, per-user value) invalidates the cache from that point on.

## Output limits, sampling, and reasoning

Checked 2026-09-26.
- Anthropic: `max_tokens` is required. Claude Opus 4.7 and later reject non-default `temperature`, `top_p`, and `top_k` with a 400, and the Python SDK 1.x removed those parameters. `budget_tokens` (manual extended thinking) must be at least 1024 and below `max_tokens` on models that accept it; it is deprecated on Opus 4.6 and Sonnet 4.6 and rejected on later models, which use adaptive thinking and `output_config.effort`. Verify at https://platform.claude.com/docs/en/about-claude/model-deprecations and /build-with-claude/extended-thinking.
- OpenAI: Chat Completions uses `max_completion_tokens` (`max_tokens` is deprecated and rejected by reasoning models); the Responses API uses `max_output_tokens`. Reasoning models reject `temperature`, `top_p`, and penalty parameters (check per model). Reasoning depth: `reasoning_effort` (Chat Completions) or `reasoning.effort` (Responses). Verify at https://developers.openai.com/api/docs/guides/reasoning.
- Gemini: `max_output_tokens` in the generation config; thinking set through `thinking_config` (a token budget or a thinking level, depending on the model generation) (verify). Verify at https://ai.google.dev/gemini-api/docs/thinking.

## Errors, retries, and timeouts (SDK defaults)

- Anthropic SDKs (checked 2026-09-26): default timeout 10 minutes (seconds in Python, milliseconds in TypeScript); `max_retries` 2, retrying connection errors, 408, 409, 429, and 5xx; 529 `overloaded_error` is retryable. Typed errors include `RateLimitError`, `APIConnectionError`, `APITimeoutError`, `InternalServerError`, and `APIStatusError`. Verify at https://platform.claude.com/docs/en/api/errors.
- OpenAI SDKs: default read timeout 600 seconds and `max_retries` 2 (checked 2026-09-26); the retried statuses match Anthropic's list (verify). Typed errors include `RateLimitError`, `APIConnectionError`, `APITimeoutError`, and `InternalServerError`; they derive from the SDK's own base error, not Python's built-in `ConnectionError` (verify in the SDK's `_exceptions.py`). Verify at https://github.com/openai/openai-python.
- Gemini `google-genai`: errors `APIError`, `ClientError` (4xx, including 429), `ServerError` (5xx); automatic retries only when retry options are configured (verify). Verify at https://github.com/googleapis/python-genai.
- Honor `retry-after` when a provider sends it.

## Batch APIs

- Anthropic Message Batches: 50% of standard price, results within 24 hours (checked 2026-09-26). Verify at https://platform.claude.com/docs/en/build-with-claude/batch-processing.
- OpenAI Batch API: 50% discount, 24-hour completion window (verify). Verify at https://developers.openai.com/api/docs/guides/batch.
- Gemini Batch Mode: about 50% discount (verify). Verify at https://ai.google.dev/gemini-api/docs/batch-mode.

## Deprecated endpoints and SDK surfaces

Checked 2026-09-26.
- OpenAI Assistants API (`/v1/assistants`, `/v1/threads`, `client.beta.assistants`, `client.beta.threads`) shut down 2026-08-26; the replacement is the Responses API with the Conversations API. The Chat Completions API itself is not deprecated. The legacy Completions endpoint (`/v1/completions`), pre-1.0 module calls (`openai.ChatCompletion.create`, removed in openai-python 1.0 in 2023), and the `functions` and `function_call` parameters (replaced by `tools` and `tool_choice`) are legacy. Verify at https://developers.openai.com/api/docs/deprecations.
- Google's legacy SDKs `google-generativeai` (Python) and `@google/generative-ai` (JavaScript) reached end of support 2025-11-30; the replacements are `google-genai` and `@google/genai`. Verify at https://ai.google.dev/gemini-api/docs/libraries.
- Anthropic's legacy Text Completions API (`client.completions.create`, `HUMAN_PROMPT`, `AI_PROMPT`) does not serve current models and is removed from the Python SDK 1.x (verify); the `output_format` request parameter is deprecated in favor of `output_config.format`. Verify at https://platform.claude.com/docs/en/about-claude/model-deprecations.

## Provider data controls

- OpenAI (checked 2026-09-26): the Responses API stores responses by default (`store` defaults to true, 30-day application state); under an approved zero-data-retention agreement `store` is treated as false. `store=false` alone is not zero data retention. Chat Completions stores completions only when `store` is true (verify). Verify at https://developers.openai.com/api/docs/guides/your-data.
- Anthropic (checked 2026-09-26): some models require standard retention and return a 400 to organizations under zero data retention unless Anthropic authorizes them; check the model's page before assuming ZDR covers a path. Verify at https://platform.claude.com/docs/en/about-claude/models/overview.
- Gemini API: content sent on the unpaid tier may be used to improve Google products; paid-tier content is not (verify at https://ai.google.dev/gemini-api/terms).
- Azure OpenAI: abuse monitoring may retain prompts for up to 30 days unless modified abuse monitoring is approved (verify at https://learn.microsoft.com/azure/ai-foundry/openai/concepts/abuse-monitoring).

## Agent framework loop bounds

Defaults change by version; read the pinned version's docs. A default counts as a bound only when the code does not set it to None or to a huge number.
- LangGraph `recursion_limit` 25, raising `GraphRecursionError` (checked 2026-09-26; verify per version).
- OpenAI Agents SDK `max_turns` 10, raising `MaxTurnsExceeded`; `max_turns=None` disables it (checked 2026-09-26).
- LangChain `AgentExecutor.max_iterations` 15, with `max_execution_time` unset (verify).
- CrewAI `max_iter`: the default differs by version, 15 to 25 (verify).
- Vercel AI SDK: `generateText` with tools runs one step unless `stopWhen` or `maxSteps` allows more (verify).
- google-genai automatic function calling: `maximum_remote_calls` 10 (verify).

## Embeddings and vector search

- Query and document asymmetry (verify on each model card): Cohere `input_type` (`search_query`, `search_document`); Voyage `input_type` (`query`, `document`); Gemini `task_type` (`RETRIEVAL_QUERY`, `RETRIEVAL_DOCUMENT`); E5 models use "query: " and "passage: " prefixes; nomic-embed uses "search_query: " and "search_document: "; OpenAI `text-embedding-3` models take no input type.
- Vectors from different models, or from one model at different output dimensions (OpenAI `dimensions`, Gemini `output_dimensionality`), are not comparable.
- pgvector (verify at https://github.com/pgvector/pgvector): operators `<->` L2 distance, `<#>` negative inner product, `<=>` cosine distance, `<+>` L1; an index is used only when the query operator matches its operator class (`vector_l2_ops`, `vector_ip_ops`, `vector_cosine_ops`); HNSW `ef_search` defaults to 40 and IVFFlat `probes` to 1.

## Observability

- OpenTelemetry GenAI semantic conventions (`gen_ai.*` span attributes and metrics) were still marked in development at review time (verify at https://opentelemetry.io/docs/specs/semconv/gen-ai/).
