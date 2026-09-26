# Maintaining auditor-suite

Maintainer rituals for the hub. Contributors should read
[`CONTRIBUTING.md`](CONTRIBUTING.md) first; this document is about the
coordination work that keeps the suite coherent.

## The version model

The suite versions as one release train. The root `VERSION` file names the
train. When the train bumps, these move together, and
`bash scripts/lint.sh suite-release` plus `plugin-sync` enforce the agreement:

- `VERSION`
- README version badge (`version-x.y.z-blue`) and release badge
  (`release-vx.y.z-blue`)
- `SUITE.md` "Release train: x.y.z" line
- `.claude-plugin/marketplace.json` metadata version
- every `plugins/*/.claude-plugin/plugin.json` version
- `AS_SUITE_VERSION` in `shared/scripts/_lib.sh` (printed in every report banner)

Semver at suite level: patch for report or doc fixes, minor for new rubric
dimensions, defect classes (rule cards), modes, or scoring rules, major for
changes to the read-only contract, report paths, the report format's section
or field names, or skill names.

## Ritual: single-skill patch

1. Land the contributor PR (or your own) per CONTRIBUTING.md.
2. Confirm the vendored plugin copy moved with it (`lint.sh plugin-sync`).
3. No version bump needed unless behavior changed in a way consumers must
   pin; batch small patches into the next train.

## Ritual: release train

1. Decide the new train number `x.y.z`.
2. Update `VERSION`.
3. Update the README version and release badges, and the SUITE.md
   release-train line.
4. Update the marketplace metadata version and every plugin manifest version.
5. Update `AS_SUITE_VERSION` in `shared/scripts/_lib.sh` and run
   `bash scripts/sync-shared.sh`.
6. Add the `## [x.y.z] - YYYY-MM-DD` entry to the hub `CHANGELOG.md`; add
   per-skill entries for skills whose behavior changed.
7. `bash scripts/refresh-plugins.sh`
8. `bash scripts/lint.sh --verbose` and `bash tests/run.sh` until green.
9. For a minor or major train, run the eval cases for the skills that changed
   on at least one small model (see `evals/README.md`) and record the scores
   in the hub CHANGELOG entry.
10. Merge to `main` via PR; CI must be green.
11. Tag and release:

   ```bash
   git tag -a vx.y.z -m "auditor-suite x.y.z"
   git push origin vx.y.z
   gh release create vx.y.z --title "auditor-suite x.y.z" --notes-file <notes>
   ```

See [`RELEASE-CHECKLIST.md`](RELEASE-CHECKLIST.md) for the compact version.

## Ritual: lint regression recovery

If CI lint fails on `main` (a check regressed or a bad merge landed):

1. Reproduce locally: `bash scripts/lint.sh --verbose`.
2. Fix forward with a single revert-or-repair commit; do not stack unrelated
   changes on a red main.
3. If the lint itself is wrong (a check fails when it should not), fix the
   check in `scripts/lint.sh` and say so in the commit body; a check that
   fails to fail is worse, so never loosen a check to make a bad tree pass.

## The shared core

`shared/` holds the only editable copy of the protocol
(`shared/references/protocol.md`), the report template
(`shared/assets/report-template.md`), and the scripts (`shared/scripts/`).
`bash scripts/sync-shared.sh` copies them into every skill; `lint.sh
shared-sync` fails on any difference. A change to the scoring rules touches
both `shared/references/protocol.md` (for the model) and
`shared/scripts/_score.awk` (for the machine), and `tests/run.sh` must be
updated to pin the new arithmetic.

## Plugin packaging

`plugins/<skill>/skills/<skill>/` must carry a byte-identical copy of the
canonical runtime payload: `SKILL.md`, `references/`, `scripts/`, and
`assets/`. The only sanctioned way to update the vendored copies is
`bash scripts/refresh-plugins.sh`. Manifest edits (descriptions, keywords) are
manual; each plugin's description and its marketplace entry must equal the
skill's frontmatter description, and lint enforces it.

## Ritual: refresh dated facts

`references/facts.md` in each skill carries a "Last reviewed" date. Review
them at least every six months, and whenever a standard the cards cite
publishes a new edition (OWASP, WCAG, provider API changes, search-engine
policy changes). Verify each fact against its source, update the date, and
note the review in the skill's CHANGELOG.

## Ritual: evals

Eval cases live in `evals/<skill>/full-audit/` and run with
`bash scripts/eval.sh <skill>` (see `evals/README.md`). They call models with
your credentials; set `--max-cost-usd` and pass `--no-publish`. Run them when a
spine, the protocol, the scripts, or a skill's cards change materially, and on
new model releases you intend to support.

## History and lineage

The seven skills were consolidated from standalone repos on 2026-07-14 with
full history via subtree merges. To trace a skill across the boundary use
`git log -- skills/<skill>/`; the subtree merge connects the standalone
commits as ancestors of main. The pre-consolidation layouts
(engine files, per-repo installers, plugin manifests) are all reachable in
history if archaeology is ever needed.
