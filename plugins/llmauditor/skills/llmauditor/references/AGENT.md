# AGENT: Agent and Tool Integration

Weight 6. Active when tool calling, an agent framework, or an MCP client exists. Floor dimension: one Critical finding here holds the overall score at 69.
Owns: tool definitions, loop control, approval gates, tool error handling, tool output size, tool sandboxes, and MCP server supply chain.
Not here: the credential and identity tools act under (LLMSEC-R4); untrusted content steering the agent (LLMSEC-R1); tool arguments used unvalidated (OUTPUT-R5); prose parsed for tool intent (APIUSE-R2); declared tools never completed (APIUSE-R3); memory not scoped per user or tenant (LLMSEC-R7).
Standards: OWASP LLM06:2025, LLM10:2025, OWASP Agentic (ASI02, ASI04, ASI05, ASI08, ASI09); framework loop defaults in references/facts.md.
Read first: each tool definition and implementation, the loop that calls the model and runs tools (or the framework run call and its limits), and any MCP configuration.

## Cards

### AGENT-R1 Destructive or external-effect tool runs with no human approval (quick)
- Leads: `scan.sh AGENT-R1` lists tool functions and schemas that send, delete, pay, deploy, write, or run commands, and tool decorators.
- Confirm: a tool that sends messages, deletes or overwrites data, moves money, deploys, runs commands, or writes files executes as soon as the model calls it, with no approval step, dry run, or confirmation token; or approval defaults to yes, or is not on this tool's path; or the model freely chooses the destination (recipient, URL, account).
- Not a finding if: the action is reversible and low impact (read-only, or a draft a person sends); code enforces approval before execution (read the dispatcher, not the prompt); the server fixes the destination, such as the signed-in customer's own address.
- Severity: Critical when the path also reads untrusted content (retrieved documents, email, web, tool results) or the action is irreversible. High when only the signed-in user's own input reaches it.
- Fix: require human approval or a signed confirmation for irreversible and external tools, default to dry run, and bound each call (amount caps, recipient allowlists, server-chosen destinations).
- Verify the fix: a unit test that simulates a model call to the tool shows nothing executes until approval is recorded.
- Refs: OWASP LLM06:2025, ASI02, ASI09

### AGENT-R2 Agent or tool loop with no iteration, token, or time bound (quick)
- Leads: `scan.sh AGENT-R2` lists `while True` loops and framework loop limits.
- Confirm: a loop that calls the model repeatedly (a tool loop, a self-critique or refine loop) runs until the model stops asking for tools, with no iteration cap, cumulative token budget, or deadline; or a framework bound is set to None or to a huge value with no repeat detection; or only a per-call `max_tokens` is set, which bounds one call, not the loop. If AGENT was marked not applicable but such a loop exists, make AGENT active and say why in Scope and limitations.
- Not a finding if: a counter or deadline exits the loop (read it); the framework's default bound applies and is not overridden (facts.md).
- Severity: Critical when users or untrusted content can reach the loop (runaway spend, hung workers, repeated side effects). High on an internal batch path.
- Fix: an iteration cap, a cumulative token and cost budget, a deadline, and a repeated-call detector; at a bound, stop and return a clear partial result.
- Verify the fix: a unit test with a mocked model that always requests a tool shows the loop stops at the cap.
- Refs: OWASP LLM10:2025, LLM06:2025, ASI08

### AGENT-R3 Tool definitions too thin or overlapping to select correctly
- Leads: `scan.sh AGENT-R3` lists tool schemas and descriptions.
- Confirm: a tool has an empty or one-line description, bare string parameters with no field descriptions, enums, or required list, or overlaps another tool so the model must guess.
- Not a finding if: each tool says what it does and when not to use it, and every field is constrained.
- Severity: Medium. High when a wrong-tool call can act.
- Fix: describe each tool's purpose and limits, constrain every field, and merge or rename overlapping tools.
- Verify the fix: every schema field has a description and constraint, and the agent eval shows fewer wrong-tool calls.
- Refs: provider tool-use guides

### AGENT-R4 A tool error crashes the loop or breaks the conversation
- Leads: `scan.sh AGENT-R4` lists tool dispatch and tool-result construction.
- Confirm: exceptions from tools escape the loop instead of returning an error result (`tool_result` with `is_error`, or a `role: "tool"` message with the matching `tool_call_id`), so a recoverable failure ends the run, or a tool call left without a result makes the next request fail.
- Not a finding if: each call is wrapped and returns a structured error result with the matching ID.
- Severity: Medium. High when the agent runs unattended jobs.
- Fix: catch errors per tool call, return a structured error with the matching ID, and cap retries.
- Verify the fix: a test where a tool raises shows the next request carries an error result and the loop continues.
- Refs: provider tool-use guides

### AGENT-R5 Tool output returned to the model with no size limit
- Leads: `scan.sh AGENT-R5` lists raw bodies, file reads, and full result sets turned into tool results.
- Confirm: whole HTTP bodies, files, or query results go back into the context with no truncation, pagination, or summary.
- Not a finding if: tool results are capped and structured (fields, not raw bodies).
- Severity: Medium. High when the output carries third-party content on a path that can act (the injection itself is LLMSEC-R1).
- Fix: cap and summarize tool output, and return structured fields instead of raw bodies.
- Verify the fix: a test with a huge mocked tool response keeps the tool result under the cap.
- Refs: OWASP LLM10:2025

### AGENT-R6 Tool runs with the app's full privileges: no sandbox, path jail, or egress allowlist
- Leads: `scan.sh AGENT-R6` lists subprocess, file-write, sandbox, and egress settings.
- Confirm: a shell, code-execution, file, or fetch tool runs in the app's own process or host with no sandbox, no restriction to a working directory (so `..` escapes), and no egress allowlist.
- Not a finding if: the tool runs in an isolated sandbox with no secrets, no host filesystem, and restricted network (read the config).
- Severity: High when the tool runs code or commands or writes files. Medium for read-only file access in a fixed directory.
- Fix: run the tool in a sandbox (container, microVM, or hosted code execution), jail paths to a working directory, and allowlist egress hosts.
- Verify the fix: a test asks for a path outside the directory and a host off the allowlist and gets refusals.
- Refs: OWASP LLM06:2025, ASI05, CWE-22, CWE-250

### AGENT-R7 MCP servers loaded without pinning or change checks
- Leads: `scan.sh AGENT-R7` lists MCP server configuration and client code.
- Confirm: MCP servers start from unpinned runners (`npx -y package`, `uvx package`) or unlisted remote URLs, their tool descriptions are trusted verbatim, and a one-time approval is never re-checked when definitions change (tool poisoning, tool shadowing across servers, rug pull).
- Not a finding if: servers are pinned by version or hash, allowlisted, and tool definitions are diffed and re-approved on change.
- Severity: High when the agent holds private data or write tools. Medium otherwise.
- Fix: pin versions, allowlist servers, diff tool definitions on load with re-approval on change, and namespace tools per server.
- Verify the fix: the config shows pinned versions, and a changed fixture tool definition blocks loading until approved.
- Refs: ASI04, OWASP LLM03:2025

## Also check
- A loop that ends only when the model stops calling tools, with no goal or verification check, so it can finish on an unverified answer.
- Independent read-only tools forced to run one at a time, or state-changing tools run in parallel with no ordering or locking.
- Multi-agent handoffs passed as unstructured, fully trusted text, or agents sharing one credential (ASI07, ASI08).
- Agent memory that grows without bound and is replayed verbatim with no provenance (memory poisoning, ASI06).

## Paper controls (look protective, protect nothing)
- A per-call `max_tokens` treated as the loop guard.
- A `MAX_AGENT_STEPS` or `max_iterations` setting the loop never reads.
- An approval helper not on the destructive path, or defaulting to approve.
- A high `recursion_limit` plus a try/except that only logs the eventual error.
- A one-time MCP approval silently reloaded on every start with no check for changed tool definitions.
