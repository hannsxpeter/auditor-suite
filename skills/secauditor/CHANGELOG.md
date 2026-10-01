# Changelog

All notable changes to secauditor are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Since 2026-07-14 the
skill versions with the auditor-suite release train named in the hub
[`VERSION`](../../VERSION) file.

## [auditor-suite 1.2.0] - 2026-10-01

Released with productauditor, the suite's eighth auditor. The cards now name
the product topics that moved to it, and the shared scripts pick leads more
fairly and gain fixes.

### Changed

- `SKILL.md`: the judgment notes hand plan gates and quotas, paid access that
  waits for a confirmed payment, an unreleased feature's route that skips the
  release flag, public API deprecation and versioning, and customer-facing
  encryption guarantees to productauditor.
- `AUTHZ.md`: the Not here line hands plan gates, plan limits and quotas, and
  the plan catalog to productauditor ENT, and keeps a plan, price, credit, or
  balance value the client sets in AUTHZ-R3, except a plan or paid flag set on
  the checkout success or return request (productauditor BILL-R1). AUTHZ-R3's
  Confirm now lists plan among the protected fields, and its lead pattern in
  `patterns.tsv` matches plan and plan_id fields taken from a request.
- `APISEC.md`: the Not here line hands deprecation signals and breaking-change
  versioning of the product's own public API (productauditor SHIP-R5, SHIP-R6)
  and an unreleased feature's route that skips the release flag the UI checks
  (productauditor SHIP-R2) to productauditor.
- `CRYPTO.md`: the Not here line hands customer-facing encryption guarantees
  the code contradicts to productauditor CLM-R5.
- `SKILL.md`: when a probe is wrong and you move a dimension between the
  Active and Not applicable lines, keep its reason in parentheses, for example
  `AUTHN (sign-in is handled by the VPN gateway)`; `check-report.sh` now
  requires one.
- `scan.sh`: when a card has more leads than `--max` (12 by default), it
  picks the ones it shows round-robin across files in path order (the first
  lead of each file, then the second of each, until the cap) and still prints
  them in path and line order. Before, it showed the first 12 in path order,
  so one file full of hits hid every file after it. `scan.sh --help` now
  explains `--max` and the selection.
- The scripts read an optional `SCAN_SKIP_RE` from `assets/skill.conf`, a
  regex of paths this auditor's scans and probes skip. secauditor sets none, so
  the setting changes nothing here.
- Scans skip `productaudit.md`, the new auditor's report, as they skip the
  other reports.

### Fixed

- SECRET-R5 (secrets written to logs, errors, or image layers) is now tagged
  `(quick)`, with flag `q` on its `patterns.tsv` row. Its Severity reaches
  Critical when the logs or images are shared outside the team, so `quick`
  mode now checks it.
- On macOS and with gawk, files such as `admin.js` and `admin.css` are no
  longer dropped from scans and probes as if they were minified bundles: the
  scripts now pass regexes to awk through `ENVIRON`, which keeps their
  backslashes.
- The file list leaves out symlinks, submodules, and tracked files that are
  deleted or outside a sparse checkout, so ripgrep and grep search the same
  files and no scan follows a link out of the project.
- Surface probes take their first hit in path and line order, so
  `inventory.sh` and `new-report.sh` cite the same hit on every run; ripgrep
  prints files in no fixed order.
- Reports are never written through a symlink, and the temporary file for a
  report write stays in the project, beside the report. `score.sh --write`
  keeps the report's permission bits and refuses a read-only report instead
  of replacing it.
- `check-report.sh` requires every dimension in exactly one of the Active and
  Not applicable lines (Not assessed in `only=` mode), with a reason in
  parentheses for each not-applicable dimension.
- Only the IDs after "Members:" count as systemic-pattern members, and CWE,
  CVE, and hash names (such as SHA-256) in a root fix or Related line are no
  longer read as finding IDs.
- `new-report.sh --mode only=` normalizes its list: spaces and empty items
  are dropped, and each ID is kept once.
- Leads no longer depend on the user's ripgrep config, `GREP_OPTIONS`, or
  locale.
- Projects inside a folder that an outer repository ignores are scanned.

## [auditor-suite 1.1.0] - 2026-09-26

Restructured so the skill works for small and local models as well as frontier
models. The audit knowledge is preserved; its shape changed.

### Changed

- `SKILL.md` is now a short spine (about 1,900 tokens, down from about 12,300):
  contract, modes, an eight-step workflow checklist, the dimension table, and
  judgment notes. Detail moved to files read only when a step needs them.
- Each dimension's checklist became rule cards in `references/<DIM>.md`: where
  to look, how to confirm, when it is not a finding, severity, fix, and how to
  verify the fix. The eleven dimensions and their weights are unchanged.
- Scores are computed by `scripts/score.sh` from the findings (deductions per
  finding, then caps), so re-runs are comparable. Suspected findings count half
  and never cap a score; two Critical findings cap a dimension at 59 and the
  overall at 69.
- Findings drop the `Owner` field (the ID prefix is the owning dimension) and
  must quote the cited code in Evidence; `check-report.sh` verifies it.
- The finding bucket rules now cover every finding: Medium findings go to a new
  Schedule bucket, and Likely High or Critical findings are no longer dropped
  from "What to fix first".

### Added

- Modes: `quick` (Critical-class cards only, no score), `only=DIM,DIM`, and a
  path scope.
- Read-only scripts: `inventory.sh`, `scan.sh`, `new-report.sh`, `score.sh`,
  `check-report.sh`.
- `references/example-report.md` (validated in CI), `references/facts.md`
  (dated OWASP 2025 and 2021 mapping, supply-chain incidents), and an eval case
  under `evals/secauditor/`.
- New cards for checks that were implicit before: identity headers trusted
  from the client (AUTHN-R8), webhook signing (APISEC-R5), and third-party API
  responses as untrusted input (APISEC-R6).

### Fixed

- Overlaps inside the skill now have one owner each: excessive data exposure
  (was in both AUTHZ and APISEC) is AUTHZ-R6; SSRF (was in both INJ and APISEC)
  is INJ-R4; rate limits (were in MISCFG, APISEC, and AUTHN) are AUTHN-R4 for
  login, MFA, and reset and APISEC-R1 elsewhere; CORS and verbose errors are
  MISCFG only; outbound TLS verification is CRYPTO-R3 only; secrets in logs are
  SECRET-R5 only.

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
