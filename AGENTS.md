# Agent instructions for auditor-suite

## Project shape

This repository is the auditor-suite monorepo. The canonical skill sources live under `skills/<skill-name>/`. The `plugins/<skill-name>/` tree is vendored packaging for Claude Code plugin installs and must stay synchronized with the canonical skill sources.

The suite has seven auditors:

- `codeauditor`
- `secauditor`
- `dbauditor`
- `llmauditor`
- `seoauditor`
- `uiauditor`
- `uxauditor`

Each skill directory carries `SKILL.md` (canonical content), `README.md`, `CHANGELOG.md`, and `LICENSE`. The hub owns everything else: installer, linter, CI, marketplace, and policy docs.

## Required checks

Run the suite linter before handing off repo changes:

```bash
bash scripts/lint.sh --verbose
```

## Edit rules

- Do not introduce em dashes, en dashes, decorative unicode arrows, box-drawing characters, or emojis. The lint fails the build on them.
- Keep shell scripts compatible with bash 3.2, the default bash on macOS. Do not use associative arrays, `mapfile`, or `${var,,}`.
- Every auditor is read-only by contract: never add behavior that edits source files, runs the app, connects to live systems, or calls models. The only file an audit writes is its own report.
- Treat `skills/<skill-name>/` as source of truth. After canonical skill changes, run `bash scripts/refresh-plugins.sh` to re-vendor the plugin packaging, then verify with `bash scripts/lint.sh plugin-sync`.
- When a skill behavior changes, update that skill's top `CHANGELOG.md` entry in the same patch.
- Version bumps are suite-wide: update `VERSION`, the README version and release badges, the SUITE.md release-train line, the marketplace metadata, and every plugin manifest together. The lint enforces agreement.
- Do not commit local harness worktrees or session state under `.claude/`.

## Maintenance references

- `README.md`: user-facing overview and install paths.
- `SUITE.md`: the suite map, auditor boundaries, and composition principles.
- `MAINTAINING.md`: maintainer rituals and version-bump rules.
- `CONTRIBUTING.md`: contributor workflow and PR standards.
