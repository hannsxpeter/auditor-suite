# Changelog

All notable changes to llmauditor are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-06-18

First release.

### Added
- The `llmauditor` skill: a read-only audit of how a codebase integrates Large
  Language Models that writes a scored, prioritized `llmaudit.md` and then prints
  the verdict in chat. Dual-compatible: the same `SKILL.md` runs in Claude Code
  (`/llmauditor`) and Codex (`$llmauditor`).
- Twelve analysis dimensions, two of them conditional on the project's surface:
  Security, Trust Boundaries, Safety and Data Governance (LLMSEC); Prompt
  Construction and Context Management (PROMPT); Model Selection, Configuration
  and Routing (MODEL); Provider API and SDK Usage (APIUSE); Reliability, Retries
  and Fallback (RELIABILITY); Output Handling and Structured-Output Consumption
  (OUTPUT); Cost, Quotas and Token Efficiency (COST); Evaluation, Testing and
  Quality (EVAL); Observability and Monitoring (OBSERV); Latency and Throughput
  (SPEED); Retrieval, RAG, Indexing and Vector Search (RAG, conditional); and
  Agent and Tool Integration (AGENT, conditional).
- Explicit scoring rubric with per-dimension weights, conditional re-normalization,
  score bands, and a rule that a single Critical finding caps the dimension and the
  overall score, with a security and data-loss floor that caps the overall grade.
- An ownership map that assigns each cross-lens defect (floating model alias,
  unbounded agent loop, structured-output-but-regex-parsed, RAG access control)
  to exactly one dimension so findings are not triple-counted.
- A seven-phase method: orient and detect surfaces; map the LLM data flow and
  trust boundaries (including the lethal-trifecta surface); analyze across every
  lens with `file:line` evidence; verify adversarially and cluster; score;
  prioritize into Quick wins / Plan now / Verify first / Backlog; and write the
  report, then summarize in chat.
- Self-contained findings (Severity, Confidence, Effort, Location, Evidence,
  Impact, Recommendation, Verify-the-fix, References, Related) grounded in the
  OWASP Top 10 for LLM Applications 2025, the OWASP Top 10 for Agentic
  Applications, NIST AI 600-1, MITRE ATLAS, and provider documentation, written
  so another agent can act on them with no prior context.
- Project documentation: README, LICENSE, this changelog, and a
  `.claude-plugin/plugin.json` manifest.

[0.1.0]: https://github.com/aihxp/llmauditor/releases/tag/v0.1.0
