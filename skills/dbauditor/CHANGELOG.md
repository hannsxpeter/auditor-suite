# Changelog

All notable changes to dbauditor are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Since 2026-07-14 the
skill versions with the auditor-suite release train named in the hub
[`VERSION`](../../VERSION) file.

## [auditor-suite 1.0.0] - 2026-07-14

Moved into the [auditor-suite](https://github.com/hannsxpeter/auditor-suite)
monorepo as `skills/dbauditor/`, with the standalone repo's full git history
preserved. Standalone versioning is retired; the skill now follows the
auditor-suite release train.

### Changed

- The standalone `.claude-plugin/plugin.json` manifest is retired; plugin
  packaging now lives in the hub under `plugins/dbauditor/`.
- The audit content in `SKILL.md` is unchanged from standalone 0.1.1.

## [0.1.1] - 2026-06-18

Standalone release from `hannsxpeter/dbauditor`. Documented dual invocation:
`/dbauditor` in Claude Code and `$dbauditor` in Codex. Full details in the git
history under `skills/dbauditor/`.

## [0.1.0] - 2026-06-18

First standalone release: the read-only database audit skill covering schema,
relationships, indexing, queries, transactions, migrations, data protection,
search, and scale, writing a scored, prioritized `dbaudit.md`.
