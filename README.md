# codeauditor

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE) [![Release](https://img.shields.io/github/v/release/aihxp/codeauditor?sort=semver)](https://github.com/aihxp/codeauditor/releases) [![PRs welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)

A cross-tool AI command that audits a codebase end to end, writes a single report (`codeaudit.md`) with an overall score, a per-dimension scorecard, evidence-backed findings, and a prioritized remediation plan, then **shows the results in the chat**.

One command. One job. Works across many AI coding tools from one source of truth.

The report is written for a reader with no memory of the audit, typically an AI agent that opens `codeaudit.md` and decides on its own what to fix. Every finding cites exact locations and carries the context needed to act on it cold.

## What it does

A full, read-only analysis across nine lenses (Security, Architecture, Code Quality, Testing, Error Handling, Performance, Dependencies, Documentation, Observability). It scores each against an explicit rubric, clusters repeated issues into root-cause patterns, ends with a weighted overall score, and then prints a summary to the chat so you see the verdict without opening the file. Source code is never modified.

## Cross-tool support

The behavior lives in one file, [`engine/codeauditor.md`](engine/codeauditor.md). The installer renders that one file into each tool's native format, so the command behaves identically everywhere.

| Tool | Installed as | Invoke with |
|---|---|---|
| Claude Code | skill (`~/.claude/skills/codeauditor/`) | ask "audit my codebase" (auto-triggers) |
| OpenAI Codex CLI | skill + command (`~/.codex/`) | `/codeauditor` |
| Gemini CLI | skill + command (`~/.gemini/`) | `/codeauditor` |
| Cursor | skill + command (`~/.cursor/`) | `/codeauditor` |
| Windsurf | command (`~/.windsurf/commands/`) | `/codeauditor` |
| opencode | command (`~/.config/opencode/command/`) | `/codeauditor` |
| Antigravity | skill (`~/.antigravity/skills/`) | ask "audit my codebase" |
| pi (pi.dev) | skill, flat file (`~/.pi/skills/codeauditor.md`) | `/codeauditor` |
| Any other tool that reads `AGENTS.md` | portable directive | ask "audit codebase" (see [AGENTS.md](AGENTS.md)) |

Only tools actually present on the machine are touched. Tools without a skill or command system (for example ones that only read an `AGENTS.md`) are covered by the portable directive in [AGENTS.md](AGENTS.md): drop it into a project's `AGENTS.md` or a global one and the same audit behavior applies.

## Install

### From source

```sh
git clone https://github.com/aihxp/codeauditor
cd codeauditor
./install.sh
```

It detects every supported tool under your home directory and installs the command into each. Re-run it any time after editing the engine to re-sync all tools. Append `uninstall` to remove it.

### Via npm (GitHub Packages)

The command is also published as an npm package on GitHub Packages, [`@aihxp/codeauditor`](https://github.com/aihxp/codeauditor/pkgs/npm/codeauditor). GitHub Packages requires authentication even for public packages, so add a one-time line to `~/.npmrc` (`//npm.pkg.github.com/:_authToken=YOUR_GITHUB_TOKEN`, using a token with `read:packages`), then run:

```sh
npx --registry=https://npm.pkg.github.com @aihxp/codeauditor
```

That runs the same installer and renders the command into every detected tool. Append `uninstall` to remove it.

To add a tool the installer does not know about, copy the engine into that tool's command or prompt directory (wrapping it in whatever frontmatter the tool expects), or use the `AGENTS.md` directive.

## The philosophy

A few principles separate a useful audit from a decorative one:

- **Evidence over assertion.** No claim survives without a `file:line`. Every sentence must fail the substitution test: if it would read true for some other codebase, it is filler.
- **Verify against reality.** Read the code, not the comments, names, or docs. Where a doc claims one thing and the code does another, the gap is itself a finding.
- **Refuse theater.** Hunt for constructs that look robust but carry no weight: swallowed errors, validators never called, middleware registered but not applied, tests that assert nothing, health checks that check nothing.
- **Find the root, not the leaves.** Twelve instances of one mistake are one systemic finding, not twelve.
- **Verify adversarially.** Try to refute each finding before keeping it; tag confidence so the reader acts on confirmed issues directly and re-checks suspected ones first.
- **Calibrate and be honest about scope.** Grade against the project's evident maturity, and state what was and was not examined.
- **Specific, actionable recommendations**, each with a way to verify the fix, so an agent can act autonomously.

## Layout

```
codeauditor/
  engine/
    codeauditor.md      the complete, tool-neutral command (the one source of truth)
  install.sh            detects installed tools and renders the engine into each
  AGENTS.md             portable directive for any AGENTS.md-aware tool, plus repo notes
  README.md             this file
  CONTRIBUTING.md       how to contribute (edit the engine, re-run the installer)
  CHANGELOG.md          release history
  SECURITY.md           what the tool does and does not do, and how to report issues
  CODE_OF_CONDUCT.md    community expectations
  LICENSE               MIT
```

## Editing

Change behavior in `engine/codeauditor.md` only, then re-run `./install.sh`. Do not edit the per-tool copies by hand; they are generated and will be overwritten on the next install.

## Documentation

- [CONTRIBUTING.md](CONTRIBUTING.md) - how to make and test changes, and how to add a new tool adapter.
- [CHANGELOG.md](CHANGELOG.md) - release history.
- [SECURITY.md](SECURITY.md) - the tool is read-only; how to report a vulnerability and handle reports.
- [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) - community expectations.
- [AGENTS.md](AGENTS.md) - portable directive for any tool that reads `AGENTS.md`.

## Contributing

Contributions are welcome. The one rule: all behavior lives in `engine/codeauditor.md`, and everything else is generated by `install.sh`. See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

[MIT](LICENSE), copyright 2026 aihxp.
