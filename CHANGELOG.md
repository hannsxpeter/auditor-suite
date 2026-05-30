# Changelog

All notable changes to codeauditor are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

[1.0.0]: https://github.com/aihxp/codeauditor/releases/tag/v1.0.0
