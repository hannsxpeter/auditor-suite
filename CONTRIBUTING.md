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
2. **No em dashes, en dashes, arrows, box-drawing characters, decorative
   symbols, or emojis** anywhere in the tree. Use a comma, colon, parentheses,
   or two sentences instead of a dash; use words instead of arrows.
   `bash scripts/lint.sh unicode-clean` checks this mechanically, in tracked
   files and in untracked files that git does not ignore, and CI fails the
   build on violations.
3. **Bash 3.2 compatibility** for every shell script. macOS ships bash 3.2 as
   `/bin/bash`, and the installer must run there. No associative arrays, no
   `mapfile`, no `${var,,}`; `lint.sh bash-syntax` flags them. Keep awk POSIX
   (BSD awk, mawk, and gawk). Pass a regex to awk through ENVIRON
   (`as_match_lines` in `shared/scripts/_lib.sh`), never `awk -v`: BSD awk and
   gawk strip backslashes from -v values. CI runs the lint on Ubuntu and under
   macOS `/bin/bash` 3.2 and BSD awk, and again on Ubuntu with awk set to
   mawk, then gawk.
4. **`skills/<skill-name>/` is the source of truth; `shared/` is the source of
   the shared core.** The `plugins/` tree is vendored packaging, and each
   skill's copies of the protocol, template, and scripts are vendored from
   `shared/`. Edit the protocol, template, or scripts only in `shared/`. After
   any change, run `bash scripts/refresh-plugins.sh` (it runs
   `scripts/sync-shared.sh` first) in the same patch, and verify with
   `bash scripts/lint.sh shared-sync plugin-sync` (the lint runs every check
   it is given).
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
bash tests/lint-selftest.sh
```

All checks must pass. The lint runs `tests/run.sh` and `tests/install.sh`
itself (check `script-tests`); run `tests/run.sh` directly to see every
failing assertion. `tests/lint-selftest.sh` injects violations for eight of
the thirteen lint checks and proves each one fails (`patterns-valid`,
`examples-valid`, `evals-structure`, `suite-release`, and `changelog-top`
have no case yet); if you add or fix a check, add a case. CI runs the lint
and the self-test on Ubuntu and on macOS, plus the lint under mawk and gawk,
so a green run on one platform can still fail on the other.

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
5. Run `bash scripts/refresh-plugins.sh`, then the checks in "Before you open
   a PR".
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
   [`MAINTAINING.md`](MAINTAINING.md): `VERSION`, the README badges and
   release link, the SUITE.md release-train line, the marketplace metadata,
   every plugin manifest, and `AS_SUITE_VERSION` in `shared/scripts/_lib.sh`
   move together, and the lint enforces their agreement; also update the
   banner in each skills/*/references/example-report.md, which no check reads.
4. Run `bash scripts/refresh-plugins.sh`, then the checks in "Before you open
   a PR".
5. Open one PR with the whole coordinated change; do not split a version bump
   across PRs.

## Adding an auditor

There is no list of skill names to edit: `scripts/lint.sh`,
`scripts/sync-shared.sh`, and `scripts/refresh-plugins.sh` take the roster
from the directories under `skills/`. Build `skills/<name>/` as
[docs/AUTHORING.md](docs/AUTHORING.md) describes, then run
`bash scripts/lint.sh suite-registry` and add what it names: the vendored
plugin and its `.claude-plugin/plugin.json`, the marketplace entry, the meta
plugin dependency, `evals/<name>/`, `tests/fixtures/<name>/`, the README and
SUITE.md table rows, and the report name in `AS_EXCLUDE_RE` in
`shared/scripts/_lib.sh`. No check reads the auditor count in README.md,
SUITE.md, and the marketplace and meta plugin descriptions, or the list in
AGENTS.md; update those by hand. Then run the checks in "Before you open a
PR". The steps are in [docs/AUTHORING.md](docs/AUTHORING.md), section 8.

## Commit and PR style

- Imperative subject lines ("fix dbauditor index rubric weight," not "fixed").
- Explain the why in the body when the diff alone does not carry it.
- PRs should say what an auditor now catches (or stops flagging) that it did
  not before; a before/after report snippet or an eval result on a small model
  is the best evidence.

## Conduct

Be respectful. See [`CODE_OF_CONDUCT.md`](CODE_OF_CONDUCT.md). Security
reports go through [`SECURITY.md`](SECURITY.md), not public issues.
