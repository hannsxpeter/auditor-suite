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
4. **`skills/<skill-name>/` is the source of truth; `shared/` is the source of
   the shared core.** The `plugins/` tree is vendored packaging, and each
   skill's copies of the protocol, template, and scripts are vendored from
   `shared/`. Edit the protocol, template, or scripts only in `shared/`. After
   any change, run `bash scripts/refresh-plugins.sh` (it runs
   `scripts/sync-shared.sh` first) in the same patch, and verify with
   `bash scripts/lint.sh shared-sync plugin-sync`.
5. **Small models are first-class.** Every instruction must be executable by a
   Haiku-class model: numbered steps, exact commands, one instruction per
   sentence, a clear stop condition. Checks belong in rule cards with a
   Confirm and a Not-a-finding-if line, not in prose. See
   [docs/AUTHORING.md](docs/AUTHORING.md).
6. **Changelog with the change.** A behavior change to a skill updates that
   skill's `CHANGELOG.md` top entry in the same PR. A hub change (installer,
   lint, packaging, docs) updates the hub `CHANGELOG.md`.

## Before you open a PR

```bash
bash scripts/lint.sh --verbose
bash tests/run.sh
```

All checks must pass. CI runs the same lint (which includes the tests), so a
green local run means a green build.

## Single-skill patch

The common case: adding or sharpening a rule card, a search pattern, a
surface probe, or a dimension's judgment notes in one auditor.

1. Edit the skill's files: a card in `references/<DIM>.md`, its lead in
   `assets/patterns.tsv`, a probe in `assets/surfaces.tsv`, or the spine.
2. If the change affects the example report (a renamed card, a new card in an
   active dimension), update `references/example-report.md` and re-check it:
   `lint.sh examples-valid`.
3. If a new Critical-class card lands, consider a planted defect for it in
   `evals/<skill-name>/full-audit/` (and a line in ANSWERS.md).
4. Add a top entry to `skills/<skill-name>/CHANGELOG.md` describing the change.
5. Run `bash scripts/refresh-plugins.sh`, `bash scripts/lint.sh --verbose`, and
   `bash tests/run.sh`.
6. Open a PR touching only that skill's directory, its eval case and fixture,
   and its vendored plugin copy. One skill per PR keeps review tractable.

## Coordinated cross-suite patch

For changes that touch several auditors at once (the shared protocol, the
report template, the scripts, a scoring rule, a release train):

1. Make shared changes in `shared/` and skill-specific changes in each
   affected skill. A scoring change updates both
   `shared/references/protocol.md` and `shared/scripts/_score.awk`, plus
   `tests/run.sh`.
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
  not before; a before/after report snippet or an eval result on a small model
  is the best evidence.

## Conduct

Be respectful. See [`CODE_OF_CONDUCT.md`](CODE_OF_CONDUCT.md). Security
reports go through [`SECURITY.md`](SECURITY.md), not public issues.
