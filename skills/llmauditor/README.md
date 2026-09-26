# llmauditor

A read-only **LLM-integration audit** skill for AI coding agents, part of the [auditor-suite](../../README.md). It audits how the codebase in the current directory uses large language models end to end, writes a scored, prioritized, self-contained `llmaudit.md` at the project root, and prints the verdict in chat. It never calls a model or an embeddings endpoint, never runs the app or its agents, never connects to a vector store, and never changes data or an index.

- Claude Code: `/llmauditor`
- Codex: `$llmauditor`
- Other Agent Skills harnesses: the harness's native skill invocation

## What it audits

Twelve dimensions, grounded in the OWASP Top 10 for LLM Applications (2025 IDs, mapped to the 2026 edition), the OWASP Top 10 for Agentic Applications, NIST AI 600-1, MITRE ATLAS, CWE-1426 and CWE-1427, and the provider documentation for stop reasons, structured outputs, prompt caching, deprecations, and data retention.

| ID | Dimension | Weight | Active when |
|---|---|---|---|
| LLMSEC | Security, Trust Boundaries, Safety and Data Governance | 17 | always |
| PROMPT | Prompt Construction and Context Management | 12 | always |
| MODEL | Model Selection, Configuration and Routing | 10 | always |
| APIUSE | Provider API and SDK Usage | 10 | always |
| RELIABILITY | Reliability, Retries and Fallback | 10 | always |
| OUTPUT | Output Handling and Structured-Output Consumption | 8 | always |
| COST | Cost, Quotas and Token Efficiency | 6 | always |
| EVAL | Evaluation, Testing and Quality | 5 | always |
| OBSERV | Observability and Monitoring | 5 | always |
| SPEED | Latency and Throughput | 4 | always |
| RAG | Retrieval, RAG, Indexing and Vector Search | 7 | embeddings or a vector store exist |
| AGENT | Agent and Tool Integration | 6 | tool calling, an agent framework, or an MCP client exists |

Weights re-normalize over the active dimensions, so a single-call summarizer and a tool-using agent are each scored only on what they have. LLMSEC and AGENT are floor dimensions: one Critical finding in either (injection that reaches an action or a sink, excessive agency, a secret or personal data sent to the provider, cross-tenant retrieval, an unbounded agent loop) holds the overall score at 69.

Two principles set it apart from a linter:

- **It reads the request the code sends, not what the prompt promises.** "Respond only with JSON" guarantees nothing without a structured-output mechanism and validation; "only show the user's own records" is not authorization.
- **It hunts paper controls**: a guardrail whose verdict is logged but never blocks, a cache breakpoint after a volatile timestamp, a retry that misses the SDK's rate-limit error, an ACL stored on vectors but never filtered on, `max_tokens` presented as the agent-loop bound, an eval never run in CI.

## Modes

- `/llmauditor` or `/llmauditor full`: every active dimension and every card.
- `/llmauditor quick`: only the ten Critical-class cards; no numeric score. A good first pass for small models or large repos.
- `/llmauditor only=LLMSEC,AGENT`: a subset of dimensions with a partial score.
- `/llmauditor src/agents` (or `quick src/agents`): limit the audit to a path.

## How it works

The skill is a short procedural spine (`SKILL.md`, about 2,400 tokens) plus files it reads only when a step needs them. The model does the judgment (reading code, confirming or refuting each lead, choosing severity); the scripts do the bookkeeping, so the same findings always produce the same score.

| Script | What it does |
|---|---|
| `scripts/inventory.sh` | Maps languages, manifests, and entry points, probes for the LLM surface, and decides whether RAG and AGENT apply. |
| `scripts/scan.sh <DIM\|CARD\|quick\|all>` | Turns rule cards into leads: lines worth reading, never findings by themselves. |
| `scripts/new-report.sh --mode <mode>` | Writes the `llmaudit.md` skeleton with the active dimensions filled in. |
| `scripts/score.sh --write \| --chat` | Computes every score, cap, and remediation bucket from the findings; prints the chat summary. |
| `scripts/check-report.sh` | Validates the report: sections, finding fields, that every cited `path:line` exists and holds the quoted code, and that every card was worked. |

Every script only reads, except `new-report.sh` and `score.sh --write`, which write only `llmaudit.md`. The scripts, `references/protocol.md`, and `assets/report-template.md` are vendored from the hub's `shared/` folder; edit them there.

## Files

```
SKILL.md                     the spine: contract, modes, workflow, dimension table, judgment notes
references/protocol.md       shared rules: evidence, finding format, severity, confidence, scoring
references/<DIM>.md          rule cards for each of the twelve dimensions (69 cards, 10 tagged quick)
references/facts.md          dated provider and standards facts, each with a verify-at link
references/example-report.md a complete report of tests/fixtures/llmauditor/ that passes check-report.sh
assets/skill.conf            names and sentences the scripts use
assets/dimensions.tsv        dimensions, weights, conditional and floor flags
assets/patterns.tsv          search patterns behind scan.sh (grep -E and ripgrep compatible)
assets/surfaces.tsv          probes for the LLM surface, RAG, and AGENT
assets/report-template.md    the report skeleton
scripts/                     the shared read-only scripts above
```

Each card in `references/<DIM>.md` says where to look, what confirms the defect, when it is not a finding, how severe it is under which conditions, the fix, and how to verify the fix. Each dimension file also lists what belongs to other dimensions ("Not here"), so every defect has exactly one owning card, and the paper controls to hunt. `references/facts.md` carries the facts that move fastest (OWASP IDs, model-id conventions, deprecations, stop reasons, caching and structured-output features, SDK defaults); check its review date before relying on it.

## Install

Use the hub installer or the plugin marketplace; see the [suite README](../../README.md#install). A manual install must copy or link the whole skill directory (`SKILL.md`, `references/`, `scripts/`, `assets/`), not just `SKILL.md`.

## Output

`llmaudit.md` is written for a reader with no memory of the audit, typically another agent that will fix the findings: snapshot, the LLM data-flow and trust map (including lethal-trifecta surfaces), score and scorecard, what to fix first, strengths to preserve, systemic root causes, findings with `path:line` evidence and a way to verify each fix, dimension notes, a remediation plan, scope and limitations, and a protocol for the acting agent.

## Evals

`evals/llmauditor/full-audit/` holds a multi-tenant helpdesk copilot (FastAPI, OpenAI SDK, pgvector) with ten planted defects, six of them Critical-class, and two decoys; `bash scripts/eval.sh llmauditor` runs it with a no-skill baseline. See the hub's `evals/README.md`.

## License

MIT. See [LICENSE](LICENSE).
