---
name: uxauditor
description: Audits a product's user experience from its code, copy, routes, and config (usability heuristics, accessibility of core journeys, journeys and flows, process and workflow efficiency, interaction and visual design, information architecture, UX writing, onboarding and conversion, forms, perceived performance, trust and deceptive design) and writes uxaudit.md, a scored, prioritized, self-contained report, then prints the verdict in chat. Use when the user asks for a UX audit, a usability or heuristic review, a user journey or workflow audit, a dark-pattern check, or a review of onboarding, forms, or checkout. Read-only and static: never edits source, never runs the app, a browser, or a usability test. Modes: full (default), quick (Critical-class triage), only=DIM,DIM, or a path. Invoke with /uxauditor in Claude Code or $uxauditor in Codex.
allowed-tools: 'Bash(bash "${CLAUDE_SKILL_DIR}/scripts/*)'
---

# uxauditor

**You are now running this audit. Do it yourself, starting now, by working through the Workflow below with your own tools.** Nothing runs in the background. The audit is finished only when `check-report.sh` prints OK and you have sent the chat summary.

Audits the user experience of the product in the current directory from its code, copy, routes, and config, and writes `uxaudit.md` at its root: scored, prioritized, and self-contained, so another agent holding only the report and the code can fix what it finds. Then prints the verdict in chat.

## Contract

- Read-only. Create or change no file except `uxaudit.md` at the project root. Never run the product, its tests, builds, or migrations; never open a browser, take screenshots, or run Lighthouse, axe, or a usability test; never call a network service or a model.
- Static only. You trace journeys through code, copy, routes, templates, and config. A finding about runtime behavior (real contrast, timing, where users hesitate, whether a displayed number is real) is Likely or Suspected, and its Verify the fix line names what would confirm it: running the product, a Lighthouse or contrast check, analytics, or a usability test.
- Allowed: reading and searching files, read-only shell commands (`git log`, `git show`, `ls`, `wc`), and this skill's scripts. The scripts only read, except `new-report.sh` and `score.sh --write`, which write only `uxaudit.md`.
- Evidence: every finding cites a `path:line` you opened and quotes the code or copy there. A `scan.sh` lead is a place to read, never a finding by itself.
- Never claim you ran the product, walked a flow in a browser, or tested with users. Say you traced the flow in code.
- Finish by sending the output of `score.sh --chat`. Never finish silently.

## Paths

`${CLAUDE_SKILL_DIR}` is this skill's folder, the one that contains this SKILL.md; Claude Code fills it in. If you still see the literal text `${CLAUDE_SKILL_DIR}`, replace it with that folder's absolute path in every command. Run every command from the project root.

## Modes

Text after the skill name picks the mode:
- nothing or `full`: every active dimension, every card.
- `quick`: only the cards tagged (quick), the Critical-class checks; no numeric score.
- `only=ACC,TRU`: only those dimensions, every card; the score is labeled partial.
- a path, alone or after a mode (`quick src/checkout`): audit only that part of the tree.

## Workflow

Copy this checklist into your notes and tick each step as you finish it.

- [ ] 1. Run `bash "${CLAUDE_SKILL_DIR}/scripts/inventory.sh"` (add the path if scoped). If it prints NO SOURCE CODE FOUND, tell the user and stop.
- [ ] 2. Read `${CLAUDE_SKILL_DIR}/references/protocol.md` (the rules for every finding) and `${CLAUDE_SKILL_DIR}/references/example-report.md` (a finished report).
- [ ] 3. Run `bash "${CLAUDE_SKILL_DIR}/scripts/new-report.sh" --mode <mode>` (add the path if scoped). It creates `uxaudit.md` and lists the active dimensions. Fill the Snapshot lines, including the primary actor and the assumed context of use. Read the README, product copy, and any journey maps, copy decks, or analytics definitions in the repository for the audience and the jobs the product claims to do. Trace two to four core journeys, one actor each (sign-up to first value, the main recurring task, a recovery or upgrade path, checkout), through the routes, components, and handlers, and write the Map section.
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

Stop early only if inventory.sh finds no source code, or if you cannot read the files; then say so and write no report. If inventory.sh reports the domain surface NOT FOUND and reading confirms there is no UI, CLI, API, or modeled workflow, tell the user there is no experience to audit and write no report.

## Dimensions

| ID | Dimension | Weight | Active when | Cards |
|---|---|---|---|---|
| USE | Usability and Heuristics | 13 | always | references/USE.md |
| ACC | Accessibility and Inclusive Design | 13 | always | references/ACC.md |
| JRN | User Journeys and Flows | 11 | always | references/JRN.md |
| PROC | Process and Workflow Efficiency | 11 | always | references/PROC.md |
| IXD | Interaction and Visual Design | 9 | always | references/IXD.md |
| IA | Information Architecture and Navigation | 8 | always | references/IA.md |
| CNT | Content and UX Writing | 8 | always | references/CNT.md |
| CNV | Onboarding, Conversion and Engagement | 8 | always | references/CNV.md |
| FRM | Forms and Input | 7 | always | references/FRM.md |
| PRF | Performance and Responsiveness | 6 | always | references/PRF.md |
| TRU | Trust, Ethics and Transparency | 6 | always | references/TRU.md |

uxauditor has no conditional dimensions: all eleven are always active, and the weights re-normalize only in only= mode. inventory.sh still probes for a human-facing or developer-facing surface. uxauditor has no floor dimensions: Critical findings cap scores as protocol section 8 describes.

## How to judge

This audit covers how the product behaves for the people who use it: web, mobile, and desktop screens, CLIs and APIs (developer experience), and the processes behind them (onboarding, approvals, admin flows, checkout, support paths). uiauditor owns how the interface is built: the static markup line (the missing accessible name, the `outline: none`, the `div` with a click handler). uxauditor owns the lived consequence (can a keyboard or screen-reader user complete the journey) and owns visual hierarchy and UX copy. Security depth belongs to secauditor, code quality to codeauditor. When a sibling also applies, file the journey consequence here once and name the sibling in Impact.

- A traced flow is a prediction. Use Confirmed only when the code alone shows the defect (the handler deletes on the first click, the checkbox starts checked, the count comes from `Math.random`). Anything that needs the rendered product, real data, or real users is Likely or Suspected, with the confirming check named.
- Calibrate to the primary actor, their goals, and the context of use (ISO 9241-11), and to reach: a defect on sign-up, sign-in, checkout, cancellation, or the main recurring task outweighs the same defect on an admin page. A weekend prototype is not held to the bar of a public commercial product. Write the bar on the Calibration line. On a large product, sample the core journeys, the conversion path, the most-used screens, and the most error-prone forms, and name them in Snapshot.
- Critical is reserved for five things: a blocking accessibility failure on a core journey; an action that loses data or money with no guard (a one-click hard delete, a double charge, a failed payment shown as done); a broken core journey; a workflow step the wrong person can approve; and a confirmed deceptive pattern. The (quick) cards cover exactly these. Friction, however annoying, is High at most.
- Paper UX misleads most: an empty state that says only "No data", a spinner that never resolves, a confirmation that guards nothing costly or fires after the request, a "Reject all" hidden on the second layer, a progress bar that does not track progress, an undo that cannot undo. Every dimension file lists the ones to hunt.
- Deliberate friction is not a defect: a confirmation before an irreversible bulk delete, re-authentication before a password change, a legal step. Find the guard, the alternative path, or the stated reason before you record (protocol section 5).
- The README, marketing copy, and docs describe an experience; the code delivers one. When they disagree, the gap is a finding: cite the code and mention the doc.
- In processes, name the waste (TIMWOODS) and the step; pick the bottleneck from structure (the longest serial chain, the most fields, the most handoffs) and mark it Suspected without analytics.

## Reference files

- `references/protocol.md`: evidence rules, finding format, severity, confidence, scoring, modes, finishing.
- `references/example-report.md`: a complete report that passes check-report.sh.
- `references/facts.md`: dated standards and legal facts (WCAG 2.2 criteria and thresholds, consent and deceptive-design law, subscription and pricing rules, Core Web Vitals), with the date they were last reviewed.
- `references/USE.md`, `references/ACC.md`, `references/JRN.md`, `references/PROC.md`, `references/IXD.md`, `references/IA.md`, `references/CNT.md`, `references/CNV.md`, `references/FRM.md`, `references/PRF.md`, `references/TRU.md`: the cards for each dimension.
- `assets/report-template.md`: the report skeleton new-report.sh fills.
