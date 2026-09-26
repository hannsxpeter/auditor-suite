# OUTPUT: Output Handling and Structured-Output Consumption

Weight 8. Always active.
Owns: the shape contract of model output and its safe consumption: schema validation before use, extraction from text, parse and validation failure handling, schema strictness, tool-argument validation, and decisions taken on model-returned labels.
Not here: the stop reason checked before parsing (APIUSE-R1); JSON requested in prose when the output is validated (APIUSE-R2); output reaching code, SQL, shell, HTML, or URL sinks (LLMSEC-R2); access and safety decisions taken on model flags (LLMSEC-R3); provider errors swallowed (RELIABILITY-R5).
Standards: OWASP LLM05:2025, CWE-1426, CWE-20, provider structured-output guides (references/facts.md).
Read first: every `json.loads`, `JSON.parse`, regex, or split applied to model text, the schemas sent to the provider, and the tool-call dispatcher.

## Cards

### OUTPUT-R1 Model output parsed and used with no schema validation
- Leads: `scan.sh OUTPUT-R1` lists JSON parses and regexes applied to model text.
- Confirm: model text, or a JSON-mode response, is parsed with `json.loads`, `JSON.parse`, a regex, or `split`, and its fields are stored, branched on, or passed on with no Pydantic, Zod, or JSON Schema validation; enum and range fields are used without checking the allowed set; or casts such as `int(x)` or `as Type` hide bad values. This card also covers a missing native structured-output mechanism on the same call; do not file APIUSE-R2 for it.
- Not a finding if: a typed parse helper or validator checks the full schema before use and failures are handled (read it: `model_validate`, a Zod `parse`, the SDK's typed `parse`).
- Severity: High when the fields drive writes, money, routing, or other branching. Medium when they are only displayed.
- Fix: validate against a schema at the boundary (enums for closed sets, ranges, required fields), and turn on native structured output where the provider offers it.
- Verify the fix: a unit test feeds malformed and out-of-enum fixtures and gets a validation error, not a stored row.
- Refs: OWASP LLM05:2025, CWE-1426, CWE-20

### OUTPUT-R2 JSON extracted from free text by hand
- Leads: `scan.sh OUTPUT-R2` lists code-fence stripping, greedy brace regexes, and brace slicing.
- Confirm: code strips code fences by hand (`replace` or `split` on the three-backtick fence), runs a greedy `{.*}` regex, slices from the first `{` to the last `}`, or parses a partial stream buffer.
- Not a finding if: native structured output makes the extraction unnecessary and it is dead code.
- Severity: Medium. Low when a schema validator runs right after and failures are handled.
- Fix: native structured output so no extraction is needed; otherwise one tolerant extractor followed by schema validation.
- Verify the fix: tests with fenced, prefixed, and truncated fixtures either parse correctly or raise the validation error.
- Refs: provider structured-output guides

### OUTPUT-R3 Parse or validation failure swallowed or retried blind
- Leads: `scan.sh OUTPUT-R3` lists handlers for JSON and validation errors.
- Confirm: a parse or validation error becomes `None`, `{}`, or defaults that flow on as real data, or the call is retried with the identical prompt and no validation feedback, so the model has nothing new to correct.
- Not a finding if: the failure is raised or recorded as a failure the caller handles; a retry appends the validation error and is capped.
- Severity: High when the default is stored or drives a decision. Medium otherwise.
- Fix: surface the failure, retry at most a few times with the validation error appended, then fail explicitly.
- Verify the fix: a test with two mocked invalid responses asserts one feedback retry and then a typed failure.
- Refs: CWE-390

### OUTPUT-R4 Output schema too loose to guarantee the shape
- Leads: `scan.sh OUTPUT-R4` lists schemas, response formats, and Pydantic or Zod models.
- Confirm: the schema sent to the provider or used for validation leaves `additionalProperties` open, omits used fields from `required`, types everything as a string, has no enum for closed sets, or omits `strict` where the provider needs it for the guarantee; or `strict` is set on a schema strict mode does not support (rejected or partly ignored, depending on the provider).
- Not a finding if: the schema is tight for every field the code uses.
- Severity: Medium. High when a loose field drives a decision.
- Fix: tighten types, enums, `required`, and `additionalProperties: false`, and turn strict mode on.
- Verify the fix: the provider accepts the schema in strict mode, and validation rejects an extra or a missing field.
- Refs: provider structured-output guides (references/facts.md)

### OUTPUT-R5 Tool-call arguments used without checking the tool name and re-validating
- Leads: `scan.sh OUTPUT-R5` lists reads of tool-call arguments.
- Confirm: code reads `tool_calls[0].function.arguments` or a `tool_use` block's input without checking which tool was called, or passes the arguments on (for example `**args`) without validating them against that tool's own schema (types, ranges, allowed IDs).
- Not a finding if: a dispatcher looks up the tool by name, rejects unknown tools, and validates the arguments before the call (read it); the provider's strict tool mode guarantees the schema and the code relies only on schema-level facts.
- Severity: High when the tool writes or acts. Medium for read-only tools.
- Fix: dispatch by name, reject unknown tools, and validate the arguments with the tool's schema before running it.
- Verify the fix: a test sends an unknown tool name and a wrongly typed argument and gets error results, not a call.
- Refs: OWASP LLM05:2025, CWE-20

### OUTPUT-R6 A consequential decision rests only on a model-returned label or flag
- Leads: `scan.sh OUTPUT-R6` lists branches on model-returned fields such as approved, verdict, category, or priority.
- Confirm: code approves, refunds, merges, deletes, escalates, or routes work on a model-returned boolean or label with no corroboration (a rule check, a threshold on a validated score, a second signal, or human review).
- Not a finding if: the decision is advisory and a person confirms it; the label only sorts or tags. Access and safety decisions are LLMSEC-R3.
- Severity: High when it moves money or changes records. Medium otherwise.
- Fix: corroborate with deterministic checks, and send low-confidence or high-impact cases to review.
- Verify the fix: a test where the mocked model returns the approving label without the corroborating signal leaves the action undone.
- Refs: OWASP LLM09:2025

## Also check
- JSON parsed from a partial stream buffer before the stream ends (file under OUTPUT-R2).
- Numbers, dates, and IDs from model output used without a range or existence check (file under OUTPUT-R1).

## Paper controls (look protective, protect nothing)
- A prompt that says "respond ONLY with JSON" while the call runs in plain text mode.
- JSON mode treated as a schema guarantee; it guarantees syntax only.
- A Pydantic or Zod model defined but never applied to the response.
- An allowed-values constant (queues, categories) defined but never checked against the model's answer.
- `strict: true` set on a schema that strict mode does not support.
