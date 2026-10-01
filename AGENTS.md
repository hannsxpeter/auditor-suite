# Agent instructions for auditor-suite

## Project shape

This repository is the auditor-suite monorepo. The canonical skill sources live under `skills/<skill-name>/`. The `plugins/<skill-name>/` tree is vendored packaging for Claude Code plugin installs and must stay synchronized with the canonical skill sources.

The suite has eight auditors:

- `codeauditor`
- `secauditor`
- `dbauditor`
- `llmauditor`
- `seoauditor`
- `uiauditor`
- `uxauditor`
- `productauditor`

Each skill directory carries:

- `SKILL.md`: the short spine (contract, modes, workflow, dimension table, judgment notes), under 5,000 tokens.
- `references/`: `<DIM>.md` rule cards per dimension, `example-report.md`, optional `facts.md` and domain files, and the shared `protocol.md`.
- `scripts/`: the shared read-only scripts (`inventory.sh`, `scan.sh`, `new-report.sh`, `score.sh`, `check-report.sh` and their helpers).
- `assets/`: `skill.conf`, `dimensions.tsv`, `patterns.tsv`, `surfaces.tsv`, and the shared `report-template.md`.
- `README.md`, `CHANGELOG.md`, and `LICENSE`.

The hub owns everything else: `shared/` (the one editable copy of the protocol, template, and scripts), the installer, linter, tests, eval runner, CI, marketplace, and docs. Eval cases live in `evals/<skill-name>/`; example-report fixtures in `tests/fixtures/<skill-name>/`. How an auditor is built: `docs/AUTHORING.md` (section 8 covers adding one; `bash scripts/lint.sh suite-registry` names every place a new auditor must still appear, except the auditor count and the list above, which no check reads). Why: `docs/ARCHITECTURE.md`.

## Required checks

Run these before handing off repo changes:

```bash
bash scripts/lint.sh --verbose
bash tests/run.sh
bash tests/lint-selftest.sh
```

The lint runs `tests/run.sh` and `tests/install.sh` itself (check `script-tests`). `tests/lint-selftest.sh` injects violations for eight of the thirteen lint checks (all but `patterns-valid`, `examples-valid`, `evals-structure`, `suite-release`, and `changelog-top`) and proves each one fails; when you add or fix a check in `scripts/lint.sh`, add a case for it there. Run `bash tests/install.sh` directly when `install.sh` or `uninstall.sh` changes, to see every failure.

## Edit rules

- Do not introduce em dashes, en dashes, unicode arrows, box-drawing characters, symbols or dingbats, or emojis. The lint fails the build on them, in tracked files and in untracked files that git does not ignore.
- Keep shell scripts compatible with bash 3.2, the default bash on macOS. Do not use associative arrays, namerefs, `mapfile`, `readarray`, or case-changing expansions such as `${var,,}`; `lint.sh bash-syntax` flags them. Keep awk POSIX (BSD awk, mawk, and gawk). Pass a regex to awk through ENVIRON (`as_match_lines` in `shared/scripts/_lib.sh`), never `awk -v`: BSD awk and gawk strip backslashes from -v values.
- Every auditor is read-only by contract: never add behavior that edits source files, runs the app, connects to live systems, or calls models. The only file an audit writes is its own report. The bundled scripts may read files and print; only `new-report.sh` and `score.sh --write` write, and only the report.
- Edit shared content only in `shared/`, then run `bash scripts/sync-shared.sh`. Never edit a skill's copy of a shared file; `lint.sh shared-sync` fails on any difference.
- Treat `skills/<skill-name>/` as source of truth. After skill changes, run `bash scripts/refresh-plugins.sh` to re-vendor the plugin packaging (it runs sync-shared first), then verify with `bash scripts/lint.sh plugin-sync`.
- A plugin manifest's and the marketplace's description must equal the skill's frontmatter description; lint enforces it.
- Search patterns must work in both `grep -E` and ripgrep (`lint.sh patterns-valid`); see docs/AUTHORING.md section 4.
- Keep each example report valid (`lint.sh examples-valid`) and never let it audit the eval fixture.
- When a skill behavior changes, update that skill's top `CHANGELOG.md` entry in the same patch.
- Version bumps are suite-wide: update `VERSION`, the README version and release badges (and the release link), the SUITE.md release-train line, the marketplace metadata, every plugin manifest, and `AS_SUITE_VERSION` in `shared/scripts/_lib.sh` together. The lint enforces agreement. Also update the "(auditor-suite x.y.z)" banner in each skills/*/references/example-report.md; no check reads it.
- Do not run `scripts/eval.sh` or `claude plugin eval` without the maintainer's go-ahead: they call models and cost money.
- Do not commit local harness worktrees or session state under `.claude/`, or eval results under `evals/results/`.

## Maintenance references

- `README.md`: user-facing overview and install paths.
- `SUITE.md`: the suite map, auditor boundaries, the contract, and composition principles.
- `docs/ARCHITECTURE.md`, `docs/AUTHORING.md`, `docs/DRIFT.md`: design, authoring rules, and the drift log.
- `MAINTAINING.md`: maintainer rituals and version-bump rules.
- `CONTRIBUTING.md`: contributor workflow and PR standards.
- `evals/README.md`: running and reading the eval cases.
