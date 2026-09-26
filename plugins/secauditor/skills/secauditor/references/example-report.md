# Security audit: secauditor

> Read-only security audit of the code as written, 2026-09-26. No exploits were run and no live system was touched. Mode: full. Scope: whole project.
> Self-contained: every finding cites the file and line it is about, so an agent holding only this report and the code can act on it. Written with secauditor (auditor-suite 1.1.0).

## Snapshot

- Project: secauditor (commit 3f2a9c1 on main))
- Stack: Python 3, Flask 2.0.1, requests 2.31.0, SQLite (inventory.sh).
- Size and coverage: 3 source files, about 40 lines; read exhaustively.
- Maturity and exposure: Internal tool for the support team, reachable on the company VPN (README.md:3); stores support notes, no payment or health data.
- Active dimensions: AUTHZ, INJ, AUTHN, CRYPTO, MISCFG, SUPPLY, SECRET, APISEC, LOGPRIV
- Not applicable: IAC (no match for: container or infrastructure files; Kubernetes manifests), LLMSEC (no match for: model provider SDKs or LLM frameworks)
- Not assessed: none
- Excluded: none

## Map

- Entry points: `GET /notes/<id>` (`app.py:13`) and `POST /convert` (`app.py:18`); both trust the session set upstream.
- Trust boundary: form data from VPN users crosses into a shell and the filesystem in `convert` (`app.py:20` to `app.py:22`).
- Assets: support notes in SQLite, the server filesystem, and the partner API token in `PARTNER_TOKEN`.
- Highest-risk flow: `request.form["filename"]` (`app.py:20`) into `subprocess.run(..., shell=True)` (`app.py:21`) and `send_file` (`app.py:22`).

## Overall score

<!-- BEGIN GENERATED: score (score.sh --write fills this block; do not edit it by hand) -->
**Overall: 79/100, Grade C (adequate, real gaps)**

| Dimension | Score | Grade | Weight | Critical | High | Medium | Low | Suspected |
|---|---:|---|---:|---:|---:|---:|---:|---:|
| AUTHZ Authorization and Access Control | 100 | A | 18.8% | 0 | 0 | 0 | 0 | 0 |
| INJ Injection and Unsafe Input Handling | 65 | D | 16.7% | 1 | 1 | 0 | 0 | 0 |
| AUTHN Authentication and Session Management | 97 | A | 15.6% | 0 | 0 | 1 | 0 | 0 |
| CRYPTO Cryptography and Data Protection | 95 | A | 11.5% | 0 | 0 | 0 | 0 | 1 |
| MISCFG Security Misconfiguration and Hardening | 100 | A | 9.4% | 0 | 0 | 0 | 0 | 0 |
| SUPPLY Dependencies and Software Supply Chain | 97 | A | 9.4% | 0 | 0 | 1 | 0 | 0 |
| SECRET Secrets Management | 100 | A | 8.3% | 0 | 0 | 0 | 0 | 0 |
| APISEC API and Web Service Security | 100 | A | 6.2% | 0 | 0 | 0 | 0 | 0 |
| LOGPRIV Logging, Monitoring and Data Privacy | 100 | A | 4.2% | 0 | 0 | 0 | 0 | 0 |
| **Overall** | **79** | **C** | 100% | 1 | 1 | 2 | 0 | 1 |

Caps applied: overall held at 79 (one Critical finding).
Not applicable (not scored): IAC (no match for: container or infrastructure files; Kubernetes manifests), LLMSEC (no match for: model provider SDKs or LLM frameworks).
Findings: Critical 1, High 1, Medium 2, Low 0 (Suspected, not yet confirmed: 1).
Computed by score.sh from the findings below (rules: references/protocol.md, Scoring).
<!-- END GENERATED: score -->

Verdict: Any VPN user can run shell commands on the notes server through the `filename` field of `/convert`, and the same field reaches `send_file` unchecked. Record access and SQL are handled well. The remaining findings are configuration hygiene.

Calibration: Internal VPN-only service with low data sensitivity, graded at an internal-tool bar; command execution stays Critical at any exposure.

## What to fix first

<!-- BEGIN GENERATED: fix-first (score.sh --write) -->
1. [INJ-001] Form field `filename` runs shell commands in `/convert` - Critical, effort S. any VPN user can send a filename such as `x; <command>` and run commands as the service account, with access to the notes database and the partner ...
2. [INJ-002] `send_file` serves any path built from the form field - High, effort S. a VPN user can read files outside `out/`, including source and configuration.
<!-- END GENERATED: fix-first -->

## Strengths (preserve these)

- Note lookups are scoped to the owner with bound parameters: `db.py:8`.
- The Flask secret key is read from the environment with no fallback: `app.py:9`.

## Systemic patterns (root causes)

- SYS-1: the uploaded `filename` is used without validation. Members: INJ-001, INJ-002. Root fix: accept only names matching `^[A-Za-z0-9_-]+\.(png|jpg)$` and write outputs under generated names.

## Findings

<!-- One block per finding in the exact format of references/protocol.md (Finding format). -->

### [INJ-001] Form field `filename` runs shell commands in `/convert`
- Severity: Critical | Confidence: Confirmed | Effort: S | Dimension: INJ
- Location: `app.py:21`
- Evidence: `name = request.form["filename"]` (`app.py:20`) goes straight into `subprocess.run(f"convert uploads/{name} -resize 50% out/{name}", shell=True, check=True)`.
- Impact: any VPN user can send a filename such as `x; <command>` and run commands as the service account, with access to the notes database and the partner token.
- Recommendation: call `subprocess.run(["convert", src, "-resize", "50%", dst], check=True)` with no shell, and validate the name first (SYS-1).
- Verify the fix: a test posting `filename=a.png;touch /tmp/pwned` creates no file and returns 400.
- References: CWE-78, OWASP A05:2025
- Related: SYS-1

### [INJ-002] `send_file` serves any path built from the form field
- Severity: High | Confidence: Likely | Effort: S | Dimension: INJ
- Location: `app.py:22`
- Evidence: `return send_file(f"out/{name}")` uses the unvalidated `name`; `../` sequences escape the `out` directory.
- Impact: a VPN user can read files outside `out/`, including source and configuration. Likely rather than Confirmed because the line runs only after `convert` succeeds for the same name.
- Recommendation: serve from a fixed directory with `send_from_directory("out", safe_name)` after validating the name (SYS-1).
- Verify the fix: `filename=../app.py` returns 400 or 404.
- References: CWE-22, OWASP A01:2025
- Related: SYS-1

### [CRYPTO-001] Partner rate client disables certificate checks while sending a bearer token
- Severity: High | Confidence: Suspected | Effort: S | Dimension: CRYPTO
- Location: `partner.py:10`
- Evidence: `requests.get(PARTNER_URL + "/v1/rates", headers=headers, verify=False, timeout=10)` sends `Authorization: Bearer` with verification off.
- Impact: anyone on the network path can impersonate the partner and capture the token. Suspected because nothing in this repo calls `fetch_rates`; it may run from an external scheduler or be dead code.
- Recommendation: remove `verify=False`; if the partner uses a private CA, pass its bundle with `verify="/path/ca.pem"`.
- Verify the fix: confirm whether the scheduler calls `fetch_rates`; the call then succeeds against the real endpoint and fails against a self-signed test server.
- References: CWE-295, OWASP A04:2025
- Related: none

### [AUTHN-001] Session cookie is allowed over plain HTTP
- Severity: Medium | Confidence: Confirmed | Effort: S | Dimension: AUTHN
- Location: `app.py:10`
- Evidence: `app.config["SESSION_COOKIE_SECURE"] = False` lets browsers send the session cookie over HTTP.
- Impact: on a network path without TLS, the session can be captured and replayed; the VPN limits who can try.
- Recommendation: set `SESSION_COOKIE_SECURE = True` and `SESSION_COOKIE_SAMESITE = "Lax"`.
- Verify the fix: the Set-Cookie header on a response carries `Secure; HttpOnly; SameSite=Lax`.
- References: CWE-614, ASVS V7
- Related: none

### [SUPPLY-001] Flask pinned to 2.0.1, below the fix for CVE-2023-30861
- Severity: Medium | Confidence: Likely | Effort: S | Dimension: SUPPLY
- Location: `requirements.txt:1`
- Evidence: `Flask==2.0.1`; CVE-2023-30861 (a missing `Vary: Cookie` header that can let a caching proxy serve one user's session cookie to another) is fixed in 2.2.5 and 2.3.2.
- Impact: exploitable only behind a caching proxy that stores responses carrying a refreshed permanent session; Likely because the proxy setup is not in the repo.
- Recommendation: upgrade to Flask 2.3.2 or later and add `pip-audit` to CI.
- Verify the fix: `pip-audit -r requirements.txt` reports no advisory for Flask.
- References: CVE-2023-30861, OWASP A03:2025
- Related: none

## Dimension notes

### AUTHZ: Authorization and Access Control
- Checked: AUTHZ-R1, AUTHZ-R2, AUTHZ-R3, AUTHZ-R4, AUTHZ-R5, AUTHZ-R6
- Note: The only record read, `get_note`, is scoped to the session user; no findings.

### INJ: Injection and Unsafe Input Handling
- Checked: INJ-R1, INJ-R2, INJ-R3, INJ-R4, INJ-R5, INJ-R6, INJ-R7, INJ-R8
- Note: The form field `filename` reaches a shell (INJ-001) and a file path (INJ-002); SQL is parameterized.

### AUTHN: Authentication and Session Management
- Checked: AUTHN-R1, AUTHN-R2, AUTHN-R3, AUTHN-R4, AUTHN-R5, AUTHN-R6, AUTHN-R7, AUTHN-R8
- Note: Sign-in happens at the VPN gateway (assumed from the README); the session cookie is sent over plain HTTP (AUTHN-001).

### CRYPTO: Cryptography and Data Protection
- Checked: CRYPTO-R1, CRYPTO-R2, CRYPTO-R3, CRYPTO-R4, CRYPTO-R5, CRYPTO-R6
- Note: One outbound call disables certificate checks, but nothing in the repo calls it (CRYPTO-001, Suspected).

### MISCFG: Security Misconfiguration and Hardening
- Checked: MISCFG-R1, MISCFG-R2, MISCFG-R3, MISCFG-R4, MISCFG-R5, MISCFG-R6
- Note: No debug mode, no CORS, and the app returns JSON and files only, so missing browser headers are not a finding here.

### SUPPLY: Dependencies and Software Supply Chain
- Checked: SUPPLY-R1, SUPPLY-R2, SUPPLY-R3, SUPPLY-R4, SUPPLY-R5, SUPPLY-R6
- Note: Flask is pinned to a version with a published session-cookie advisory (SUPPLY-001); there is no lockfile, which matters little for an internal service with two pinned packages.

### SECRET: Secrets Management
- Checked: SECRET-R1, SECRET-R2, SECRET-R3, SECRET-R4, SECRET-R5, SECRET-R6
- Note: The Flask secret key comes from the environment with no fallback; no credentials in source or history.

### APISEC: API and Web Service Security
- Checked: APISEC-R1, APISEC-R2, APISEC-R3, APISEC-R4, APISEC-R5, APISEC-R6
- Note: Two routes, no webhooks, GraphQL, or old versions; no findings.

### LOGPRIV: Logging, Monitoring and Data Privacy
- Checked: LOGPRIV-R1, LOGPRIV-R2, LOGPRIV-R3, LOGPRIV-R4, LOGPRIV-R5
- Note: The service stores support notes but no regulated data, and authentication events originate at the gateway; no findings.

## Remediation plan

<!-- BEGIN GENERATED: plan (score.sh --write) -->
- Quick wins (Critical or High, not Suspected, effort S): INJ-001, INJ-002
- Plan now (Critical or High, not Suspected, effort M or L), in this order: none
- Verify first (Suspected; confirm against the code before acting): CRYPTO-001
- Schedule (Medium): AUTHN-001, SUPPLY-001
- Backlog (Low): none
<!-- END GENERATED: plan -->

## Scope and limitations

Read every file (`app.py`, `db.py`, `partner.py`, `requirements.txt`, `README.md`). Nothing was run. Whether `fetch_rates` runs in production depends on a scheduler outside the repo (CRYPTO-001). The VPN-only exposure is taken from the README; if the service is reachable from the internet, AUTHN-001 rises to High.

## How to use this report (for the acting agent)

1. Triage by severity and confidence. Confirmed Critical and High findings are safe to act on now, in the order under "What to fix first". Re-verify every Suspected finding against the cited code before changing anything.
2. Confirm the stated assumption on Likely findings before acting.
3. Fix root causes first: prefer a systemic pattern's root fix over its individual members.
4. Preserve the strengths; do not refactor them away while fixing something else.
5. Fix at the trust boundary: prefer one central authorization or validation layer over per-handler patches, never weaken a working control to make another fix easier, and never add exploit payloads beyond what a Verify the fix test needs.
6. One finding, one change, verified: after each fix, run its "Verify the fix" step and keep the change traceable to the finding ID.
7. Do not widen scope silently; note adjacent issues instead of sprawling into a rewrite.
8. Re-run the audit to measure progress: confirm findings are resolved, not relocated, and that the strengths did not regress.
