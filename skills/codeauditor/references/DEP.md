# DEP: Dependencies and Supply Chain

Weight 7. Always active.
Owns: what the project pulls in and how: known-vulnerable versions, abandoned or end-of-life packages and runtimes, deprecated APIs still called, unused and duplicate packages, lockfiles and version pinning (including base images and CI actions), license conflicts, and transitive bloat.
Not here: how the build and deploy run (OBS-R7); malicious packages and CI pipeline security in depth (secauditor).
Standards: CWE-1395, CWE-1104, CWE-477, OWASP A03:2025 (Software Supply Chain Failures).
Read first: every manifest and lockfile inventory.sh lists, the runtime pins (.nvmrc, `engines`, `requires-python`, Dockerfile `FROM`, `go` in go.mod), and references/facts.md.
No network: you cannot run `npm audit`, `pip-audit`, or any registry lookup. Reason from the package name and version. When you are not sure a version is affected, record the finding as Suspected and name the ecosystem's audit tool in Verify the fix.

## Cards

### DEP-R1 Dependency at a version with a known serious advisory (quick)
- Leads: `scan.sh DEP-R1` lists the dependency lines of every manifest. When the manifest gives a range, read the lockfile for the resolved version.
- Confirm: a direct dependency, or a transitive one the lockfile resolves, is at a version you know has a published advisory, and the project uses the affected feature or the advisory affects every use.
- Not a finding if: the lockfile resolves a patched version; the affected feature is not used (read the imports and calls); the package is a dev-only tool that never ships.
- Severity: Critical when the advisory allows remote code execution or an authentication bypass and the affected code is reachable from outside; High for other reachable high-severity advisories; Medium when reachability is unclear. Confidence is Suspected when you are not certain of the advisory or the affected versions.
- Fix: upgrade to the first patched version, or the current stable release, and update the lockfile.
- Verify the fix: `npm audit`, `pip-audit`, `govulncheck ./...`, `bundle audit`, or `cargo audit` reports no advisory for the package.
- Refs: CWE-1395, OWASP A03:2025

### DEP-R2 Package or runtime abandoned, past end of life, or several majors behind
- Leads: `scan.sh DEP-R2` lists runtime pins and packages known to be deprecated or unmaintained (references/facts.md); DEP-R1's lines show every version.
- Confirm: the runtime pinned in the repo (Node.js, Python, Java, Ruby, Go, PHP) is past end of life; a package is deprecated by its maintainers or unmaintained (for example `request`, `moment`, `node-sass`, `tslint`, `pycrypto`, log4j 1.x); or a core framework is two or more major versions behind.
- Not a finding if: the old major is still supported upstream (an LTS line), or an upgrade is tracked and in progress.
- Severity: High when the runtime or a security-relevant package (crypto, auth, HTTP server, template engine) no longer gets security fixes; Medium otherwise; Low for dev-only tools.
- Fix: plan the upgrade to a supported release, or replace the abandoned package with its maintained successor (`sass`, `cryptography` or `pycryptodome`, `luxon` or `date-fns`, log4j 2).
- Verify the fix: the manifest and runtime pin name supported versions, and `npm outdated` or `pip list --outdated` shows no major gap on core packages.
- Refs: CWE-1104

### DEP-R3 Deprecated or removed API still called
- Leads: `scan.sh DEP-R3` lists calls to APIs that are deprecated or removed in current releases (references/facts.md).
- Confirm: the code calls an API its library or runtime has deprecated or removed (`new Buffer()`, `datetime.utcnow()`, `ReactDOM.render`, `pkg_resources`, `distutils`), and the pinned or targeted version warns about it or no longer has it.
- Not a finding if: the pinned version still supports it and no upgrade is planned (then it is a Low note at most); the call sits in a compatibility shim that uses the new API when present.
- Severity: High when the API is already removed in the runtime or library version the project targets; Medium when it is deprecated with warnings; Low otherwise.
- Fix: switch to the replacement the deprecation notice names (`Buffer.from`, `datetime.now(timezone.utc)`, `createRoot`, `importlib.metadata`).
- Verify the fix: `scan.sh DEP-R3` no longer lists the call, and the test run prints no deprecation warning for it.
- Refs: CWE-477

### DEP-R4 Dependency declared but unused, or two packages doing one job
- Leads: no search pattern. For each dependency line from `scan.sh DEP-R1`, search the code, scripts, and config for its import or command name; note packages that do the same job (two HTTP clients, two date libraries, two test runners).
- Confirm: a runtime dependency has no import or use anywhere in the code, scripts, or config, or two packages serve the same purpose in production code.
- Not a finding if: the package is loaded by name rather than imported: a database driver named by the URL scheme (`postgresql+psycopg://` loads psycopg), a server named in a Procfile or Dockerfile command (gunicorn), a plugin named in config (pytest, babel, eslint), or a peer dependency another package needs.
- Severity: Medium when the unused package is large or carries advisories (install time, image size, attack surface); Low otherwise.
- Fix: remove the unused package from the manifest and lockfile; standardize on one package per job and migrate the other's call sites.
- Verify the fix: a clean install and the full test run pass without it, and a search for its import name returns no hits.
- Refs: none

### DEP-R5 No lockfile, or versions float so builds are not reproducible
- Leads: `scan.sh DEP-R5` lists floating ranges, `latest` tags, unpinned base images, and CI actions pinned to a branch; inventory.sh prints the lockfiles it found.
- Confirm: an application (not a library) has no committed lockfile for its package manager; versions use `*`, `latest`, or open `>=` ranges; a Dockerfile uses `FROM image` with no tag or with `:latest`; a CI action is pinned to `@main` or `@master`; or CI installs with a command that ignores the lockfile (`npm install` instead of `npm ci`).
- Not a finding if: the project is a library that deliberately publishes ranges; a Python app pins every package with `==`, transitive ones included (pip-compile or `pip freeze` output acts as the lock).
- Severity: High when production images build from floating tags or ranges with no lockfile, so two deploys of one commit can run different code; Medium otherwise.
- Fix: commit the lockfile, install with the command that honors it (`npm ci`, `pip install --require-hashes`, `poetry install`), pin base images to a version or digest, and pin CI actions to a tag or commit SHA.
- Verify the fix: two clean installs from the same commit resolve identical versions.
- Refs: OWASP A03:2025

### DEP-R6 A dependency's license conflicts with how the project is distributed
- Leads: `scan.sh DEP-R6` lists license declarations in manifests and license files. Read the project's own license and README to learn how it ships (a closed product, a hosted service, a published library).
- Confirm: the project ships closed-source or permissively licensed code and depends at runtime on a package whose license that distribution triggers: GPL in a distributed app or binary, AGPL in a network service, SSPL or another source-available license in a hosted offering; or a runtime dependency declares no license at all.
- Not a finding if: the project itself is open source under a compatible license; the package is dev-only and never distributed; the copyleft tool runs only as a separate program.
- Severity: High when the project is a commercial product shipped to customers and the conflict is in a runtime dependency; Medium otherwise. Record it for legal review; never state a legal conclusion.
- Fix: replace the package with a permissively licensed alternative, or get a legal review and record the decision.
- Verify the fix: a license checker (`license-checker`, `pip-licenses`, `go-licenses`) shows no copyleft or unknown license among runtime dependencies.
- Refs: none

## Also check
- Surface area: a small utility pulling in a large transitive tree, or a whole framework used for one helper.
- Dev tools in runtime dependencies (test frameworks and linters under `dependencies` instead of `devDependencies`), which then ship in production images.
- Git or URL dependencies (`git+https://`, tarball URLs) that skip the registry and the lockfile's integrity check.

## Paper controls (look protective, protect nothing)
- A dependency-audit step in CI with `continue-on-error: true` or `|| true`, so advisories never fail the build.
- A lockfile committed but out of date with the manifest (a package in the manifest missing from the lockfile), so installs ignore it.
- Dependabot or Renovate configured for one ecosystem of several, or set to ignore major updates of core packages.
