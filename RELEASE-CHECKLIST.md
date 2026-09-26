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
- [ ] Hub `CHANGELOG.md` has a top `## [x.y.z] - YYYY-MM-DD` entry
- [ ] Per-skill `CHANGELOG.md` entries added for changed skills
- [ ] `bash scripts/refresh-plugins.sh` run; vendored payloads byte-identical
- [ ] `bash scripts/lint.sh --verbose` fully green locally
- [ ] `bash tests/run.sh` passes
- [ ] For a minor or major train: eval cases run for changed skills on a small model, scores recorded in the hub CHANGELOG
- [ ] PR merged to `main`; CI lint green on `main`
- [ ] Tag `vx.y.z` pushed
- [ ] GitHub release created with notes
