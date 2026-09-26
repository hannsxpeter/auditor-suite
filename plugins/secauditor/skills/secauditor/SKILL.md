---
name: secauditor
description: Audits a codebase for security vulnerabilities (access control, injection, authentication, cryptography, secrets, misconfiguration, supply chain, APIs, logging and privacy, cloud and IaC, LLM features) and writes secaudit.md, a scored, prioritized, self-contained report, then prints the verdict in chat. Use when the user asks for a security audit, a vulnerability or OWASP review, or a pre-launch security check. Read-only: never edits source, never runs exploits or the app. Modes: full (default), quick (Critical-class triage), only=DIM,DIM, or a path. Invoke with /secauditor in Claude Code or $secauditor in Codex.
allowed-tools: 'Bash(bash "${CLAUDE_SKILL_DIR}/scripts/*)'
---

# secauditor

**You are now running this audit. Do it yourself, starting now, by working through the Workflow below with your own tools.** Nothing runs in the background. The audit is finished only when `check-report.sh` prints OK and you have sent the chat summary.

The audit covers the security of the codebase in the current directory and writes `secaudit.md` at its root: scored, prioritized, and self-contained, so another agent holding only the report and the code can fix what it finds.

## Contract

- Read-only. Create or change no file except `secaudit.md` at the project root. Never run the project, its tests, builds, or migrations; never run exploits; never call a network service or a model.
- Allowed: reading and searching files, read-only shell commands (`git log`, `git show`, `ls`, `wc`), and this skill's scripts. The scripts only read, except `new-report.sh` and `score.sh --write`, which write only `secaudit.md`.
- Evidence: every finding cites a `path:line` you opened and quotes the code there. A `scan.sh` lead is a place to read, never a finding by itself.
- Describe weaknesses and fixes; never write a working exploit or payload beyond what a Verify the fix test needs.
- Finish by sending the output of `score.sh --chat`. Never finish silently.

## Paths

`${CLAUDE_SKILL_DIR}` is this skill's folder, the one that contains this SKILL.md; Claude Code fills it in. If you still see the literal text `${CLAUDE_SKILL_DIR}`, replace it with that folder's absolute path in every command. Run every command from the project root.

## Modes

Text after the skill name picks the mode:
- nothing or `full`: every active dimension, every card.
- `quick`: only the cards tagged (quick), the Critical-class checks; no numeric score.
- `only=AUTHZ,INJ`: only those dimensions, every card; the score is labeled partial.
- a path, alone or after a mode (`quick src/api`): audit only that part of the tree.

## Workflow

Copy this checklist into your notes and tick each step as you finish it.

- [ ] 1. Run `bash "${CLAUDE_SKILL_DIR}/scripts/inventory.sh"` (add the path if scoped). If it prints NO SOURCE CODE FOUND, tell the user and stop.
- [ ] 2. Read `${CLAUDE_SKILL_DIR}/references/protocol.md` (the rules for every finding) and `${CLAUDE_SKILL_DIR}/references/example-report.md` (a finished report).
- [ ] 3. Run `bash "${CLAUDE_SKILL_DIR}/scripts/new-report.sh" --mode <mode>` (add the path if scoped). It creates `secaudit.md` and lists the active dimensions. Fill the Snapshot lines. Trace the two or three highest-risk flows and write the Map section.
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
| AUTHZ | Authorization and Access Control | 18 | always | references/AUTHZ.md |
| INJ | Injection and Unsafe Input Handling | 16 | always | references/INJ.md |
| AUTHN | Authentication and Session Management | 15 | login, session, token, or password code exists | references/AUTHN.md |
| CRYPTO | Cryptography and Data Protection | 11 | always | references/CRYPTO.md |
| MISCFG | Security Misconfiguration and Hardening | 9 | always | references/MISCFG.md |
| SUPPLY | Dependencies and Software Supply Chain | 9 | always | references/SUPPLY.md |
| SECRET | Secrets Management | 8 | always | references/SECRET.md |
| APISEC | API and Web Service Security | 6 | HTTP routes or API handlers exist | references/APISEC.md |
| LOGPRIV | Logging, Monitoring and Data Privacy | 4 | always | references/LOGPRIV.md |
| IAC | Cloud, Container and Infrastructure-as-Code Security | 2 | container, IaC, or Kubernetes files exist | references/IAC.md |
| LLMSEC | AI and LLM Application Security | 2 | a model SDK or LLM framework is used | references/LLMSEC.md |

new-report.sh decides the conditional dimensions from probes and prints why; if a probe is wrong, move the ID between the Active and Not applicable lines and say why in Scope and limitations. Weights re-normalize over the active dimensions. secauditor has no floor dimensions: Critical findings cap scores as protocol section 8 describes.

## How to judge

This audit covers the security of the code as written and configured: who can do what, how untrusted input reaches dangerous sinks, how secrets and data are protected, and where the trust boundaries really are. Code quality, architecture, and performance belong to codeauditor; the database layer to dbauditor; LLM-integration depth to llmauditor. Touch those only where they create a security weakness.

- Source to sink: for injection and access findings, Evidence names where the untrusted value enters and where it is used.
- Exploitability, not presence: Impact says who can reach it, from where, with what input, and the precondition (signed in or not, which role, which setting). If reachability depends on deployment you cannot see, use Likely or Suspected.
- Paper controls are the most dangerous findings: a guard defined but never mounted, a validator never called on the path to the sink, a scanner step that cannot fail the build. Every dimension file lists the ones to hunt.
- A green scanner or a SECURITY.md proves nothing; check the code.
- Calibrate to exposure (internet-facing, internal, or local) and to the data at stake, and write the bar on the Calibration line.

## Reference files

- `references/protocol.md`: evidence rules, finding format, severity, confidence, scoring, modes, finishing.
- `references/example-report.md`: a complete report that passes check-report.sh.
- `references/facts.md`: dated standards facts (OWASP 2025 and 2021 IDs, recent supply-chain incidents), with the date they were last reviewed.
- `references/AUTHZ.md`, `references/INJ.md`, `references/AUTHN.md`, `references/CRYPTO.md`, `references/MISCFG.md`, `references/SUPPLY.md`, `references/SECRET.md`, `references/APISEC.md`, `references/LOGPRIV.md`, `references/IAC.md`, `references/LLMSEC.md`: the cards for each dimension.
- `assets/report-template.md`: the report skeleton new-report.sh fills.
