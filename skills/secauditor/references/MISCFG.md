# MISCFG: Security Misconfiguration and Hardening

Weight 9. Always active.
Owns: production hardening: debug modes and management surfaces, CORS, error disclosure, security headers, file upload handling, filesystem and bucket permissions set in code, and CI/CD access-control gates.
Not here: cookie flags (AUTHN); TLS settings and certificate checks (CRYPTO); rate limits and API inventory (APISEC); secrets in CI (SECRET); third-party Action pinning (SUPPLY); cloud and container config (IAC).
Standards: OWASP A02:2025 (A05:2021), A10:2025 (mishandling of exceptional conditions), ASVS V14, OWASP Secure Headers Project.
Read first: the app bootstrap (middleware order), the error handler, the framework settings per environment, the upload handlers, and `.github/workflows/` or other CI config.

## Cards

### MISCFG-R1 Debug mode or a management surface reachable in production (quick)
- Leads: `scan.sh MISCFG-R1` lists debug flags, Werkzeug and Django debug, Spring Actuator, `phpinfo`, and static serving of `.git` or `.env`.
- Confirm: debug mode can be on in production (`DEBUG = True`, `app.run(debug=True)`, `NODE_ENV` not forced to production), or a management endpoint (Actuator `/env` or `/heapdump`, admin consoles, `phpinfo`) or a served `.git`, `.env`, or directory listing is reachable.
- Not a finding if: the flag comes from an environment variable that defaults to off and production config sets it off (cite both).
- Severity: Critical for an interactive debugger or heap and env dumps; High for other management surfaces.
- Fix: default debug to off, gate it to local development, and remove or protect management endpoints behind authentication and network rules.
- Verify the fix: with production settings, the debug flag is false and the management routes return 404 or 401.
- Refs: CWE-489, CWE-215, OWASP A02:2025

### MISCFG-R2 CORS allows any origin with credentials, or reflects the request Origin
- Leads: `scan.sh MISCFG-R2` lists `Access-Control-Allow-Origin` headers and CORS middleware options.
- Confirm: the server echoes the request `Origin` (or uses `*`, `origin: true`, a `startsWith` or loose regex check, or accepts `null`) while also allowing credentials.
- Not a finding if: origins are matched exactly against an allowlist, or credentials are not allowed and no cookie-authenticated endpoint relies on CORS.
- Severity: High when authenticated endpoints use cookies (any site can read the victim's data); Medium otherwise.
- Fix: match origins exactly against an allowlist and send `Vary: Origin`; never combine a wildcard or reflection with credentials.
- Verify the fix: a request with `Origin: https://evil.example` gets no `Access-Control-Allow-Origin` header.
- Refs: CWE-942, CWE-346, OWASP A02:2025

### MISCFG-R3 Error responses leak stack traces, queries, or internals
- Leads: `scan.sh MISCFG-R3` lists error handlers that return `stack`, `err.message`, `traceback`, or SQL errors.
- Confirm: an error handler returns a stack trace, a raw exception message, SQL text, file paths, or framework versions to the client, or some error types fall through to a verbose default handler.
- Not a finding if: the detailed response is limited to development and production returns a generic message with a correlation ID (cite the gate).
- Severity: Medium; High when the leak includes secrets or connection strings.
- Fix: return a generic error body with a request ID and log the details server-side; catch all error types.
- Verify the fix: forcing a 500 in production mode returns no stack trace or message text.
- Refs: CWE-209, CWE-497, OWASP A02:2025, A10:2025

### MISCFG-R4 Security headers missing or not enforced
- Leads: `scan.sh MISCFG-R4` lists helmet, CSP, HSTS, `X-Frame-Options`, `frame-ancestors`, and `nosniff` configuration.
- Confirm: there is no enforcing Content-Security-Policy (or it is report-only, or allows `unsafe-inline` or `unsafe-eval` for scripts), no HSTS, no `nosniff`, no clickjacking protection, or the headers are set on one route instead of globally.
- Not a finding if: a CDN or proxy sets the headers (cite the config in the repo); the app serves only an API with no HTML.
- Severity: Medium; High when an XSS finding exists and CSP is the missing second line.
- Fix: set the headers globally (for example `helmet()` early in the middleware chain) with an enforcing CSP.
- Verify the fix: a response from any route carries the headers; a test asserts them.
- Refs: CWE-693, CWE-1021, OWASP Secure Headers

### MISCFG-R5 File uploads accept dangerous content (quick)
- Leads: `scan.sh MISCFG-R5` lists multer, `FileField`, `request.files`, and upload handlers.
- Confirm: uploads are checked by extension or client Content-Type only (a blocklist), have no size cap, keep the client filename, or are stored under the web root where they can be served or executed.
- Not a finding if: an allowlist plus magic-byte check, a size limit, generated filenames, and storage outside the web root (or in object storage served with safe headers) are all present.
- Severity: Critical when an uploaded file can execute on the server; High for stored XSS or unbounded size; Medium otherwise.
- Fix: allowlist types by magic bytes, cap size, generate names, store outside the web root, and serve with `Content-Disposition: attachment` and `nosniff`.
- Verify the fix: uploading `shell.php` renamed to `.png` is rejected.
- Refs: CWE-434, OWASP A02:2025

### MISCFG-R6 CI/CD pipeline permissions or approvals too open
- Leads: `scan.sh MISCFG-R6` lists `permissions: write-all`, missing `permissions:` blocks, and deploy jobs.
- Confirm: workflow tokens have write-all or unscoped default permissions, production deploys run without a protected environment or required reviewer, or branch protection can be bypassed by the change author (as far as the repo config shows).
- Not a finding if: each job declares least-privilege `permissions` and deploys use a protected environment (cite the workflow).
- Severity: High when a pull request can reach deploy credentials; Medium otherwise.
- Fix: set `permissions: contents: read` at the top and grant more per job; gate deploys with protected environments and required reviewers.
- Verify the fix: every workflow has an explicit least-privilege `permissions` block.
- Refs: CWE-250, OWASP CI/CD Top 10 (CICD-SEC-1, CICD-SEC-5)

## Also check
- HTTP methods not in use (TRACE) still accepted.
- World-readable config files, `0777` directories, or public bucket ACLs set in code.
- Hardening applied in production config but not in staging that holds real data.
- No test asserting that security headers are present.

## Paper controls (look protective, protect nothing)
- A headers middleware configured but never mounted, or mounted after the routes.
- A CSP that is report-only or allows `unsafe-inline`.
- A CORS allowlist in a comment while the middleware reflects `Origin`.
- Debug gated behind an environment variable that defaults to on.
- A custom error handler that catches one error type while others fall through to the verbose default.
- "Validated uploads" that are an extension blocklist.
- An admin endpoint protected only by an obscure path or a frontend guard.
