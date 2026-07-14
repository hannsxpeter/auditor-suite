# secauditor

A read-only **security audit** skill for AI coding agents. It audits the codebase in the current working directory end to end, writes a scored, prioritized, self-contained `secaudit.md` at the repo root, then prints the verdict in chat. It never edits source and never runs exploits.

It is the security counterpart to `codeauditor` (code quality) and `uxauditor` (user experience), and it is **dual-compatible**: the same `SKILL.md` runs in both Claude Code and Codex.

- In **Claude Code**: invoke with `/secauditor`
- In **Codex**: invoke with `$secauditor`

## What it audits

The audit is grounded in current security frameworks (OWASP Top 10:2025 and 2021, OWASP API Security Top 10 2023, OWASP Top 10 for LLM Applications 2025, OWASP ASVS 5.0, OWASP Top 10 CI/CD Security Risks, CWE Top 25, SLSA v1.2, CIS Benchmarks, and the relevant NIST SP 800-series). It scores eleven dimensions, two of which are conditional on the project's surface:

| Dimension | Weight | Applies |
|---|---|---|
| Authorization and Access Control | 18% | always |
| Injection and Unsafe Input Handling | 16% | always |
| Authentication and Session Management | 15% | always |
| Cryptography and Data Protection | 11% | always |
| Security Misconfiguration and Hardening | 9% | always |
| Dependencies and Software Supply Chain | 9% | always |
| Secrets Management | 8% | always |
| API and Web Service Security | 6% | if an API/web surface exists |
| Logging, Monitoring and Data Privacy | 4% | always (privacy half if regulated data) |
| Cloud, Container and Infrastructure-as-Code Security | 2% | if container/IaC files exist |
| AI / LLM Application Security | 2% | if the project uses an LLM/AI |

Conditional dimensions are dropped and the remaining weights re-normalized when their surface is absent, so the score stays meaningful for any project type.

## How it works

The method runs in phases: orient and detect surfaces; map the attack surface and trust boundaries (a lightweight STRIDE pass); analyze across every security lens with source-to-sink evidence; verify each candidate adversarially and cluster duplicates into systemic patterns; score with conditional re-normalization (a single Critical caps the dimension at 69 and the overall at 79); prioritize into Quick wins / Plan now / Verify first / Backlog; write `secaudit.md`; and report the verdict in chat.

Every finding is self-contained: an exact `file:line`, the source-to-sink path, the attack path and precondition, the impact, a specific fix with the safe pattern, a way to verify the fix, and CWE/OWASP references. It actively hunts "paper" controls (a guard defined but never wired, a validator never called, a scanner run with `continue-on-error`) because a green scanner is not a clean bill of health.

## Install

The skill is a single `skills/secauditor/SKILL.md`. Install it into whichever tool you use.

### Claude Code

As a personal skill:

```sh
mkdir -p ~/.claude/skills/secauditor
cp skills/secauditor/SKILL.md ~/.claude/skills/secauditor/SKILL.md
```

Or install the whole repo as a Claude Code plugin (it ships a `.claude-plugin/plugin.json` manifest) via your plugin workflow, then invoke `/secauditor`.

### Codex

```sh
mkdir -p ~/.codex/skills/secauditor
cp skills/secauditor/SKILL.md ~/.codex/skills/secauditor/SKILL.md
```

Codex also reads skills from `~/.agents/skills/` and `.agents/skills/` (repo-local); any of these works. Invoke with `$secauditor`, or run `/skills` to list.

## Usage

From the root of the project you want to audit:

- Claude Code: `/secauditor` (optionally pass a subpath to scope the audit)
- Codex: `$secauditor`

The skill writes `secaudit.md` to the audited project's root and prints the score, scorecard, and top fixes in chat.

## Output

`secaudit.md` is written for a reader with no memory of the audit (typically another agent that will fix the findings). It contains the snapshot, attack-surface map, overall score and scorecard, "what to fix first", strengths to preserve, systemic root causes, the full findings, a remediation plan, scope and limitations, and a "how to use this report" protocol.

## License

MIT. See [LICENSE](LICENSE).
