# Changelog

All notable changes to the auditor-suite hub are documented here. The format is
based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the suite
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html) at the
release-train level: the root `VERSION` file names the train, and all seven
skills plus the plugin packaging publish that train together.

Per-skill history from before the consolidation lives in each
`skills/<skill-name>/CHANGELOG.md`.

## [1.0.0] - 2026-07-14

First release of the auditor-suite monorepo: seven previously standalone
auditor repos consolidated into one hub, ready-suite style.

### Added

- Hub documentation: `README.md` (overview, install paths, lineage),
  `SUITE.md` (suite map, auditor boundaries, read-only contract),
  `AGENTS.md` (agent brief), `CONTRIBUTING.md`, `MAINTAINING.md`,
  `SECURITY.md`, `CODE_OF_CONDUCT.md`, and `RELEASE-CHECKLIST.md`.
- One-command installer (`install.sh`) and uninstaller (`uninstall.sh`)
  covering Claude Code, Codex, Cursor, and the neutral Agent Skills path
  read by pi and OpenClaw. Symlink-based and idempotent.
- Claude Code plugin marketplace (`.claude-plugin/marketplace.json`) with
  seven specialist plugins plus an `auditor-suite` meta plugin that bundles
  them all, vendored under `plugins/<skill-name>/`.
- Meta-linter (`scripts/lint.sh`) enforcing skill frontmatter validity,
  plugin-packaging sync, suite-wide version agreement, changelog discipline,
  a unicode-clean tree (no em dashes, en dashes, or decorative arrows), and
  bash-3.2 script syntax. Runs in CI on every push and pull request
  (`.github/workflows/lint.yml`).
- `scripts/refresh-plugins.sh` to re-vendor plugin packaging from the
  canonical skill sources.

### Changed

- Consolidated seven standalone repos into `skills/<skill-name>/` via subtree
  merges, preserving the full git history of every repo:

  | Skill | Former repo | Final standalone version |
  |---|---|---|
  | codeauditor | `hannsxpeter/codeauditor` | 1.0.0 |
  | secauditor | `hannsxpeter/secauditor` | 0.1.0 |
  | dbauditor | `hannsxpeter/dbauditor` | 0.1.1 |
  | llmauditor | `hannsxpeter/llmauditor` | 0.1.0 |
  | seoauditor | `hannsxpeter/seoauditor` | 0.1.0 |
  | uiauditor | `hannsxpeter/uiauditor` | 0.1.0 |
  | uxauditor | `hannsxpeter/uxauditor` | 1.1.0 |

- Normalized every skill to the Agent Skills layout `skills/<name>/SKILL.md`.
  For codeauditor and uxauditor, which shipped as frontmatter-less engine
  files rendered by a per-repo installer, valid `name` and `description`
  frontmatter was synthesized from their installer metadata; the audit
  engine bodies are unchanged.
- Retired per-repo scaffolding superseded by the hub: standalone installers,
  per-repo CI, `.claude-plugin/` manifests, gitignores, editorconfigs, and
  per-repo policy docs. Each skill keeps its README, CHANGELOG, and LICENSE.
- Retired standalone versioning in favor of the suite release train.
