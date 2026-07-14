# codeauditor

[![checks](https://github.com/hannsxpeter/codeauditor/actions/workflows/checks.yml/badge.svg)](https://github.com/hannsxpeter/codeauditor/actions/workflows/checks.yml) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE) [![Release](https://img.shields.io/github/v/release/aihxp/codeauditor?sort=semver)](https://github.com/hannsxpeter/codeauditor/releases) [![PRs welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)

**codeauditor is an installable skill for AI coding agents.** You install it once, then run it from whichever AI coding tool you use. It audits a codebase end to end, writes a single scored report (`codeaudit.md`), and prints the verdict right in your chat.

It installs as a skill or a `/codeauditor` slash command across Claude Code, OpenAI Codex CLI, Gemini CLI, Cursor, opencode, Windsurf, Antigravity, and pi (pi.dev), all rendered from one source of truth.

The report is written for a reader with no memory of the audit, typically an AI agent that opens `codeaudit.md` and decides on its own what to fix. Every finding cites exact locations and carries the context needed to act on it cold.

## What it does

A full, read-only analysis across nine lenses (Security, Architecture, Code Quality, Testing, Error Handling, Performance, Dependencies, Documentation, Observability). It scores each against an explicit rubric, clusters repeated issues into root-cause patterns, ends with a weighted overall score, and prints a summary to the chat so you see the verdict without opening the file. Source code is never modified; the only file it writes is `codeaudit.md`.

## Install

codeauditor is a skill, so installing it means rendering it into your AI tools' skill and command directories. The installer detects which tools you have under your home directory and writes the correct file for each. Only tools you actually have are touched.

### Option A: from source

```sh
git clone https://github.com/hannsxpeter/codeauditor
cd codeauditor
./install.sh
```

### Option B: from a release download

Download `codeauditor-1.0.0.zip` (or `.tar.gz`) from the [latest release](https://github.com/hannsxpeter/codeauditor/releases/latest), then:

```sh
unzip codeauditor-1.0.0.zip
cd codeauditor-1.0.0
./install.sh
```

Re-run `./install.sh` any time after editing the engine to re-sync every tool. Run `./install.sh uninstall` to remove it from every tool. Either way, it installs into each tool's user-level config (for example `~/.claude/skills/`, `~/.codex/skills/`), so the skill is available globally in every project, not just one.

### Optional: a global installer command

To run the installer from any directory, put it on your PATH (from the repo root):

```sh
ln -sf "$PWD/install.sh" ~/.local/bin/codeauditor-install
```

Then `codeauditor-install` re-syncs every tool from anywhere, and `codeauditor-install uninstall` removes it. The installer resolves its own path through the symlink, so it still finds the engine.

## How to run it

After installing, open your AI coding tool in the project you want to audit, then run the command:

- **Codex:** type `$codeauditor` (Codex skills use a `$` prefix)
- **Gemini, Cursor, Windsurf, opencode, pi:** type `/codeauditor`
- **Claude Code, Antigravity:** type `/codeauditor`, or say "audit my codebase" (the skill triggers on its own)

The agent analyzes the project, writes `codeaudit.md` at the project root, and prints a summary in the chat: the overall score and grade, the per-dimension scorecard, the top fixes, and finding counts by severity. From there you can ask that same agent to start fixing, or hand `codeaudit.md` to another agent that will act on it.

It is read-only. It never changes your source. The only file it creates is `codeaudit.md`.

## Cross-tool support

The behavior lives in one file, [`engine/codeauditor.md`](engine/codeauditor.md). The installer renders that one file into each tool's native format, so the skill behaves identically everywhere.

| Tool | Installed as | How you run it |
|---|---|---|
| Claude Code | skill (`~/.claude/skills/codeauditor/`) | `/codeauditor` (or ask "audit my codebase") |
| OpenAI Codex CLI | skill + command (`~/.codex/`) | `$codeauditor` |
| Gemini CLI | skill + command (`~/.gemini/`) | `/codeauditor` |
| Cursor | skill + command (`~/.cursor/`) | `/codeauditor` |
| Windsurf | command (`~/.windsurf/commands/`) | `/codeauditor` |
| opencode | command (`~/.config/opencode/command/`) | `/codeauditor` |
| Antigravity | skill (`~/.antigravity/skills/`) | ask "audit my codebase" |
| pi (pi.dev) | skill, flat file (`~/.pi/skills/codeauditor.md`) | `/codeauditor` |
| Any other tool that reads `AGENTS.md` | portable directive | ask "audit codebase" (see [AGENTS.md](AGENTS.md)) |

Tools without a skill or command system (for example ones that only read an `AGENTS.md`) are covered by the portable directive in [AGENTS.md](AGENTS.md): drop it into a project's `AGENTS.md` or a global one and the same audit behavior applies. To add a tool the installer does not know about, copy the engine into that tool's command or prompt directory (wrapping it in whatever frontmatter the tool expects).

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
    codeauditor.md      the complete, tool-neutral skill (the one source of truth)
  install.sh            detects installed tools and renders the engine into each
  AGENTS.md             portable directive for any AGENTS.md-aware tool, plus repo notes
  README.md             this file
  CONTRIBUTING.md       how to contribute (edit the engine, re-run the installer)
  CHANGELOG.md          release history
  SECURITY.md           what the skill does and does not do, and how to report issues
  CODE_OF_CONDUCT.md    community expectations
  LICENSE               MIT
```

## Editing

Change behavior in `engine/codeauditor.md` only, then re-run `./install.sh`. Do not edit the per-tool copies by hand; they are generated and will be overwritten on the next install.

## Documentation

- [CONTRIBUTING.md](CONTRIBUTING.md) - how to make and test changes, and how to add a new tool adapter.
- [CHANGELOG.md](CHANGELOG.md) - release history.
- [SECURITY.md](SECURITY.md) - the skill is read-only; how to report a vulnerability and handle reports.
- [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) - community expectations.
- [AGENTS.md](AGENTS.md) - portable directive for any tool that reads `AGENTS.md`.

## Contributing

Contributions are welcome. The one rule: all behavior lives in `engine/codeauditor.md`, and everything else is generated by `install.sh`. See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

[MIT](LICENSE), copyright 2026 aihxp.
