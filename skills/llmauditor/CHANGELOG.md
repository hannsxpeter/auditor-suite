# Changelog

All notable changes to llmauditor are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [auditor-suite 1.2.0] - 2026-10-01

Released with productauditor, the suite's eighth auditor. The cards now name
the product topics that moved to it, and the shared scripts pick leads more
fairly and gain fixes.

### Changed

- `SKILL.md`: the judgment notes hand model-call quotas a plan sells and
  invented output shown as real when no call failed to productauditor.
- `RELIABILITY.md`: the Not here line hands invented results shown as real
  output on a production path when no call failed to productauditor CLM-R7.
  RELIABILITY-R5 keeps a failed call turned into a silent default answer.
- `COST.md`: the Not here line hands model-call quotas that a plan sells to
  productauditor: a sold quota that nothing checks (ENT-R5), one set to
  another number (ENT-R4), and its unit, scope, and period (ENT-R6). COST-R3
  keeps spend limits with no plan term behind them, and its Not a finding if
  covers a sold quota for the endpoint that nothing enforces, so one missing
  check is filed once.
- `SKILL.md`: when a probe is wrong and you move a dimension between the
  Active and Not applicable lines, keep its reason in parentheses, for example
  `RAG (embeddings are used only to find duplicates)`; `check-report.sh` now
  requires one.
- `scan.sh`: when a card has more leads than `--max` (12 by default), it
  picks the ones it shows round-robin across files in path order (the first
  lead of each file, then the second of each, until the cap) and still prints
  them in path and line order. Before, it showed the first 12 in path order,
  so one file full of hits hid every file after it. `scan.sh --help` now
  explains `--max` and the selection.
- The scripts read an optional `SCAN_SKIP_RE` from `assets/skill.conf`, a
  regex of paths this auditor's scans and probes skip. llmauditor sets none, so
  the setting changes nothing here.
- Scans skip `productaudit.md`, the new auditor's report, as they skip the
  other reports.

### Fixed

- On macOS and with gawk, files such as `admin.js` and `admin.css` are no
  longer dropped from scans and probes as if they were minified bundles: the
  scripts now pass regexes to awk through `ENVIRON`, which keeps their
  backslashes.
- The file list leaves out symlinks, submodules, and tracked files that are
  deleted or outside a sparse checkout, so ripgrep and grep search the same
  files and no scan follows a link out of the project.
- Surface probes take their first hit in path and line order, so
  `inventory.sh` and `new-report.sh` cite the same hit on every run; ripgrep
  prints files in no fixed order.
- Reports are never written through a symlink, and the temporary file for a
  report write stays in the project, beside the report. `score.sh --write`
  keeps the report's permission bits and refuses a read-only report instead
  of replacing it.
- `check-report.sh` requires every dimension in exactly one of the Active and
  Not applicable lines (Not assessed in `only=` mode), with a reason in
  parentheses for each not-applicable dimension.
- Only the IDs after "Members:" count as systemic-pattern members, and CWE,
  CVE, and hash names (such as SHA-256) in a root fix or Related line are no
  longer read as finding IDs.
- `new-report.sh --mode only=` normalizes its list: spaces and empty items
  are dropped, and each ID is kept once.
- Leads no longer depend on the user's ripgrep config, `GREP_OPTIONS`, or
  locale.
- Projects inside a folder that an outer repository ignores are scanned.

## [auditor-suite 1.1.0] - 2026-09-26

Restructured so the skill works for small and local models as well as frontier
models. The audit knowledge is preserved; its shape changed.

### Changed

- `SKILL.md` is now a short spine (about 2,400 tokens, down from about 15,900):
  contract, modes, an eight-step workflow checklist, the dimension table, and
  judgment notes (the lethal trifecta, source to sink, code over prompt text,
  paper controls, static limits, calibration, model-id principles).
- Each lens's checklist became rule cards in `references/<DIM>.md`: where to
  look, how to confirm, when it is not a finding, severity, fix, and how to
  verify the fix. The twelve dimensions, their weights, and the conditional
  RAG and AGENT rules are unchanged.
- The security and data-loss floor is now enforced by marking LLMSEC and AGENT
  as floor dimensions: one Critical finding in either holds the overall score
  at 69.
- Scores are computed by `scripts/score.sh` from the findings, so re-runs are
  comparable; Suspected findings count half and never cap a score.
- Findings drop the `Owner` field (the ID prefix is the owning dimension) and
  must quote the cited code in Evidence; `check-report.sh` verifies it.
- Model-id guidance stays principle-based; provider naming conventions (which
  ids are aliases and which are pinned snapshots) now live in a dated facts
  file instead of the prompt.

### Added

- Modes: `quick` (the ten Critical-class cards, no score), `only=DIM,DIM`, and
  a path scope.
- Read-only scripts: `inventory.sh`, `scan.sh`, `new-report.sh`, `score.sh`,
  `check-report.sh`, driven by `assets/` tables (93 search patterns that
  compile under grep and ripgrep, and surface probes for the LLM surface, RAG,
  and AGENT).
- `references/facts.md`: dated facts with verify-at links, including the OWASP
  LLM Top 10 2025 IDs mapped to the 2026 edition (published 2026-08-03), the
  OWASP Top 10 for Agentic Applications, provider model-id conventions and
  recent retirements, stop reasons, structured outputs, prompt caching, SDK
  timeout and retry defaults, deprecated endpoints (including the Assistants
  API shutdown on 2026-08-26), and agent-framework loop defaults.
- `references/example-report.md` (validated in CI against
  `tests/fixtures/llmauditor/`) and an eval case under `evals/llmauditor/`: a
  multi-tenant helpdesk copilot with ten planted defects and two decoys.
- Card detail for checks that were implicit before: user or tenant IDs taken
  from tool arguments (LLMSEC-R4), destinations the model chooses freely, such
  as email recipients (AGENT-R1), SDK error classes that do not subclass
  Python's built-in `ConnectionError` (RELIABILITY-R2), and a pgvector query
  operator that does not match the index operator class, so the index is
  skipped (RAG-R2).

### Fixed

- Overlaps between lenses now have one owner each, so one defect is filed
  once: the stop reason is APIUSE-R1 (a mishandled stop reason is a RELIABILITY
  check); unvalidated parsing is OUTPUT-R1, which also covers the missing
  native structured-output mechanism (APIUSE-R2 keeps prose tool intent and
  validated calls); the missing cache mechanism is APIUSE-R4 and the busted
  cache is COST-R1; model tier for cost or latency is MODEL-R6; output caps
  are MODEL-R5; the Batch API is COST-R2; unbounded history is PROMPT-R5;
  usage capture and cost attribution are OBSERV-R2; timeouts and fan-out
  limits are RELIABILITY-R1 and RELIABILITY-R6; sync clients in async code and
  buffered streams are SPEED-R3 and SPEED-R1; embedding mismatch and
  deprecation are RAG-R1 and RAG-R3; retrieval evals are EVAL-R5; tool-argument
  validation is OUTPUT-R5; security decisions on model flags are LLMSEC-R3 and
  correctness decisions OUTPUT-R6; secrets and personal data in LLM logs are
  LLMSEC-R5 and LLMSEC-R6.

## [auditor-suite 1.0.0] - 2026-07-14

Moved into the [auditor-suite](https://github.com/hannsxpeter/auditor-suite)
monorepo as `skills/llmauditor/`, with the standalone repo's full git history
preserved. Standalone versioning is retired; the skill now follows the
auditor-suite release train.

### Changed
- The standalone `.claude-plugin/plugin.json` manifest is retired; plugin
  packaging now lives in the hub under `plugins/llmauditor/`.
- The audit content in `SKILL.md` is unchanged from standalone 0.1.0.

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

[0.1.0]: https://github.com/hannsxpeter/llmauditor/releases/tag/v0.1.0
