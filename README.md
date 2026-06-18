# uxauditor

[![checks](https://github.com/aihxp/uxauditor/actions/workflows/checks.yml/badge.svg)](https://github.com/aihxp/uxauditor/actions/workflows/checks.yml) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE) [![Release](https://img.shields.io/github/v/release/aihxp/uxauditor?sort=semver)](https://github.com/aihxp/uxauditor/releases) [![PRs welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)

**uxauditor is an installable skill for AI coding agents.** You install it once, then run it from whichever AI coding tool you use. It audits a product's user experience end to end, its interface, user journeys, processes, and workflows, writes a single scored report (`uxaudit.md`), and prints the verdict right in your chat.

It installs as a skill or a `/uxauditor` slash command across Claude Code, OpenAI Codex CLI, Gemini CLI, Cursor, opencode, Windsurf, Antigravity, and pi (pi.dev), all rendered from one source of truth.

The report is written for a reader with no memory of the audit, typically an AI agent that opens `uxaudit.md` and decides on its own what to fix. Every finding cites an exact location and carries the context needed to act on it cold.

## What it does

A full, read-only analysis across eleven lenses grounded in established standards (Nielsen's heuristics, WCAG 2.2, ISO 9241, the Laws of UX, Baymard form research, Lean and the Theory of Constraints, AARRR, and the deceptive-design taxonomy):

- **Usability and Heuristics** (Nielsen's 10)
- **Accessibility and Inclusive Design** (WCAG 2.2 AA, POUR)
- **User Journeys and Flows** (journey mapping, friction, jobs-to-be-done)
- **Process and Workflow Efficiency** (Lean waste, bottlenecks, step economy)
- **Interaction and Visual Design** (Gestalt, affordances, component states)
- **Information Architecture and Navigation** (scent, findability, labels)
- **Content and UX Writing** (plain language, microcopy, error messages)
- **Onboarding, Conversion and Engagement** (activation, funnels, empty states)
- **Forms and Input** (labels, validation, autofill, field economy)
- **Performance and Responsiveness** (Core Web Vitals, perceived speed)
- **Trust, Ethics and Transparency** (dark patterns, credibility, consent)

It scores each lens against an explicit rubric, clusters repeated issues into root-cause patterns, ends with a weighted overall score, and prints a summary to the chat so you see the verdict without opening the file. Your source is never modified; the only file it writes is `uxaudit.md`.

## Install

uxauditor is a skill, so installing it means rendering it into your AI tools' skill and command directories. The installer detects which tools you have under your home directory and writes the correct file for each. Only tools you actually have are touched.

### Quickest: npx (no clone)

```sh
npx uxauditor
```

This fetches uxauditor and renders it into every detected AI tool in one step. Then `npx uxauditor list` shows what is installed, `npx uxauditor --dry-run` previews without writing, and `npx uxauditor uninstall` removes it. Requires Node (for `npx`) and bash.

### Option A: from source

```sh
git clone https://github.com/aihxp/uxauditor
cd uxauditor
./install.sh
```

### Option B: from a release download

Download the `.zip` (or `.tar.gz`) for the [latest release](https://github.com/aihxp/uxauditor/releases/latest), then unzip it, `cd` into the extracted `uxauditor-<version>` directory, and run the installer. The wildcards below match whichever version you downloaded:

```sh
unzip uxauditor-*.zip
cd uxauditor-*/
./install.sh
```

Other commands:

```sh
./install.sh --dry-run   # preview what would be written, without writing
./install.sh list        # show what is installed in each detected tool
./install.sh uninstall   # remove it from every tool
./install.sh --help      # full usage, including which directories are detected
```

Re-run `./install.sh` any time after editing the engine to re-sync every tool.

## How to run it

After installing, open your AI coding tool in the project you want to audit, then run the command:

- **Codex:** type `$uxauditor` (the installed skill) or `/uxauditor` (the installed prompt)
- **Gemini, Cursor, Windsurf, opencode, pi:** type `/uxauditor`
- **Claude Code, Antigravity:** type `/uxauditor`, or say "audit my UX" (the skill triggers on its own)

The agent analyzes the product, writes `uxaudit.md` at the project root, and prints a summary in the chat: the overall score and grade, the per-dimension scorecard, the top fixes, and finding counts by severity. From there you can ask that same agent to start fixing, or hand `uxaudit.md` to another agent that will act on it.

It is read-only. It never changes your source. The only file it creates is `uxaudit.md`.

Optionally pass a path, a flow name, or a scope to narrow the audit (for example the checkout flow or a single route); with no argument it audits the whole product rooted at the working directory.

## What it audits

"Experience" is treated broadly. uxauditor works on web and mobile UI, but also on command-line interfaces, APIs and SDKs (developer experience), desktop apps, and the processes and workflows behind a product (onboarding, approval queues, admin flows, checkout, support paths). It reads the implementation, walks the flows, and, where a running instance or design artifacts are available, observes them. Much of UX lives at runtime, so findings inferred from static code alone are marked Suspected with a note on what would confirm them (running the product, a Lighthouse or contrast check, or a usability test).

## Cross-tool support

The behavior lives in one file, [`engine/uxauditor.md`](engine/uxauditor.md). The installer renders that one file into each tool's native format, so the skill behaves identically everywhere.

| Tool | Installed as | How you run it |
|---|---|---|
| Claude Code | skill (`~/.claude/skills/uxauditor/`) | `/uxauditor`, or ask "audit my UX" (auto-triggers) |
| OpenAI Codex CLI | skill + prompt (`~/.codex/`) | `$uxauditor` (skill) or `/uxauditor` (prompt) |
| Gemini CLI | skill + command (`~/.gemini/`) | `/uxauditor` |
| Cursor | skill + command (`~/.cursor/`) | `/uxauditor` |
| Windsurf | command (`~/.windsurf/commands/`) | `/uxauditor` |
| opencode | command (`~/.config/opencode/command/`) | `/uxauditor` |
| Antigravity | skill (`~/.antigravity/skills/`) | ask "audit my UX" |
| pi (pi.dev) | skill, flat file (`~/.pi/skills/uxauditor.md`) | `/uxauditor` |
| Any other tool that reads `AGENTS.md` | portable directive | ask "audit UX" (see [AGENTS.md](AGENTS.md)) |

Tools without a skill or command system (for example ones that only read an `AGENTS.md`) are covered by the portable directive in [AGENTS.md](AGENTS.md): drop it into a project's `AGENTS.md` or a global one and the same audit behavior applies. To add a tool the installer does not know about, copy the engine into that tool's command or prompt directory (wrapping it in whatever frontmatter the tool expects).

## The philosophy

A few principles separate a useful UX audit from a decorative one:

- **Evidence over assertion.** No claim survives without a location (a `file:line`, a route, a component, or a named step). Every sentence must fail the substitution test: if it would read true for some other product, it is filler.
- **Audit the experienced product, not the description of it.** Read the rendered behavior, copy, and flows, not just names and marketing claims. Where a doc promises one experience and the implementation delivers another, the gap is itself a finding.
- **Inference is a prediction, not a verdict.** Much of UX is only visible at runtime, so findings inferred from static code are tagged Suspected with a note on what would confirm them.
- **Refuse theater.** Hunt for experience that looks designed but does not work: empty states that say only "No data," confirmation dialogs guarding nothing, a "Reject all" hidden behind low contrast, a progress bar that does not track progress.
- **Find the root, not the leaves.** Placeholder-as-label on every field is one systemic finding, not twelve.
- **Verify adversarially.** Try to refute each finding before keeping it; tag confidence so the reader acts on confirmed issues directly and re-checks suspected ones first.
- **Calibrate and be honest about scope.** Grade against the product's evident maturity and audience, state the assumed persona and context, and say whether you ran the product or only read it.
- **Specific, actionable recommendations**, each with a way to verify the fix, so an agent can act autonomously.

## Layout

```
uxauditor/
  engine/
    uxauditor.md        the complete, tool-neutral skill (the one source of truth)
  install.sh            detects installed tools and renders the engine into each
  VERSION               the current version, read by install.sh --version
  AGENTS.md             portable directive for any AGENTS.md-aware tool, plus repo notes
  README.md             this file
  CONTRIBUTING.md       how to contribute (edit the engine, re-run the installer)
  CHANGELOG.md          release history
  SECURITY.md           what the skill does and does not do, and how to report issues
  CODE_OF_CONDUCT.md    community expectations
  LICENSE               MIT
```

## Editing

Change behavior in `engine/uxauditor.md` only, then re-run `./install.sh`. Do not edit the per-tool copies by hand; they are generated and will be overwritten on the next install.

## Documentation

- [CONTRIBUTING.md](CONTRIBUTING.md) - how to make and test changes, and how to add a new tool adapter.
- [CHANGELOG.md](CHANGELOG.md) - release history.
- [SECURITY.md](SECURITY.md) - the skill is read-only; how to report a vulnerability and handle reports.
- [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) - community expectations.
- [AGENTS.md](AGENTS.md) - portable directive for any tool that reads `AGENTS.md`.

## Contributing

Contributions are welcome. The one rule: all behavior lives in `engine/uxauditor.md`, and everything else is generated by `install.sh`. See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

[MIT](LICENSE), copyright 2026 aihxp.
