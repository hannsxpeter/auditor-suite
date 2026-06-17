# Changelog

All notable changes to uxauditor are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project adheres
to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-06-17

First release.

### Added
- The tool-neutral audit engine ([`engine/uxauditor.md`](engine/uxauditor.md)): a read-only, end-to-end UX audit that writes a scored, prioritized, self-contained `uxaudit.md` and prints the verdict in chat.
- Eleven analysis lenses grounded in established standards: Usability and Heuristics (Nielsen's 10), Accessibility and Inclusive Design (WCAG 2.2 AA), User Journeys and Flows, Process and Workflow Efficiency (Lean, Theory of Constraints), Interaction and Visual Design, Information Architecture and Navigation, Content and UX Writing, Onboarding, Conversion and Engagement (AARRR), Forms and Input (Baymard), Performance and Responsiveness (Core Web Vitals), and Trust, Ethics and Transparency (the deceptive-design taxonomy).
- A weighted scoring model with A-F bands and a Critical-caps-the-score rule, severity mapped to Nielsen's 0-4 scale, and Confirmed / Likely / Suspected confidence so runtime-only findings are flagged for verification.
- `install.sh`: detects installed AI coding tools under `$HOME` and renders the engine into each tool's native skill or slash-command format (Claude Code, Codex CLI, Gemini CLI, Cursor, opencode, Windsurf, Antigravity, pi). Idempotent, with an `uninstall` mode.
- [`AGENTS.md`](AGENTS.md) portable directive for any tool that reads `AGENTS.md`.
- Repository scaffolding: README, CONTRIBUTING, SECURITY, CODE_OF_CONDUCT, LICENSE (MIT), `.editorconfig`, `.gitignore`, and a CI workflow that enforces plain-ASCII files and installer and engine consistency.

[1.0.0]: https://github.com/aihxp/uxauditor/releases/tag/v1.0.0
