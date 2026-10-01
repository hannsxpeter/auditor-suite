# codeauditor

A read-only **code audit** skill for AI coding agents, part of the [auditor-suite](../../README.md). It audits the whole codebase in the current directory, writes a scored, prioritized, self-contained `codeaudit.md` at the project root, and prints the verdict in chat. It never edits source and never runs the project, its tests, or its builds.

- Claude Code: `/codeauditor` (or ask "audit this codebase")
- Codex: `$codeauditor`
- Other Agent Skills harnesses: the harness's native skill invocation

## What it audits

Nine dimensions, all always active, so every codebase is scored on all nine. Security is a survey of the highest-signal checks; run [secauditor](../secauditor) for depth, and dbauditor, llmauditor, seoauditor, uiauditor, uxauditor, or productauditor for their layers. codeauditor keeps developer docs, dead code, duplicated logic, non-plan guards, per-environment config, and operator telemetry; customer-facing claims, plan gates and the plan catalog, flag behavior, analytics keys, and product telemetry belong to [productauditor](../productauditor). The suite map is in [SUITE.md](../../SUITE.md).

| ID | Dimension | Weight | Cards |
|---|---|---|---|
| SEC | Security | 20 | 8 |
| ARC | Architecture and Design | 15 | 8 |
| QUAL | Code Quality and Maintainability | 15 | 6 |
| TEST | Testing and Verification | 15 | 5 |
| ERR | Error Handling and Resilience | 10 | 6 |
| PERF | Performance and Efficiency | 8 | 5 |
| DEP | Dependencies and Supply Chain | 7 | 6 |
| DOC | Documentation and Drift | 5 | 4 |
| OBS | Observability and Operability | 5 | 7 |

The weights are fixed; `score.sh` applies them as written.

## Modes

- `/codeauditor` or `/codeauditor full`: every dimension and every card.
- `/codeauditor quick`: only the Critical-class cards (13 of 55); no numeric score. A good first pass for small models or large repos.
- `/codeauditor only=SEC,ERR`: a subset of dimensions with a partial score.
- `/codeauditor src/api` (or `quick src/api`): limit the audit to a path.

## How it works

The skill is a short procedural spine (`SKILL.md`) plus files it reads only when needed:

- `references/protocol.md`: the shared rules for evidence, the finding format, severity, confidence, scoring, and finishing.
- `references/<DIM>.md`: one file of rule cards per dimension (`SEC.md`, `ARC.md`, `QUAL.md`, `TEST.md`, `ERR.md`, `PERF.md`, `DEP.md`, `DOC.md`, `OBS.md`). Each card says where to look (a `scan.sh` lead or the files to read), how to confirm the defect, when it is not a finding, the severity, the fix, and how to verify the fix. Every dimension also lists its paper controls: code that looks protective and does nothing, such as a catch that swallows the error or a health check that checks nothing.
- `references/example-report.md`: a complete report of the small project in `tests/fixtures/codeauditor/`, validated on every lint run, as a format anchor.
- `references/facts.md`: dated facts (HTTP client timeout defaults, async error behavior, runtime end-of-life dates, deprecated packages and APIs) with a review date.
- `scripts/`: read-only helpers shared by the suite. `inventory.sh` maps the project and its size; `scan.sh` turns cards into `path:line` leads using `assets/patterns.tsv`; `new-report.sh` writes the report skeleton; `score.sh` computes every score from the findings; `check-report.sh` validates the report, including that every cited `path:line` exists and that code quoted in Evidence appears within 6 lines of the first cited location.
- `assets/`: the report template and the tables the scripts read (`skill.conf`, `dimensions.tsv`, `patterns.tsv`, `surfaces.tsv`).

The model does the judgment (reading code, confirming or refuting each lead, choosing severity); the scripts do the bookkeeping. Scores are deterministic: the same findings always produce the same score, so re-running the audit after fixes measures progress.

## Install

Use the hub installer or the plugin marketplace; see the [suite README](../../README.md#install). A manual install must copy or link the whole skill directory (`SKILL.md`, `references/`, `scripts/`, `assets/`), not just `SKILL.md`.

## Output

`codeaudit.md` is written for a reader with no memory of the audit, typically another agent that will fix the findings: snapshot, architecture map (modules, layers, state, integrations, and two or three flows traced with `path:line`), score and scorecard, what to fix first, strengths to preserve, systemic root causes, findings with quoted `path:line` evidence and a way to verify each fix, dimension notes, a remediation plan, scope and limitations, and a protocol for the acting agent.

## Evaluation

`evals/codeauditor/full-audit/` holds a small Flask service with ten planted defects (one per file) and two decoys, an answer key, and graders for recall, precision, format, and read-only behavior. Run it with `bash scripts/eval.sh codeauditor` from the hub root; it calls models, so see the hub's [evals/README.md](../../evals/README.md) first.

## License

MIT. See [LICENSE](LICENSE).
