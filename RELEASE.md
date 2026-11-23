# Auditor Suite 1.3.0

Product surface release: npm package, gamified README, and docs cleanup.
Auditor rubrics and scoring are unchanged from 1.2.0.

## Highlights

- Install with `npx @hxp-tools/auditor-suite@latest` (materializes to `~/.auditor-suite`, then runs the existing bash installer).
- README relaunch with hero, quest map, and scorecard graphics under `assets/`.
- Quick proof path: [docs/quick-proof.md](docs/quick-proof.md).
- Removed historical `docs/DRIFT.md` and `docs/STANDALONE-ARCHIVE.md` from the product tree (still in git history).

## Install

```bash
npx @hxp-tools/auditor-suite@latest
```

Claude Code plugin (pick one method per host):

```text
/plugin marketplace add hannsxpeter/auditor-suite
/plugin install auditor-suite@auditor-suite
```

## Upgrade

- From a prior clone install: `git pull` and re-run `bash install.sh` if needed.
- From npm: `npx @hxp-tools/auditor-suite@latest` again.
- Uninstall: `npx @hxp-tools/auditor-suite@latest --uninstall`

## Verify

```bash
npm run release:check
```
