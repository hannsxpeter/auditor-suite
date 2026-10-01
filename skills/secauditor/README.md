# secauditor

A read-only **security audit** skill for AI coding agents, part of the [auditor-suite](../../README.md). It audits the codebase in the current directory, writes a scored, prioritized, self-contained `secaudit.md` at the project root, and prints the verdict in chat. It never edits source and never runs exploits or the app.

- Claude Code: `/secauditor`
- Codex: `$secauditor`
- Other Agent Skills harnesses: the harness's native skill invocation

## What it audits

Eleven dimensions, grounded in OWASP Top 10:2025 (with 2021 IDs), the OWASP API Security Top 10 2023, the OWASP Top 10 for LLM Applications 2025, ASVS, CWE, SLSA, and the CIS benchmarks.

| ID | Dimension | Weight | Active when |
|---|---|---|---|
| AUTHZ | Authorization and Access Control | 18 | always |
| INJ | Injection and Unsafe Input Handling | 16 | always |
| AUTHN | Authentication and Session Management | 15 | login, session, token, or password code exists |
| CRYPTO | Cryptography and Data Protection | 11 | always |
| MISCFG | Security Misconfiguration and Hardening | 9 | always |
| SUPPLY | Dependencies and Software Supply Chain | 9 | always |
| SECRET | Secrets Management | 8 | always |
| APISEC | API and Web Service Security | 6 | HTTP routes or API handlers exist |
| LOGPRIV | Logging, Monitoring and Data Privacy | 4 | always |
| IAC | Cloud, Container and Infrastructure-as-Code Security | 2 | container, IaC, or Kubernetes files exist |
| LLMSEC | AI and LLM Application Security | 2 | a model SDK or LLM framework is used |

Weights re-normalize over the active dimensions, so a project without an API or containers is scored only on what it has.

Boundaries: codeauditor's security lens is a survey; secauditor is the depth. secauditor owns roles, ownership, tenants, client-set fields (a plan or price included), webhook signatures, credentials, personal data in events, old or debug routes as attack surface, and abuse at machine speed. [productauditor](../productauditor) owns plan gates and quotas, paid access that waits for a confirmed payment, an unreleased feature's route that skips the release flag the UI checks, deprecation and versioning of the product's own public API, and customer-facing encryption guarantees the code contradicts. The suite map is in [SUITE.md](../../SUITE.md).

## Modes

- `/secauditor` or `/secauditor full`: every active dimension and every card.
- `/secauditor quick`: only the Critical-class cards; no numeric score. A good first pass for small models or large repos.
- `/secauditor only=AUTHZ,INJ`: a subset of dimensions with a partial score.
- `/secauditor src/api` (or `quick src/api`): limit the audit to a path.

## How it works

The skill is a short procedural spine (`SKILL.md`) plus files it reads only when needed:

- `references/protocol.md`: the shared rules for evidence, the finding format, severity, confidence, scoring, and finishing.
- `references/<DIM>.md`: one file of rule cards per dimension. Each card says where to look (a `scan.sh` lead or the files to read), how to confirm the defect, when it is not a finding, the severity, the fix, and how to verify the fix. Every dimension also lists its paper controls: guards that look protective but do nothing.
- `references/example-report.md`: a complete report that passes the validator, as a format anchor.
- `references/facts.md`: dated standards facts (OWASP 2025 and 2021 IDs, recent supply-chain incidents) with a review date.
- `scripts/`: read-only helpers. `inventory.sh` maps the project and decides the conditional dimensions; `scan.sh` turns cards into leads; `new-report.sh` writes the report skeleton; `score.sh` computes every score from the findings; `check-report.sh` validates the report, including that every cited `path:line` exists and that code quoted in Evidence appears within 6 lines of the first cited location.
- `assets/`: the report template and the tables the scripts read (dimensions, search patterns, surface probes).

The model does the judgment (reading code, confirming or refuting each lead, choosing severity); the scripts do the bookkeeping. Scores are deterministic: the same findings always produce the same score.

## Install

Use the hub installer or the plugin marketplace; see the [suite README](../../README.md#install). A manual install must copy or link the whole skill directory (`SKILL.md`, `references/`, `scripts/`, `assets/`), not just `SKILL.md`.

## Output

`secaudit.md` is written for a reader with no memory of the audit, typically another agent that will fix the findings: snapshot, attack-surface map, score and scorecard, what to fix first, strengths to preserve, systemic root causes, findings with `path:line` evidence and a way to verify each fix, dimension notes, a remediation plan, scope and limitations, and a protocol for the acting agent.

## License

MIT. See [LICENSE](LICENSE).
