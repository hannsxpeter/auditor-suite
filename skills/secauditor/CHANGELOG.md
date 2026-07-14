# Changelog

All notable changes to secauditor are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Since 2026-07-14 the
skill versions with the auditor-suite release train named in the hub
[`VERSION`](../../VERSION) file.

## [auditor-suite 1.0.0] - 2026-07-14

Moved into the [auditor-suite](https://github.com/hannsxpeter/auditor-suite)
monorepo as `skills/secauditor/`, with the standalone repo's full git history
preserved. Standalone versioning is retired; the skill now follows the
auditor-suite release train.

### Changed

- The standalone `.claude-plugin/plugin.json` manifest is retired; plugin
  packaging now lives in the hub under `plugins/secauditor/`.
- The audit content in `SKILL.md` is unchanged from standalone 0.1.0.

## [0.1.0] - 2026-06-18

First standalone release from `hannsxpeter/secauditor`: the read-only security
audit skill scoring a codebase across 11 OWASP/CWE-grounded dimensions and
writing a prioritized `secaudit.md`. Full details in the git history under
`skills/secauditor/`.
