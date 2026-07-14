# Changelog

All notable changes to codeauditor are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [auditor-suite 1.0.0] - 2026-07-14

Moved into the [auditor-suite](https://github.com/hannsxpeter/auditor-suite)
monorepo as `skills/codeauditor/`, with the standalone repo's full git history
preserved. Standalone versioning is retired; the skill now follows the
auditor-suite release train.

### Changed
- `SKILL.md` now carries Agent Skills frontmatter directly (name, description,
  and the `/codeauditor` and `$codeauditor` invocation tokens); previously the
  frontmatter was synthesized at install time by the standalone installer. The
  audit engine body is unchanged from `engine/codeauditor.md`.
- The standalone per-tool installer, its planned global-command mode, and the
  per-repo CI checks (formerly tracked here as unreleased work) are superseded
  by the hub installer (`install.sh`) and the hub lint workflow, which enforce
  the same rules suite-wide: no em dashes, en dashes, or emojis in tracked
  files, and bash-valid scripts.

## [1.0.0] - 2026-05-30

First public release.

### Added
- The `codeauditor` command: a complete, read-only audit of a codebase that
  writes `codeaudit.md` and then prints a summary to the chat.
- Nine analysis lenses: Security, Architecture and Design, Code Quality and
  Maintainability, Testing and Verification, Error Handling and Resilience,
  Performance and Efficiency, Dependencies and Supply Chain, Documentation and
  Drift, and Observability and Operability.
- Explicit scoring rubric with per-dimension weights, score bands, and a rule
  that a single Critical finding caps the dimension and the overall score.
- Self-contained findings (Severity, Confidence, Effort, Location, Evidence,
  Impact, Recommendation, Verify-the-fix, Related) and root-cause clustering
  into systemic patterns, written so another agent can act on them with no
  prior context. Includes a decision protocol for the acting agent.
- Chat summary after the report is written: headline score and grade,
  scorecard, top fixes, finding counts by severity, and the report path.
- Single source of truth in `engine/codeauditor.md`.
- `install.sh` that detects installed tools and renders the engine into each
  one's native format, with an `uninstall` mode. Supports Claude Code, OpenAI
  Codex CLI, Gemini CLI, Cursor, opencode, Windsurf, Antigravity, and pi
  (pi.dev).
- `AGENTS.md` portable directive for any other tool that reads `AGENTS.md`.
- Project documentation: README, CONTRIBUTING, SECURITY, CODE_OF_CONDUCT, and
  this changelog.
- Downloadable release archive (`codeauditor-1.0.0.zip` and `.tar.gz`) attached
  to the GitHub release: unzip and run `./install.sh`.

[1.0.0]: https://github.com/hannsxpeter/codeauditor/releases/tag/v1.0.0
