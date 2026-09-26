# Answer key: llmauditor full-audit

Never copied into the eval workspace. Lines refer to files under repo/. Model facts were checked against the provider pages on 2026-09-26.

## Planted defects

| Grader | Location | Card | Expected severity | Defect |
|---|---|---|---|---|
| finds-kb-in-system-prompt | app/prompts.py:9-10 | LLMSEC-R1 | Critical | retrieved knowledge-base chunks, which include shoppers' community forum answers, are joined into the system prompt of an agent that can read the shopper's orders and send email to any address (the lethal trifecta) |
| finds-sql-from-model | app/insights.py:18-20 | LLMSEC-R2 | Critical | model-written SQL is executed on the app's own connection; the tenant rule exists only in the prompt (LLMSEC-R3 is also acceptable), so one tenant's admin can read every tenant's rows, admin API tokens, and customer session tokens |
| finds-email-tool-ungated | app/tools.py:54-62 | AGENT-R1 | Critical | `send_customer_email` sends at once to any recipient the model chooses, with no approval step, on a path that reads untrusted forum content |
| finds-agent-loop-unbounded | app/agent.py:20 | AGENT-R2 | Critical | `while True` tool loop reachable anonymously from the public widget; only per-call `max_completion_tokens` is set, and `MAX_AGENT_STEPS` (app/config.py:14) is never read |
| finds-triage-json-unvalidated | app/triage.py:31-34 | OUTPUT-R1 | High | JSON mode plus `json.loads`, then `priority` and `team` are written to the ticket with no schema or enum check |
| finds-retry-predicate | app/llm.py:6-10 | RELIABILITY-R2 | High | SDK retries are off (`max_retries=0`) and tenacity retries only the built-in `ConnectionError`, which the OpenAI SDK's rate-limit, timeout, connection, and server errors do not subclass, so nothing is ever retried |
| finds-retrieval-tenant | app/retrieval.py:17-24 | LLMSEC-R7 | Critical | vector search over the shared `kb_chunks` table has no `tenant_id` filter (the table holds every tenant's chunks, db/schema.sql:57-68), and the agent calls it without a tenant (app/agent.py:14) |
| finds-summary-cache-bust | app/summaries.py:16 | COST-R1 | High (Medium acceptable) | a timestamp starts the otherwise static system prompt (about 1,200 tokens of house style), so automatic prefix caching never hits on a few thousand calls a day; `prompt_cache_key` and the comment at line 6-7 claim caching |
| finds-model-alias | app/config.py:3 | MODEL-R1 | Medium | `gpt-5.4-mini` is an undated OpenAI alias (the dated snapshot is `gpt-5.4-mini-2026-03-17`); MODEL-R2 is acceptable if the provider has since deprecated it |
| finds-key-in-prompt | app/tracking.py:10 | LLMSEC-R5 | Critical | the live carrier API key is interpolated into the system prompt of the public tracking widget, and the model is told to pass it back as a tool argument |

## Decoys (safe; flagging them is a false positive)

| Grader | Location | Why it is safe |
|---|---|---|
| ignores-tagging | app/tagging.py:52 | `json.loads` is followed at once by `TicketTags.model_validate` (enum-typed tags, one to three); the request uses a strict JSON schema with an enum and `additionalProperties: false`; stop reason and refusal are checked; failures raise `TaggingFailed` |
| ignores-reports | app/reports.py:54-57 | the model only picks a key, constrained by a strict enum schema and the `ReportChoice` Literal; the SQL comes from the fixed `REPORT_SQL` map and `tenant_id` is bound from the admin session |

## Strengths worth naming

- Stop reasons handled and tool failures returned as `role: "tool"` messages with the matching `tool_call_id` (app/agent.py:24-33).
- `lookup_order` scoped by tenant and customer from the server session, never from model arguments (app/tools.py:43-51).
- Re-indexing deletes and re-inserts an article's chunks and stores `embedding_model` with each vector; one batched embedding function serves ingestion and queries (app/retrieval.py:5-14, app/embeddings.py:5-7).
- One module-level client with a 30-second timeout (app/llm.py:6).
- Closed-ticket summaries run as a background task after the response (app/main.py:68).
- Strict JSON schema plus Pydantic validation with typed failures (app/tagging.py:45-54, app/reports.py:48-55).

## Other true positives (not graded)

- COST-R3: the public widget endpoints have no per-tenant or per-visitor limit (app/main.py:45-52).
- SPEED-R1: the widget chat waits for the whole agent run with no streaming (app/main.py:45-47).
- EVAL-R1: no eval set or tests for triage, tagging, or the agent.
- OBSERV-R1 and OBSERV-R2: no tracing or usage capture around any model call (app/llm.py:15-16).
- OUTPUT-R5: tool arguments are passed with `**` straight from `json.loads` with no per-tool validation (app/tools.py:72, app/tracking.py:57).
- AGENT-R4: `track_shipment` errors propagate out of the tracking loop (app/tracking.py:39, 57).
- APIUSE-R1: the insights path uses the SQL text without checking the stop reason (part of the insights finding).
- RELIABILITY-R6: no fallback model or degraded answer for the widget.
- SPEED-R2: triage and tagging run one after the other (app/main.py:57-58).
- PROMPT-R2 on app/prompts.py:10 is the same bytes as the LLMSEC-R1 finding and should be filed once.
