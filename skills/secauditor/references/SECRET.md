# SECRET: Secrets Management

Weight 8. Always active.
Owns: credentials in source, config, history, client bundles, logs, images, and CI; hardcoded fallbacks and default credentials; whether a secrets manager is really used; secret scanning.
Not here: weak password hashing (AUTHN); encryption keys' algorithms and sizes (CRYPTO); CI permissions (MISCFG); personal data in logs (LOGPRIV).
Standards: CWE-798, 259, 312, 532, 540; OWASP A07:2025 and A04:2025 (A02:2021).
Read first: config modules, `.env*` files and `.gitignore`, Dockerfiles, CI workflows, and client-side environment usage.

Never copy a live-looking secret value into the report. In Evidence, quote the part of the line before the value in backticks (for example `apiKey: process.env.API_KEY ||`) and write <redacted> for the value outside the backticks; check-report matches the quoted part.

## Cards

### SECRET-R1 Credential hardcoded in source or committed config (quick)
- Leads: `scan.sh SECRET-R1` lists literal `password=`, `api_key=`, `secret=`, and `token=` assignments, provider key shapes, private-key blocks, and tracked `.env` and credential files.
- Confirm: a real-looking credential is a string literal in code or in a tracked config file (`.env`, `credentials.json`, `*.pem`, `id_rsa`, `service-account*.json`, a filled `.npmrc`).
- Not a finding if: the value is an obvious placeholder (`changeme` in an example file that nothing loads, `xxx`, `<your-key>`), a public key, or a test fixture that no deployed code reads.
- Severity: Critical for live-looking production credentials (cloud, payment, database, signing keys); High otherwise.
- Fix: move the value to the environment or a secrets manager, rotate it (it is exposed), and add the file to `.gitignore`.
- Verify the fix: the literal is gone from the working tree and a secret scanner (gitleaks, trufflehog) reports nothing for it.
- Refs: CWE-798, CWE-259, OWASP A07:2025

### SECRET-R2 Secret with a hardcoded fallback or default that runs in practice (quick)
- Leads: `scan.sh SECRET-R2` lists `env || 'literal'`, `getenv('X', 'literal')`, and default secret keys.
- Confirm: a signing key, session secret, or credential falls back to a literal when the environment variable is missing (`process.env.JWT_SECRET || 'dev-secret'`, `SECRET_KEY = 'dev'`), or default credentials (`admin/admin`) stay active.
- Not a finding if: startup fails when the variable is missing in production (cite the check).
- Severity: Critical when the fallback signs sessions or tokens (anyone who reads the code can forge them) or opens an account; High otherwise.
- Fix: remove the fallback and fail fast at startup when the secret is missing.
- Verify the fix: starting the app without the variable exits with an error.
- Refs: CWE-798, CWE-1188, OWASP A07:2025

### SECRET-R3 Secret still live in git history (quick)
- Leads: no search pattern. Run the read-only `git log --all --oneline --diff-filter=D -- '*.env' '*.pem' '*credentials*' '*secret*'` and `git log --all -p -S'<key shape from SECRET-R1>'` to find deleted secret files and past values.
- Confirm: a credential was committed and later deleted or moved, with no evidence it was rotated. Cite it as `<commit>:path:line`.
- Not a finding if: the history was rewritten and the credential rotated (cite the note), or the value is a placeholder.
- Severity: Critical for production credentials; High otherwise. Deleting a file does not revoke a key.
- Fix: rotate the credential first, then purge history if policy requires it.
- Verify the fix: the old credential is revoked with its provider (a runtime check the acting agent records).
- Refs: CWE-540, CWE-312

### SECRET-R4 Server secret shipped to the browser or app binary (quick)
- Leads: `scan.sh SECRET-R4` lists `NEXT_PUBLIC_`, `REACT_APP_`, `VITE_`, `EXPO_PUBLIC_`, and secrets read in client components.
- Confirm: a server-only secret (not a publishable key meant for clients) is exposed through a client-exposed variable prefix, read in client code, or embedded in a mobile or desktop build.
- Not a finding if: the value is designed to be public (a publishable Stripe key, a Firebase web config, a public DSN) and its misuse is limited by server-side rules.
- Severity: Critical for secret keys with write or billing power; High otherwise.
- Fix: keep the secret on the server and call it through an API route; rotate it.
- Verify the fix: the built client bundle no longer contains the variable.
- Refs: CWE-200, CWE-798

### SECRET-R5 Secrets written to logs, errors, or image layers
- Leads: `scan.sh SECRET-R5` lists logging of headers, config objects, and connection strings, and Dockerfile `ARG`, `ENV`, and `COPY .env` lines.
- Confirm: code logs `Authorization` headers, full request or config objects, or a database URL with its password; or a Dockerfile passes secrets through `ARG` or `ENV` or copies `.env` into the image (recoverable from `docker history`).
- Not a finding if: a redaction layer covers that logger (read it and its call path); the Dockerfile uses `--mount=type=secret`.
- Severity: High; Critical if the logs or images are shared outside the team.
- Fix: redact at the logger and never log whole config or request objects; pass build secrets with `--mount=type=secret`.
- Verify the fix: a test logs a request with an Authorization header and the output contains `<redacted>`.
- Refs: CWE-532, CWE-538

### SECRET-R6 CI secrets in plaintext, long-lived keys, or no secret scanning
- Leads: `scan.sh SECRET-R6` lists tokens in workflow files, `echo $SECRET`, `set -x`, static cloud keys, and secret-scanning steps.
- Confirm: workflow files contain plaintext tokens instead of `${{ secrets.X }}`; steps echo secrets or enable `set -x`; static cloud keys are used where OIDC federation is available; or no secret scanner runs in pre-commit or CI, or it cannot fail the build.
- Not a finding if: secrets come from the CI store, scanning runs and fails the build, and cloud access uses OIDC.
- Severity: High for plaintext tokens; Medium for missing scanning or static keys.
- Fix: move tokens to the CI secret store, use OIDC for cloud access, and add a blocking secret scanner.
- Verify the fix: the workflow references only `secrets.*` and the scanner step has no `continue-on-error`.
- Refs: CWE-798, OWASP CI/CD Top 10 (CICD-SEC-6)

## Also check
- `.gitignore` or `.dockerignore` gaps (a `.env` ignored only after it was committed stays in the index and history).
- A secrets manager named in docs but never read by the code (no SDK calls).
- Long-lived static credentials with no rotation path.

## Paper controls (look protective, protect nothing)
- A tidy `.env.example` while the real `.env` is also tracked.
- A secrets manager with a hardcoded fallback that runs whenever the call fails.
- A scanner step with `continue-on-error` or `|| true`, or scoped to the working tree only.
- A `.secrets.baseline` generated with `--all-files` that allowlists live secrets.
- "Moved to environment variables" where the env file is committed.
- Base64 in a Kubernetes Secret treated as encryption.
