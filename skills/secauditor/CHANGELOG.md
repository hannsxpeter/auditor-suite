# Changelog

All notable changes to secauditor are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Since 2026-07-14 the
skill versions with the auditor-suite release train named in the hub
[`VERSION`](../../VERSION) file.

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
