# SUPPLY: Dependencies and Software Supply Chain

Weight 9. Always active.
Owns: known-vulnerable dependencies, pinning and lockfiles, dependency confusion and typosquatting, install-time scripts and remote downloads, provenance and SBOMs, and the supply chain of the CI pipeline itself (third-party Actions, pull-request triggers).
Not here: secrets in CI (SECRET); CI token permissions and approvals (MISCFG); container base images (IAC).
Standards: OWASP A03:2025 (A06 and A08:2021), SLSA v1.x, CycloneDX and SPDX, OWASP CI/CD Top 10.
Read first: every manifest and lockfile, `.npmrc`, `pip.conf`, and registry config, and every CI workflow.

## Cards

### SUPPLY-R1 Dependency pinned to a version with published advisories (quick)
- Leads: `scan.sh SUPPLY-R1` lists manifest and lockfile lines for packages with a history of severe advisories.
- Confirm: a direct or locked dependency version falls in a range with a published advisory you know (for example lodash below 4.17.21, log4j-core 2.0 to 2.16, old axios, minimist, or jsonwebtoken majors). Reason from the version; you cannot run an audit tool, so state which advisory you mean and mark confidence Likely unless the lockfile pins the exact version.
- Not a finding if: the vulnerable function is provably unused and the advisory is limited to it (say so and keep it Low); an override or resolution forces a fixed version.
- Severity: Critical for a known-exploited remote code execution in reachable code; High for other high-severity advisories; Medium otherwise.
- Fix: upgrade to the fixed version (or add an override for a transitive), then run the ecosystem audit tool in CI.
- Verify the fix: `npm audit`, `pip-audit`, `osv-scanner`, or the equivalent reports no advisory for the package.
- Refs: CWE-1395, CWE-937, OWASP A03:2025

### SUPPLY-R2 Pull-request workflows run untrusted code with secrets (quick)
- Leads: `scan.sh SUPPLY-R2` lists `pull_request_target`, `workflow_run`, and `${{ github.event.* }}` inside `run:` steps.
- Confirm: a `pull_request_target` or `workflow_run` workflow checks out and runs the pull request's code while secrets or a write token are available, or untrusted event fields (issue titles, branch names, PR bodies) are interpolated into a shell `run:` step (Poisoned Pipeline Execution).
- Not a finding if: the workflow only labels or comments without checking out PR code, and event fields reach the shell through environment variables, not `${{ }}` interpolation.
- Severity: Critical: an outside contributor can steal secrets or push code.
- Fix: use `pull_request` for untrusted code, never check out PR heads in `pull_request_target`, and pass event fields through `env:` variables.
- Verify the fix: no `pull_request_target` job checks out `github.event.pull_request.head` and no `run:` step contains `${{ github.event`.
- Refs: CWE-94, OWASP CI/CD Top 10 (CICD-SEC-4)

### SUPPLY-R3 Third-party CI actions or images referenced by mutable tags
- Leads: `scan.sh SUPPLY-R3` lists `uses: owner/action@v1` and `@main` references and `:latest` images.
- Confirm: third-party Actions are pinned to a tag or branch instead of a full commit SHA, or images are pulled by `:latest` without a digest (the tj-actions/changed-files compromise in 2025 used a moved tag).
- Not a finding if: only first-party `actions/*` are used at major tags and the team accepts that trade-off in writing; everything else is SHA-pinned.
- Severity: High for Actions that see secrets; Medium otherwise.
- Fix: pin third-party Actions to full commit SHAs (with the tag in a comment) and let Dependabot or Renovate update them.
- Verify the fix: every non-`actions/*` `uses:` line ends in a 40-character SHA.
- Refs: CWE-829, OWASP CI/CD Top 10 (CICD-SEC-3), SLSA

### SUPPLY-R4 No lockfile, floating versions, or installs that ignore the lockfile
- Leads: `scan.sh SUPPLY-R4` lists `^`, `~`, `*`, `latest`, and unbounded `>=` specifiers and `npm install` in CI.
- Confirm: there is no committed lockfile, versions float, the lockfile is out of step with the manifest, or CI runs `npm install` or `pip install` without hash enforcement instead of `npm ci`, `yarn --immutable`, or `pip install --require-hashes`.
- Not a finding if: a lockfile is committed and CI installs from it strictly.
- Severity: Medium; High for a published library or a deploy pipeline that builds releases.
- Fix: commit the lockfile and install strictly from it in CI.
- Verify the fix: CI logs show the strict install command and the lockfile is tracked.
- Refs: CWE-1357, OWASP A03:2025

### SUPPLY-R5 Internal package names can be hijacked, or names look typosquatted
- Leads: `scan.sh SUPPLY-R5` lists scoped and internal-looking package names and registry settings.
- Confirm: internal packages use unscoped names with no private-registry pinning in `.npmrc` or `pip.conf` (dependency confusion), or a dependency name is a near miss of a popular package (`reqeusts`, `crossenv`) or a low-download package pinned for core work.
- Not a finding if: internal packages are scoped and the scope is bound to the private registry.
- Severity: High for dependency confusion on names that exist only internally; Medium otherwise.
- Fix: scope internal packages and bind the scope to the private registry; replace suspicious packages.
- Verify the fix: `.npmrc` (or the equivalent) maps the internal scope to the private registry.
- Refs: CWE-427, CWE-1357, OWASP A03:2025

### SUPPLY-R6 Install or build scripts fetch and run unverified code
- Leads: `scan.sh SUPPLY-R6` lists `curl ... | sh`, `wget ... | bash`, `http://` downloads, and `postinstall` or `preinstall` hooks.
- Confirm: a Dockerfile, script, or CI step pipes a download into a shell or runs a binary without a checksum or signature check, downloads over HTTP, or the project depends on packages with install hooks while `ignore-scripts` is not set in CI.
- Not a finding if: the download is verified by checksum or signature before running.
- Severity: High in build or deploy paths; Medium in developer setup scripts.
- Fix: download over HTTPS, verify a pinned checksum or signature, and set `ignore-scripts` where hooks are not needed.
- Verify the fix: the step includes a checksum verification that fails on a modified file.
- Refs: CWE-494, OWASP A03:2025

## Also check
- Abandoned or archived packages with unpatched advisories, and transitive advisories with no `overrides` or `resolutions`.
- Runtime fetching of code or plugins that should be pinned at build time.
- Copyleft licenses pulled into proprietary distribution.
- No SBOM from the real dependency graph, no signature or provenance verification, and no SCA step that fails the build on new high or critical advisories.
- Vendored code whose upstream version comment predates later security fixes.

## Paper controls (look protective, protect nothing)
- A committed lockfile while CI runs `npm install` (not `npm ci`).
- An audit step with `|| true`, `continue-on-error: true`, or `--audit-level=none`.
- `ignore-scripts` set locally but not in CI or Docker builds.
- Dependabot or Renovate configured but disabled, or its pull requests never merged.
- A SECURITY.md claiming SLSA or signature verification with no `cosign verify` or equivalent anywhere.
- A stale, hand-written SBOM that omits transitive dependencies.
