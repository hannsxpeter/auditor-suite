# llmauditor

A read-only **LLM-integration audit** skill for AI coding agents. It audits how the codebase in the current working directory uses Large Language Models end to end (prompt construction and context, model selection and routing, provider API and SDK usage, reliability, security and trust boundaries, agents and tools, RAG and vector search, structured output, cost, speed, evaluation, and observability), writes a scored, prioritized, self-contained `llmaudit.md` at the repo root, then prints the verdict in chat. It works from the prompt templates, SDK calls, model and routing config, tool and agent definitions, retrieval code, and output-parsing code in the repo: it never calls a model, never runs the app or its agents, never connects to a vector store, and never mutates data or an index.

It is the AI-layer counterpart to `codeauditor` (code quality), `secauditor` (security), `dbauditor` (database), and `uxauditor` (user experience), and it is **dual-compatible**: the same `SKILL.md` runs in both Claude Code and Codex.

- In **Claude Code**: invoke with `/llmauditor`
- In **Codex**: invoke with `$llmauditor`

## What it audits

The audit is grounded in the current LLM-engineering and AI-security literature: the OWASP Top 10 for LLM Applications 2025 (LLM01 through LLM10) and the OWASP Top 10 for Agentic Applications (ASI01 through ASI10) from the OWASP GenAI Security Project, NIST AI 600-1 (the Generative AI Profile) and the NIST AI RMF, MITRE ATLAS for adversary techniques, and the provider documentation (Anthropic, OpenAI, Google Gemini, and the Bedrock/Azure/Vertex wrappers) for prompt caching, structured outputs, stop reasons, model deprecations, and data retention. It scores twelve dimensions, two of which are conditional on the project's surface:

| Dimension | Weight | Applies |
|---|---|---|
| Security, Trust Boundaries, Safety and Data Governance | 17% | always |
| Prompt Construction and Context Management | 12% | always |
| Model Selection, Configuration and Routing | 10% | always |
| Provider API and SDK Usage | 10% | always |
| Reliability, Retries and Fallback | 10% | always |
| Output Handling and Structured-Output Consumption | 8% | always |
| Cost, Quotas and Token Efficiency | 6% | always |
| Evaluation, Testing and Quality | 5% | always |
| Observability and Monitoring | 5% | always |
| Latency and Throughput | 4% | always |
| Retrieval, RAG, Indexing and Vector Search | 7% | if embeddings or a vector store exist |
| Agent and Tool Integration | 6% | if tool use or an agent loop exists |

Conditional dimensions (RAG and AGENT) are dropped and the remaining weights re-normalized when their surface is absent, so the score stays meaningful for a single-call summarizer and a tool-using autonomous agent alike.

These dimensions map directly onto the things teams ask about when they build with LLMs: best practices for prompting and provider APIs, right model selection and model switching, proper integration of agents and tools, reliability and speed, cost and token optimization, security and proper trust boundaries, and the linkage, indexing, and search that make retrieval work, plus the structured-output handling, evaluation, and observability that are easy to forget.

## How it works

The method runs in phases: orient and detect providers, SDKs, frameworks, retrieval and agent surfaces, and the usage paradigm; map the LLM data flow and trust boundaries (including the "lethal trifecta" of private data, untrusted content, and external action); analyze across every lens with `file:line` evidence and the data path; verify each candidate adversarially and cluster duplicates into systemic patterns; score with conditional re-normalization (a single Critical caps the dimension at 69 and the overall at 79, and a security or data-loss critical caps the overall grade outright); prioritize into Quick wins / Plan now / Verify first / Backlog; write `llmaudit.md`; and report the verdict in chat.

Two principles make it different from a linter:

- **It reads the shipped request, not the prompt's promise.** A system prompt that says "respond only with JSON" guarantees nothing if the call does not use a structured-output mechanism; an instruction "only access the current user's records" is not authorization; "do not hallucinate" is not grounding. The gap between the prompt's claim and the code is itself a finding.
- **It actively hunts paper controls.** A prompt-injection guardrail defined but never called before the request, a `cache_control` marker placed after a volatile timestamp so the cache never hits, `response_format` set to JSON while the output is still regex-parsed and never schema-validated, a retry wrapper whose `except` misses the SDK's `RateLimitError`, an ACL stored on every vector but never passed as a query filter, a `max_tokens` cap presented as the agent-loop bound, an eval suite committed but never run in CI, a tracing client constructed but never attached to the call: each looks protective and holds nothing.

Every finding is self-contained: an exact `file:line` and the data path (and, for injection and output-handling findings, the source-to-sink chain), the concrete consequence and its blast radius, a specific fix in the project's own SDK, a way to verify the fix, and a reference (OWASP LLM / Agentic, MITRE ATLAS, NIST AI 600-1, or a provider doc). An ownership map ensures each defect is scored by exactly one dimension instead of triple-counting across lenses.

## Install

The skill is a single `skills/llmauditor/SKILL.md`. Install it into whichever tool you use.

### Claude Code

As a personal skill:

```sh
mkdir -p ~/.claude/skills/llmauditor
cp skills/llmauditor/SKILL.md ~/.claude/skills/llmauditor/SKILL.md
```

Or install the whole repo as a Claude Code plugin (it ships a `.claude-plugin/plugin.json` manifest) via your plugin workflow, then invoke `/llmauditor`.

### Codex

```sh
mkdir -p ~/.codex/skills/llmauditor
cp skills/llmauditor/SKILL.md ~/.codex/skills/llmauditor/SKILL.md
```

Codex also reads skills from `~/.agents/skills/` and `.agents/skills/` (repo-local); any of these works. Invoke with `$llmauditor`, or run `/skills` to list.

## Usage

From the root of the project you want to audit:

- Claude Code: `/llmauditor` (optionally pass a subpath, a single feature, or one provider integration to scope the audit)
- Codex: `$llmauditor`

The skill writes `llmaudit.md` to the audited project's root and prints the score, scorecard, and top fixes in chat.

## Output

`llmaudit.md` is written for a reader with no memory of the audit (typically another agent that will fix the findings). It contains the snapshot, the LLM data-flow and trust map, the overall score and scorecard, "what to fix first", strengths to preserve, systemic root causes, the full findings, a remediation plan, scope and limitations, and a "how to use this report" protocol.

## License

MIT. See [LICENSE](LICENSE).
