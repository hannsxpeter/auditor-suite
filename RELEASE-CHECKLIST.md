# Release checklist

Compact version of the release-train ritual in
[`MAINTAINING.md`](MAINTAINING.md). Work top to bottom; every box must be
checked before tagging.

- [ ] `VERSION` updated to the new train `x.y.z`
- [ ] README version badge says `version-x.y.z-blue`
- [ ] README release badge says `release-vx.y.z-blue` and links the new tag
- [ ] `SUITE.md` says `Release train: x.y.z`
- [ ] `.claude-plugin/marketplace.json` metadata version is `x.y.z`
- [ ] Every `plugins/*/.claude-plugin/plugin.json` version is `x.y.z`
- [ ] `AS_SUITE_VERSION` in `shared/scripts/_lib.sh` is `x.y.z` and `scripts/sync-shared.sh` has run
- [ ] Each `skills/*/references/example-report.md` banner says `(auditor-suite x.y.z)` (no check reads it)
- [ ] If cards, spines, or example reports changed: `docs/ARCHITECTURE.md` section 9 re-measured (bytes divided by four), and the counts in the hub CHANGELOG entry match
- [ ] Hub `CHANGELOG.md` has a top `## [x.y.z] - YYYY-MM-DD` entry
- [ ] Per-skill `CHANGELOG.md` entries added for changed skills
- [ ] If the train adds an auditor: `bash scripts/lint.sh suite-registry` passes (plugin, marketplace entry, meta plugin dependency, eval case, fixture, README and SUITE.md rows, `AS_EXCLUDE_RE`), and the auditor count in README.md, SUITE.md, and the marketplace and meta plugin descriptions, and the list in AGENTS.md, name the new total (no check reads them)
- [ ] `bash scripts/refresh-plugins.sh` run; vendored payloads byte-identical
- [ ] `bash scripts/lint.sh --verbose` fully green locally (it runs `tests/run.sh` and `tests/install.sh` through `script-tests`)
- [ ] `bash tests/run.sh` passes
- [ ] `bash tests/lint-selftest.sh` passes
- [ ] For a minor or major train: eval cases run for changed skills on a small model, scores recorded in the hub CHANGELOG
- [ ] PR merged to `main`; CI green on `main` in both jobs, `lint (ubuntu-latest)` and `lint (macos-latest)`
- [ ] Annotated tag `vx.y.z` ("auditor-suite x.y.z") pushed
- [ ] GitHub release created with notes
