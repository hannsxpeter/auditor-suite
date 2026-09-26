# PROMPT: Prompt Construction and Context Management

Weight 12. Always active.
Owns: how prompts are assembled: role separation, what enters the privileged system or developer channel, the order of long context, where prompts live and how they are versioned, and the token budget of the assembled context.
Not here: whether untrusted text in a prompt is exploitable (LLMSEC-R1); secrets in prompts (LLMSEC-R5); volatile values that bust the prompt cache (COST-R1); JSON requested in prose (APIUSE-R2, OUTPUT-R1); model ids (MODEL-R1); the eval gate for prompt edits (EVAL-R3).
Standards: provider prompt-engineering guides (Anthropic, OpenAI, Google), OWASP LLM01:2025 as defense in depth, CWE-1427, Liu et al. 2023 "Lost in the Middle".
Read first: every function that builds a system prompt or a messages array, the prompt files or registry, and the code that appends chat history and retrieved context.

## Cards

### PROMPT-R1 Instructions, context, and the question collapsed into one string or message
- Leads: `scan.sh PROMPT-R1` lists prompts built as single interpolated strings and legacy `prompt=` calls.
- Confirm: durable instructions, examples, retrieved context, and the request are concatenated into one string or one user message, or earlier turns and tool results are pasted in as text instead of sent as real assistant and tool messages.
- Not a finding if: a framework template maps each part to its own role (read it, for example a system plus human template); the call is a one-off internal script with no user or third-party input.
- Severity: Medium. Low for internal scripts with fixed inputs.
- Fix: put durable instructions in the system or developer role, the request in the user role, earlier turns as real messages, and tool output as tool results.
- Verify the fix: the logged request has a system (or developer) entry with no per-request values, and user text appears only in user messages.
- Refs: provider prompt guides, OWASP LLM01:2025

### PROMPT-R2 User or retrieved text interpolated into the system or developer role
- Leads: `scan.sh PROMPT-R2` lists system prompts built with f-strings, template literals, or `.format`.
- Confirm: the system or developer prompt is built with values from user input, retrieved chunks, tool output, or database fields that users can write.
- Not a finding if: every inserted value is developer-controlled (config, enum, product name, a server-side tenant ID); the same bytes already back an LLMSEC-R1 finding (file it once, there, and cite this line in it).
- Severity: High when the value comes from users or third parties. Medium when it is a profile field only that user controls.
- Fix: keep the system prompt static, and move variable values into the user turn wrapped in labeled data delimiters.
- Verify the fix: rendering the system prompt for two different users and requests gives identical bytes.
- Refs: OWASP LLM01:2025, CWE-1427

### PROMPT-R3 Long documents placed after the question or buried mid-prompt
- Leads: no reliable pattern; read the builders that assemble long context (the `scan.sh LLMSEC-R1` leads show where chunks are joined).
- Confirm: on a path that sends long documents or many chunks, the documents come after the instructions and the question, or the most relevant chunk sits in the middle of a long block.
- Not a finding if: inputs are short; the order is documents first, then instructions, then the question.
- Severity: Medium when answers depend on long inputs. Low otherwise.
- Fix: put long documents first, then instructions, then the question, with the highest-ranked chunk at the start or the end of the context.
- Verify the fix: the rendered prompt has that order, and the eval for this path does not regress (EVAL).
- Refs: provider long-context guides, Liu et al. 2023

### PROMPT-R4 Prompts scattered across files with no registry or version
- Leads: `scan.sh PROMPT-R4` lists prompt literals such as "You are a".
- Confirm: the same or near-duplicate prompt text is inline in several files, or a prompt registry exists but call sites bypass it with literals, and no prompt name or version is recorded with each call.
- Not a finding if: prompts live in one module or directory and each call logs the prompt name and version.
- Severity: Medium when prompts drive user-facing output. Low otherwise.
- Fix: one registry (a module or prompt files) with named, versioned prompts, and the name and version logged with each call.
- Verify the fix: a search for prompt literals outside the registry returns nothing, and a trace shows the prompt version.
- Refs: none

### PROMPT-R5 Context assembled with no token budget
- Leads: `scan.sh PROMPT-R5` lists where history, messages, or memory grow.
- Confirm: full chat history, every retrieved chunk, whole documents, or whole tool outputs are appended with no count, window, truncation, or summary before the call.
- Not a finding if: a window or token count bounds each part (read it); inputs are bounded by construction.
- Severity: High when a user can push a user-facing request past the context window (hard failures) or grow its cost every turn. Medium otherwise.
- Fix: a token budget per part (a recent-turn window plus a summary, a top-k cap, per-document truncation), counted with the provider's token counter.
- Verify the fix: a test with 200 fake turns shows the request stays under the budget.
- Refs: OWASP LLM10:2025

## Also check
- Tool results or earlier assistant turns pasted into the user message as plain text (file under PROMPT-R1).
- Instructions in the system prompt that contradict per-call additions.
- Few-shot examples that contradict the instructions (examples copied from real customer data are LLMSEC-R6).

## Paper controls (look protective, protect nothing)
- A prompts module or registry that half the call sites bypass with inline strings.
- A "v2" prompt nothing references while live code sends a hardcoded literal.
- Delimiters (XML tags, triple quotes) treated as a security boundary; they are hygiene.
- A `summarize_history()` helper called only past a threshold the app never reaches.
