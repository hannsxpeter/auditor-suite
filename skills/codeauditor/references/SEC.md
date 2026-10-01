# SEC: Security

Weight 20. Always active.
Owns: a survey of the highest-signal security defects: controls that never run, authorization missing from one handler or record lookup, untrusted input reaching an injection sink, hardcoded secrets, crypto misuse, debug and default exposure, and model output trusted as validated.
Not here: secrets or personal data in logs (OBS-R1); vulnerable dependency versions (DEP-R1); errors that lose their cause (ERR-R2); non-secret per-environment config (OBS-R5); plan and feature entitlement gates, including a plan gate defined but never mounted (productauditor ENT-R5). For depth (authentication design, sessions, supply chain, infrastructure) name secauditor in Scope and limitations; for LLM integration, llmauditor.
Standards: OWASP Top 10:2025, CWE Top 25, OWASP Top 10 for LLM Applications 2025.
Read first: the route or handler registration, the middleware and its mount order, the auth helpers, and the config loader.

## Cards

### SEC-R1 Security control defined but never applied to the path it should guard (quick)
- Leads: `scan.sh SEC-R1` lists auth guards, validators, and middleware registrations. Search for every use of each guard or validator.
- Confirm: a guard, auth middleware, CSRF check, validator, sanitizer, or rate limiter exists, but a route it should cover does not run it: imported and never mounted, mounted after the router, applied to some verbs of a resource and not others, or called with its result ignored.
- Not a finding if: a global or router-level registration covers the route (read the mount order); the route is public by design and documented as public.
- Severity: Critical when the unguarded route changes data, money, or accounts, or returns other users' data; High when it exposes internal data; Medium otherwise.
- Fix: apply the control where it cannot be skipped (globally or on the router, before the handlers), and delete unused copies.
- Verify the fix: a test calls each route in the set without credentials, or with invalid input, and gets 401, 403, or 400.
- Refs: CWE-862, CWE-20, OWASP A01:2025

### SEC-R2 A handler skips the authorization its siblings enforce, or loads a record by request ID with no owner check (quick)
- Leads: `scan.sh SEC-R2` lists route registrations and record lookups by ID. Read each resource's handlers side by side.
- Confirm: one handler for a resource lacks the auth decorator, role check, or middleware its siblings have; or a handler reads, changes, or deletes a record by an ID from the path, query, or body, and nothing ties the record to the signed-in user or tenant.
- Not a finding if: a router-level guard covers every handler in the file (read where the router is mounted); the query also filters by the session's user or tenant; the record is public by design; the route authenticates another way on purpose (a webhook that verifies an HMAC signature; read the check).
- Severity: Critical when the handler is reachable without authentication, or returns or changes other users' personal, financial, or account data; High when it needs a signed-in user and exposes internal data; Medium otherwise.
- Fix: enforce authorization in one place every handler passes through (a router-level guard or central policy), and scope record queries to the caller, for example `filter_by(id=record_id, owner_id=current_user.id)`.
- Verify the fix: user B requesting user A's record gets 403 or 404, and an anonymous request to each handler in the set gets 401.
- Refs: CWE-862, CWE-639, OWASP A01:2025

### SEC-R3 Untrusted input reaches a SQL query, shell command, template, eval, or deserializer (quick)
- Leads: `scan.sh SEC-R3` lists SQL built by concatenation or interpolation, process calls, eval, string templates, and unsafe deserializers.
- Confirm: an outside value (request, upload, message) reaches the sink without parameters or an allowlist: SQL built with `+`, f-strings, `%`, `.format`, or template literals; a shell string or `shell=True` containing it; `eval`, `new Function`, or `render_template_string` of it; `pickle.loads`, `yaml.load`, or Java `ObjectInputStream` on it.
- Not a finding if: the value is bound as a query parameter; a fixed allowlist checks it before use (read the check); it comes only from code or trusted config.
- Severity: Critical when an unauthenticated user can reach it, or when it runs commands or code; High when it needs a signed-in user.
- Fix: bind values as parameters (`execute("... WHERE id = %s", (item_id,))`); pass process arguments as a list with no shell; render only fixed templates with autoescaping; parse outside data with `json` or `yaml.safe_load`, never `pickle`.
- Verify the fix: a test that sends `' OR '1'='1` gets a normal error or an empty result, and the query binds a parameter.
- Refs: CWE-89, CWE-78, CWE-94, CWE-1336, CWE-502, OWASP A05:2025

### SEC-R4 Untrusted input picks a file path, outbound URL, redirect target, or raw HTML (quick)
- Leads: `scan.sh SEC-R4` lists file reads and sends, outbound calls, redirects, and raw-HTML rendering that take a request value.
- Confirm: a request value becomes a file path that is read or served with no check that it stays under the base directory; a URL the server fetches with no host allowlist (SSRF); a redirect target with no allowlist; or HTML inserted without escaping (`innerHTML`, `dangerouslySetInnerHTML`, `|safe`, `mark_safe`).
- Not a finding if: the resolved path is checked for containment in the base (read the check); the parsed URL's host is checked against a fixed allowlist; redirects accept only relative paths; the HTML passes a maintained sanitizer.
- Severity: Critical when an unauthenticated user can read arbitrary files or make the server call internal addresses (cloud metadata at 169.254.169.254); High for other path and URL cases and stored HTML injection; Medium for reflected HTML injection and open redirects.
- Fix: reject paths that leave the base; allow listed hosts only and block private and link-local ranges; allow relative redirects only; escape by default and sanitize any HTML you keep.
- Verify the fix: inputs `../../etc/passwd`, `http://169.254.169.254/`, and `https://evil.example` get 400, and `<script>` renders as text.
- Refs: CWE-22, CWE-918, CWE-601, CWE-79, OWASP A01:2025, OWASP A05:2025

### SEC-R5 Secret, key, or password hardcoded in source or committed config (quick)
- Leads: `scan.sh SEC-R5` lists secret-like names assigned literals, environment reads with literal fallbacks, and committed env files. Run `git log --oneline --stat -- .env` to find env files committed and later deleted.
- Confirm: a real credential (API token, signing secret, database password, private key) is a literal in code or in a committed config or env file, or is the fallback used whenever an environment variable is unset.
- Not a finding if: the value is an obvious placeholder in an example file (`.env.example`, `changeme`); it is used only by tests; it is a public identifier (a publishable key, an OAuth client ID).
- Severity: Critical when it grants write access to production data, money, or messaging (payment, cloud, database, email or SMS sending); High for other real credentials, including a signing-secret fallback that ships to production; Low for test-only values.
- Fix: read the secret from the environment or a secret manager with no fallback, fail at startup when it is missing, and rotate the exposed value; deleting it from the code does not un-leak it.
- Verify the fix: `scan.sh SEC-R5` no longer lists the literal, startup fails without the variable, and the provider shows the old credential revoked.
- Refs: CWE-798, CWE-259

### SEC-R6 Passwords hashed with a fast or unsalted hash, or crypto used unsafely (quick)
- Leads: `scan.sh SEC-R6` lists hash and cipher calls, random values used as tokens, and comparisons of secrets.
- Confirm: passwords are stored with MD5, SHA-1, or plain SHA-256 (salted or not) instead of argon2, bcrypt, scrypt, or PBKDF2 with many iterations; a cipher uses ECB mode, a fixed or reused IV or nonce, or a home-made scheme; tokens, reset codes, or session IDs come from `Math.random`, `random`, or `rand`; secrets, signatures, or tokens are compared with `==` instead of a constant-time compare.
- Not a finding if: the fast hash serves a non-secret purpose (cache keys, ETags, checksums) or stores a long random token such as an API key, where a fast hash is standard; the random value is not security-relevant.
- Severity: Critical for fast or unsalted password hashes and for predictable reset or session tokens; High for ECB, fixed IVs, or home-made crypto on real data; Medium for non-constant-time comparison of signatures or tokens.
- Fix: hash passwords with argon2id or bcrypt from a maintained library; use AES-GCM with a random nonce per message; generate tokens with the platform CSPRNG (`secrets.token_urlsafe`, `crypto.randomBytes`); compare with `hmac.compare_digest` or `crypto.timingSafeEqual`.
- Verify the fix: new password hashes carry the algorithm prefix (`$argon2id$` or `$2b$`), and `scan.sh SEC-R6` no longer lists the call.
- Refs: CWE-916, CWE-759, CWE-327, CWE-329, CWE-338, CWE-208, OWASP A04:2025

### SEC-R7 Debug mode, default credentials, internals in error responses, or any-origin CORS in production (quick)
- Leads: `scan.sh SEC-R7` lists debug flags, CORS settings, stack traces sent to clients, and literal default passwords.
- Confirm: the production path enables a debug mode or console (`app.run(debug=True)`, `DEBUG = True`, the Werkzeug debugger), exposes a debug or admin endpoint without authentication, ships default credentials, returns stack traces or exception text to clients, or allows any origin with credentials in CORS.
- Not a finding if: the setting comes from the environment and defaults to off; only a development entry point uses it (read how production starts: Dockerfile, Procfile, README).
- Severity: Critical when a debug console or default admin credentials are reachable in production; High for CORS that reflects any origin with credentials; Medium for stack traces or exception text in responses.
- Fix: default debug flags to off, read from the environment; require credentials to be set at install; return a generic error body with a request ID and log the details server-side; allow a fixed list of origins.
- Verify the fix: production starts with debug off, an error response carries no stack trace, and a preflight from an unlisted origin gets no `Access-Control-Allow-Origin`.
- Refs: CWE-489, CWE-1392, CWE-209, CWE-942, OWASP A02:2025

### SEC-R8 Model output or injected content steers code, queries, or tools without validation (quick)
- Leads: `scan.sh SEC-R8` lists model SDK calls, tool definitions, and parsing of model output. Follow each output to where it is used.
- Confirm: model output is executed, run as SQL or a shell command, used as a path, URL, or HTML, or picks a tool with side effects, without schema validation and an allowlist; untrusted text (user input, fetched pages, documents) enters a prompt that drives tools able to write data, spend money, or send messages, with no confirmation step; or tool loops have no step or budget limit.
- Not a finding if: the output is parsed into a strict schema and each field is checked against an allowlist before use; tools are read-only or need human confirmation for side effects.
- Severity: Critical when model output reaches code execution, SQL, or a tool that changes data or sends messages; High when it reaches HTML or outbound URLs; Medium when an unbounded loop only costs money.
- Fix: treat model output as untrusted input: validate it against a schema, allowlist tool names and arguments, cap steps and tokens, and require confirmation for side effects.
- Verify the fix: a test that feeds a hostile model reply (an unknown tool name, a `DROP TABLE` string) sees it rejected before any side effect.
- Refs: CWE-1426, CWE-1427, OWASP LLM01:2025, LLM05:2025, LLM06:2025

## Also check
- Authentication basics: sessions and tokens expire and rotate on login, cookies set Secure, HttpOnly, and SameSite, and JWT verification pins the algorithm and checks expiry.
- Authorization done only in the client or UI (hidden buttons, disabled fields) with no server-side check.
- Authorization scattered per handler instead of one central policy: when two or more SEC findings share it, write it as a systemic pattern.

## Paper controls (look protective, protect nothing)
- Auth middleware imported but never mounted, or mounted after the router so the handlers run first.
- A validator or sanitizer defined and unit-tested but never called on the request path.
- A rate limiter that does not limit: keyed on a header the client sets, stored per process behind a load balancer, or mounted on another path.
- A CSRF middleware whose exempt list covers the state-changing routes.
