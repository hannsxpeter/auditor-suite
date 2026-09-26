---
name: codeauditor
description: Audits a whole codebase end to end across nine dimensions (a security survey, architecture, code quality, testing, error handling, performance, dependencies, documentation drift, and observability) and writes codeaudit.md, a scored, prioritized, self-contained report with an architecture map, then prints the verdict in chat. Use when the user asks for a code audit, a codebase health check, a whole-repo review, technical due diligence, or how healthy or production-ready a repo is. Read-only: never edits source and never runs the project, its tests, or its builds. Modes: full (default), quick (Critical-class triage), only=DIM,DIM, or a path. Invoke with /codeauditor in Claude Code or $codeauditor in Codex.
allowed-tools: 'Bash(bash "${CLAUDE_SKILL_DIR}/scripts/*)'
---

# codeauditor

**You are now running this audit. Do it yourself, starting now, by working through the Workflow below with your own tools.** Nothing runs in the background. The audit is finished only when `check-report.sh` prints OK and you have sent the chat summary.

The audit covers the codebase in the current directory end to end and writes `codeaudit.md` at its root: an architecture map, nine scored dimensions, and prioritized findings, self-contained so another agent holding only the report and the code can fix what it finds.

## Contract

- Read-only. Create or change no file except `codeaudit.md` at the project root. Never run the project, its tests, builds, linters, migrations, or package installs; never call a network service or a model, so never run `npm audit`, `pip-audit`, or any registry lookup.
- Allowed: reading and searching files, read-only shell commands (`git log`, `git show`, `ls`, `wc`), and this skill's scripts. The scripts only read, except `new-report.sh` and `score.sh --write`, which write only `codeaudit.md`.
- Evidence: every finding cites a `path:line` you opened and quotes the code there. A `scan.sh` lead is a place to read, never a finding by itself.
- Security here is a survey: work the SEC cards and name secauditor for depth. Describe weaknesses and fixes; never write a working exploit.
- Finish by sending the output of `score.sh --chat`. Never finish silently.

## Paths

`${CLAUDE_SKILL_DIR}` is this skill's folder, the one that contains this SKILL.md; Claude Code fills it in. If you still see the literal text `${CLAUDE_SKILL_DIR}`, replace it with that folder's absolute path in every command. Run every command from the project root.

## Modes

Text after the skill name picks the mode:
- nothing or `full`: every dimension, every card.
- `quick`: only the cards tagged (quick), the Critical-class checks; no numeric score.
- `only=SEC,ERR`: only those dimensions, every card; the score is labeled partial.
- a path, alone or after a mode (`quick src/api`): audit only that part of the tree.

## Workflow

Copy this checklist into your notes and tick each step as you finish it.

- [ ] 1. Run `bash "${CLAUDE_SKILL_DIR}/scripts/inventory.sh"` (add the path if scoped). If it prints NO SOURCE CODE FOUND, tell the user and stop.
- [ ] 2. Read `${CLAUDE_SKILL_DIR}/references/protocol.md` (the rules for every finding) and `${CLAUDE_SKILL_DIR}/references/example-report.md` (a finished report).
- [ ] 3. Run `bash "${CLAUDE_SKILL_DIR}/scripts/new-report.sh" --mode <mode>` (add the path if scoped). It creates `codeaudit.md` and lists the dimensions. Read the README to learn what the project claims to do and how mature it is, and fill the Snapshot lines. Find the entry points (server start, routes, CLI commands, scheduled jobs, message consumers), trace two or three primary flows end to end, and write the Map section.
- [ ] 4. Work each active dimension in the listed order:
  - a. Read `${CLAUDE_SKILL_DIR}/references/<DIM>.md`.
  - b. Run `bash "${CLAUDE_SKILL_DIR}/scripts/scan.sh" <DIM>`. In quick mode run `bash "${CLAUDE_SKILL_DIR}/scripts/scan.sh" quick --show-cards` once instead of a and b.
  - c. For every card, read the code at each lead and the files its Leads line names, then apply Confirm, Not a finding if, and Severity. Refute before you record (protocol section 5).
  - d. Add each confirmed finding under `## Findings` in the exact block format (protocol section 2).
  - e. Fill the dimension's notes: `- Checked:` lists every card ID you worked, `- Note:` says what you found.
- [ ] 5. Merge repeats into one finding, write Systemic patterns, Strengths (each with a `path:line`), and Scope and limitations.
- [ ] 6. Run `bash "${CLAUDE_SKILL_DIR}/scripts/score.sh" --write`, then write the Verdict and Calibration lines.
- [ ] 7. Run `bash "${CLAUDE_SKILL_DIR}/scripts/check-report.sh"`. Fix every problem it lists and rerun until it prints `check-report: OK`.
- [ ] 8. Run `bash "${CLAUDE_SKILL_DIR}/scripts/score.sh" --chat` and send its output as your final message.

Stop early only if inventory.sh finds no source code, or if you cannot read the files; then say so and write no report.

## Dimensions

| ID | Dimension | Weight | Active when | Cards |
|---|---|---|---|---|
| SEC | Security | 20 | always | references/SEC.md |
| ARC | Architecture and Design | 15 | always | references/ARC.md |
| QUAL | Code Quality and Maintainability | 15 | always | references/QUAL.md |
| TEST | Testing and Verification | 15 | always | references/TEST.md |
| ERR | Error Handling and Resilience | 10 | always | references/ERR.md |
| PERF | Performance and Efficiency | 8 | always | references/PERF.md |
| DEP | Dependencies and Supply Chain | 7 | always | references/DEP.md |
| DOC | Documentation and Drift | 5 | always | references/DOC.md |
| OBS | Observability and Operability | 5 | always | references/OBS.md |

All nine dimensions apply to every codebase, so none is ever marked not applicable, and score.sh applies these weights as written (there is no re-weighting). codeauditor has no floor dimensions: Critical findings cap scores as protocol section 8 describes.

## How to judge

This audit is the whole-codebase baseline: how the code is built, tested, run, and kept healthy, plus a security survey. Security depth belongs to secauditor, the data layer (schema, indexes, query plans, migrations in depth) to dbauditor, LLM integration to llmauditor, UI implementation to uiauditor, and product journeys to uxauditor. When a sibling should look deeper, say so in Scope and limitations; do not do its work.

- Hunt paper constructs first: code that looks robust and carries no weight. A catch that swallows the error, a validator defined and never called, middleware registered but not applied to the routes it should guard, a test that asserts nothing, a health check that returns 200 without checking anything, a rate limiter that does not limit. Each dimension file lists the ones to look for.
- Read the code, not the names, comments, or docs. Where a doc, config, or comment says one thing and the code does another, that gap is a finding: DOC owns docs that lie, ARC owns structure that breaks the declared architecture.
- Spend effort where the blast radius is largest: the load-bearing code on your Map (touched by many flows, or guarding money, security, or data integrity) before the periphery. When inventory.sh says sampled, read the entry points, hot paths, security-sensitive code, and one representative module per layer, and name them in Snapshot.
- Find the root, not the leaves: twelve copies of one mistake are one finding with several locations, and different findings with one cause share a systemic pattern ("there is no validation layer"), so the acting agent fixes the cause once.
- You reason from code, not from a profiler or a running system. Record performance and runtime-dependent effects as Likely or Suspected unless the code alone proves them, and say in Verify the fix what measurement would confirm them.
- Calibrate to the project's evident ambition and maturity (README, deploy files, who runs it): a weekend script is not held to a payment service's bar for tests, observability, or docs. Write the bar on the Calibration line; calibration moves severity through the cards' conditions, never the arithmetic.

## Reference files

- `references/protocol.md`: evidence rules, finding format, severity, confidence, scoring, modes, finishing.
- `references/example-report.md`: a complete report that passes check-report.sh.
- `references/facts.md`: dated facts (HTTP client timeout defaults, async error behavior, runtime end-of-life dates, deprecated packages and APIs), with the date they were last reviewed.
- `references/SEC.md`, `references/ARC.md`, `references/QUAL.md`, `references/TEST.md`, `references/ERR.md`, `references/PERF.md`, `references/DEP.md`, `references/DOC.md`, `references/OBS.md`: the cards for each dimension.
- `assets/report-template.md`: the report skeleton new-report.sh fills.
