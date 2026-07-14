# Contributing to auditor-suite

Thanks for wanting to improve the suite. This document covers the contribution
model, the ground rules the lint enforces, and how to land the two kinds of
change: a single-skill patch and a coordinated cross-suite patch.

## Ground rules

1. **The read-only contract is non-negotiable.** Every auditor reads code and
   writes exactly one report. A contribution that makes an auditor edit
   source, run the app, connect to a live database, call a model, or crawl a
   site will be declined regardless of how useful it is. That behavior belongs
   in a different kind of tool.
2. **No em dashes, en dashes, decorative arrows, or emojis** anywhere in the
   tree. Use a comma, colon, parentheses, or two sentences instead of a dash;
   use words instead of arrows. `bash scripts/lint.sh unicode-clean` checks
   this mechanically, and CI fails the build on violations.
3. **Bash 3.2 compatibility** for every shell script. macOS ships bash 3.2 as
   `/bin/bash`, and the installer must run there. No associative arrays, no
   `mapfile`, no `${var,,}`.
4. **`skills/<skill-name>/` is the source of truth.** The `plugins/` tree is
   vendored packaging. If you change a `SKILL.md`, run
   `bash scripts/refresh-plugins.sh` in the same patch so the packaging stays
   byte-identical, and verify with `bash scripts/lint.sh plugin-sync`.
5. **Changelog with the change.** A behavior change to a skill updates that
   skill's `CHANGELOG.md` top entry in the same PR. A hub change (installer,
   lint, packaging, docs) updates the hub `CHANGELOG.md`.

## Before you open a PR

```bash
bash scripts/lint.sh --verbose
```

All checks must pass. CI runs the same script, so a green local lint means a
green build.

## Single-skill patch

The common case: improving one auditor's dimensions, rubric, defect classes,
or report format.

1. Edit `skills/<skill-name>/SKILL.md`.
2. Add a top entry to `skills/<skill-name>/CHANGELOG.md` describing the change.
3. Run `bash scripts/refresh-plugins.sh`.
4. Run `bash scripts/lint.sh --verbose`.
5. Open a PR touching only that skill's directory plus its vendored plugin
   copy. One skill per PR keeps review tractable.

## Coordinated cross-suite patch

For changes that touch several auditors at once (a shared report convention, a
new discipline rule, a release train):

1. Make the change across the affected `skills/*/SKILL.md` files.
2. Update every affected skill CHANGELOG plus the hub CHANGELOG.
3. If the release train bumps, follow the version ritual in
   [`MAINTAINING.md`](MAINTAINING.md): `VERSION`, README badges, the SUITE.md
   release-train line, marketplace metadata, and every plugin manifest move
   together. The lint enforces agreement.
4. Run `bash scripts/refresh-plugins.sh` and `bash scripts/lint.sh --verbose`.
5. Open one PR with the whole coordinated change; do not split a version bump
   across PRs.

## Commit and PR style

- Imperative subject lines ("fix dbauditor index rubric weight," not "fixed").
- Explain the why in the body when the diff alone does not carry it.
- PRs should say what an auditor now catches (or stops flagging) that it did
  not before; a before/after report snippet is the best evidence.

## Conduct

Be respectful. See [`CODE_OF_CONDUCT.md`](CODE_OF_CONDUCT.md). Security
reports go through [`SECURITY.md`](SECURITY.md), not public issues.
