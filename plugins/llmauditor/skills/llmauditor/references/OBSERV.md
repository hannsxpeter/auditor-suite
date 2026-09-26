# OBSERV: Observability and Monitoring

Weight 5. Always active.
Owns: runtime telemetry for model calls: per-call traces, token and cost capture and attribution, correlation across steps, latency and error metrics with alerts, instrumentation that is actually attached, and production quality feedback.
Not here: secrets or personal data in prompts and completions written to logs, and log retention (LLMSEC-R5, LLMSEC-R6, LLMSEC-R8); swallowed errors (RELIABILITY-R5); pre-release evals (EVAL).
Standards: OpenTelemetry GenAI semantic conventions (references/facts.md), NIST AI RMF (Manage).
Read first: the model-call wrapper, the logging and tracing setup, and every place the response's usage fields are read.

## Cards

### OBSERV-R1 Model calls leave no trace of model, prompt version, latency, and outcome
- Leads: `scan.sh OBSERV-R1` lists tracing and LLM-observability setup.
- Confirm: model calls run with no wrapper, span, decorator, or callback that records the model, prompt name or version, latency, token usage, outcome, and the provider request ID.
- Not a finding if: one client wrapper or instrumentation library records these for every call (read it).
- Severity: Medium. High for an agent or customer-facing feature in production whose failures cannot be diagnosed.
- Fix: one wrapper, or OpenTelemetry GenAI instrumentation, around every model call.
- Verify the fix: a local run with a mocked client emits one span or log record per call with those fields.
- Refs: OpenTelemetry GenAI semantic conventions

### OBSERV-R2 Token usage and cost not captured or attributable
- Leads: `scan.sh OBSERV-R2` lists reads of usage fields and token estimates.
- Confirm: the response's usage block is never read; cost is estimated from `len(prompt) / 4` instead of the reported tokens; cached and reasoning tokens are ignored; or usage is recorded without the tags needed to attribute it (user or tenant, feature, model).
- Not a finding if: a gateway or observability tool records usage with those tags (read its config).
- Severity: Medium. High when spend is material and cannot be attributed.
- Fix: record input, output, cached, and reasoning tokens from the usage block on every call, tagged with user or tenant, feature, and model, and derive cost from the price table.
- Verify the fix: one call in a local run with a mocked client produces a usage record with all tags.
- Refs: provider usage fields (references/facts.md)

### OBSERV-R3 No shared trace or request ID across the steps of one request
- Leads: `scan.sh OBSERV-R3` lists trace, request, and conversation IDs.
- Confirm: in an agent, RAG, or multi-agent flow, each model, tool, and retrieval call is logged on its own with no trace, request, or conversation ID threaded through the child steps, or an ID created at the entry point is never passed down.
- Not a finding if: a span context or context variable carries the ID to every child call (read how it propagates).
- Severity: Medium.
- Fix: create the trace at the entry point and pass it (span context or context variable) into every child call.
- Verify the fix: one request in a local run produces log lines that all carry the same trace ID.
- Refs: OpenTelemetry context propagation

### OBSERV-R4 Latency and errors not measured in a way that can alert
- Leads: `scan.sh OBSERV-R4` lists metrics, alerting, and error logging.
- Confirm: model-call latency is not recorded, or only as an average (no p95 or p99); errors are collapsed into one generic message with no error type, status code, or request ID, so a 429 storm looks like a timeout; or the repo defines metrics that no alert rule uses.
- Not a finding if: each call emits its latency and error type with the request ID (as metrics or structured logs) and alerting lives outside the repo; say so in Scope and limitations.
- Severity: Medium.
- Fix: latency histograms, error type and status as labels, and alerts with an owner for cost, error rate, and latency.
- Verify the fix: the metrics endpoint exposes the histogram, and an alert rule references it.
- Refs: none

### OBSERV-R5 Instrumentation built but not attached
- Leads: `scan.sh OBSERV-R5` lists callback handlers, tracer providers, instrumentors, and sample rates.
- Confirm: a Langfuse, LangSmith, Helicone, or OpenTelemetry client or callback handler is built but never passed to the calls (no callbacks argument, no proxy base URL, instrumentor never run); streaming spans close when the iterator is created, so latency and tokens record as near zero; or tracing is on but sampled at about zero in production.
- Not a finding if: the handler is attached on every call path (read the call sites).
- Severity: Medium. High when the team relies on it for incidents on this path.
- Fix: attach the handler on every call path, end streaming spans at the final chunk, and set a real sample rate.
- Verify the fix: a local run shows spans for each call with non-zero duration and tokens.
- Refs: none

## Also check
- No user-feedback signal (thumbs, accept or reject) that can be joined to the trace, and no sampled review of production outputs for quality or drift.
- Prompt and model versions missing from traces, so a regression cannot be tied to a change.

## Paper controls (look protective, protect nothing)
- A trace ID generated at the entry point but never passed into child functions.
- A Langfuse or LangSmith handler built but never passed to the call.
- An alert whose channel is dead or whose threshold can never fire.
- Tracing "enabled" with a production sample rate of about zero.
