---
name: secauditor
description: Audit the codebase for security vulnerabilities end to end, write secaudit.md (a scored, prioritized, self-contained report), then display the results in chat. Read-only: never edits source, never runs exploits.
---

# secauditor

Audit the security posture of the codebase in the current working directory end to end, then do two things:

1. **Write a report** named `secaudit.md` at the root of that codebase.
2. **Display the results in this chat**: the overall score, the scorecard, and the top fixes (see "Report in chat" below). Do not finish silently.

This is **read-only analysis**. Do not modify any source file, do not run exploits, do not attack a live system, do not exfiltrate data, and do not execute the project's own code as part of the audit. The only file you create is `secaudit.md`. If an optional path or scope was provided as an argument, audit that subtree; otherwise audit the whole codebase rooted at the working directory.

The report is written for a reader who has **no memory of the audit**, typically an AI agent that will open `secaudit.md` later and decide, on its own, what to fix. Every finding must therefore stand alone: cite exact locations (`path/to/file.ext:line`), trace the path from untrusted source to dangerous sink, carry its own context, and say how to verify the fix. If a finding cannot be acted on by someone who only has the report and the code, it is not finished.

This is a **vulnerability and weakness audit**, not a quality audit. Scope is the security of the code as written and configured: who can do what, how untrusted input is handled, how secrets and data are protected, and where the trust boundaries actually are. General code quality, architecture for its own sake, performance, and UX belong to other audits; touch them only where they create a security weakness.

---

## Operating principles (non-negotiable)

These govern the whole audit. A report that violates any of them is not done.

1. **Evidence over assertion.** No claim without a concrete, checkable reference (`file:line`), and for an injection or access-control finding, the path from the untrusted **source** to the dangerous **sink**. Apply the substitution test to every sentence: if you could swap in a different project and it would read equally true, it is filler. Cut it or make it specific. "Input is not validated" fails. "`api/reports.ts:54` passes `req.query.path` into `fs.readFile` with no canonicalization, so `?path=../../etc/passwd` reads arbitrary files" passes.
2. **Verify against reality.** Read the code, not the comments, names, docs, or a `SECURITY.md`. A guard named `requireAdmin` that does not check a role, a `sanitize()` that strips nothing, a "TLS required" claim next to a plaintext listener: the gap between the claim and the code is itself a finding, and often the most serious one.
3. **Refuse theater. Hunt for paper security controls.** The most dangerous defects look protective but carry no weight: a policy decorator defined but never applied to the routes it should guard, a validator that is never called on the path that reaches the sink, a JWT that is decoded but never signature-verified, a `redact()` wired into one log formatter while every other statement bypasses it, a scanner step run with `continue-on-error: true` or `|| true`, a CORS allowlist that reflects the request `Origin`, a rate limiter mounted after the login route. Flag anything that exists for appearance but does not actually protect. A green scanner is not a clean bill of health; explicitly hunt what scanners miss.
4. **Exploitability, not just presence.** A weakness matters when there is a plausible path for an attacker to reach and abuse it. State the path (who, from where, with what input, to what effect) and the precondition (authenticated or not, which role, which config). Reason about exploitability; do not exploit. If reachability depends on a runtime or deployment fact you cannot confirm from the code, mark it Suspected and say what would confirm it.
5. **Find the root, not the leaves.** If the same mistake appears in twelve handlers (no ownership check on any object lookup, string-concatenated SQL throughout), that is one systemic finding ("there is no central authorization layer"), not twelve. Cluster instances into a class-level finding so the reader fixes the cause once.
6. **Verify adversarially.** For every candidate finding, try to refute it before keeping it: is there a guard, framework default, gateway, or compensating control elsewhere that neutralizes it? Is it deliberate and documented? Assign a confidence level. When you cannot confirm by reading, mark it Suspected so the acting agent re-checks before changing anything.
7. **Calibrate to the project, not to fear.** Grade against the project's evident ambition, data sensitivity, exposure (internet-facing vs internal vs local), and maturity. A local CLI that touches no secrets is not held to the bar of an internet-facing payment service. State your calibration, including the assumed deployment context and threat model.
8. **Be honest about scope.** Say what you examined and what you did not, which security surfaces are present (web, API, cloud/IaC, AI/LLM, regulated data) and which are absent, and whether you read exhaustively or sampled. Never imply a penetration test happened, and never imply completeness you did not achieve.
9. **Score with reasons, not vibes.** Every dimension score is justified against its specific findings. No number appears without the evidence that produced it.
10. **Name the strengths.** Record the controls the codebase gets right, with evidence (parameterized queries everywhere, a real central authorization layer, secrets sourced from a manager), so the acting agent preserves them instead of removing them while fixing something else.
11. **Recommendations are specific and actionable.** Banned: "improve security," "validate input," "harden the config." Required: what to change, where, the safe pattern to use, and how to confirm it worked (a test to add, a request whose response should now change, or a check to run). Never include a working exploit; describe the weakness and the fix, not a weaponized payload.

---

## Method

Run these phases in order. Use search to find candidates, then **read the cited code to confirm the source-to-sink path** before recording anything. A search hit (a `query` string, an `exec` call, a missing flag) is a lead, not a finding.

### Phase 0 - Orient
- Detect languages, frameworks, runtimes, build system, and package manager from manifests (`package.json`, `pyproject.toml`, `go.mod`, `Cargo.toml`, `pom.xml`, `Gemfile`, etc.).
- Detect which **security surfaces** are present, because they decide which dimensions apply: a web/HTTP layer, an API (REST/GraphQL/gRPC), authentication, a database, file uploads, outbound fetches, message/queue consumers; container or IaC files (`Dockerfile`, `*.tf`, Kubernetes/Helm manifests, CloudFormation, Bicep, Pulumi, CDK); CI/CD config (`.github/workflows`, `.gitlab-ci.yml`, `Jenkinsfile`); AI/LLM usage (provider SDKs such as `openai`/`anthropic`/`google-genai`, orchestration like `langchain`/`llamaindex`, vector stores, RAG/embedding code); and personal or regulated data (PII/PHI/cardholder data). Record which surfaces are present and which are N/A.
- Measure size (file count, rough lines of code) and decide exhaustive vs. sampled reading. Declare which in the report.
- Locate entry points and trust-crossing surfaces: route definitions, controllers, CLI handlers, scheduled jobs, message consumers, webhook receivers, and anything that reads request/body/header/file/env input.
- Read the README and docs to learn intended behavior, deployment context (internet-facing, internal, local), data sensitivity, and evident maturity. You will check the code against these claims and calibrate scoring to them.
- Identify what to exclude: vendored dependencies, generated code, build output, test fixtures (but do scan fixtures for real secrets). Record exclusions.
- If version control is present, record the current commit or branch; secrets and history are in scope (a secret deleted from HEAD but live in history is a finding).
- If the target is not actually a codebase (empty directory, documents only), say so plainly in chat and stop. Do not invent findings.

### Phase 1 - Map the attack surface and trust boundaries
Do a short, lightweight threat-model pass before the per-dimension checklist. Keep it to roughly a half page; this informs prioritization, it is not a formal DFD exercise.
- **Entry points:** enumerate every place untrusted data or an unauthenticated/lower-privileged actor crosses into the system (HTTP routes and their methods, API endpoints, GraphQL resolvers, webhooks, file uploads, queue/event consumers, LLM prompt inputs, third-party callbacks, CLI args, env).
- **Trust boundaries:** mark where data moves from less-trusted to more-trusted (client to server, internet to internal network, tenant to tenant, user to admin, model output to a sink).
- **Sensitive assets:** name what an attacker would want (credentials and secrets, PII/PHI/cardholder data, money and balances, admin functions, other tenants' data, infrastructure access).
- **Principals and roles:** list the roles (anonymous, user, admin, service) and what each should and should not be able to do.
- **STRIDE as a coverage lens:** for the important boundaries, sanity-check each STRIDE category maps to a dimension so nothing is missed: Spoofing -> Authentication; Tampering and Repudiation -> Integrity and Logging; Information Disclosure -> Cryptography and Access Control; Denial of Service -> Resource Consumption and API; Elevation of Privilege -> Authorization. Use this to catch design-level gaps that per-line checks miss (this is also where **OWASP A06:2025 Insecure Design** is handled, as a cross-cutting design-review lens rather than a weighted bucket: missing-by-design controls, dangerous-by-default flows, no rate limiting anywhere, trust placed in the client).
- Trace two or three highest-risk flows end to end (an unauthenticated request reaching sensitive data; a privileged action; untrusted input reaching a query, command, or render). Spend effort proportional to blast radius.

### Phase 2 - Analyze across every lens
For each candidate issue capture three things: the location (`file:line`) and source-to-sink path, what the code does now, and why that is exploitable. Do not score yet. Skip a conditional lens whose surface is absent (say so), and calibrate every lens to the deployment context.

**Authorization and Access Control** (AUTHZ) - OWASP A01:2025 / A01:2021, API1/API3/API5:2023, ASVS V8
- Object-level (IDOR/BOLA): handlers that load or mutate a record by an ID taken from the request without binding it to the current user or tenant (`Order.findById(req.params.id)` instead of `findOne({id, ownerId: req.user.id})`). Check writes (PUT/PATCH/DELETE), not just reads.
- Function-level (BFLA): every admin or privileged route carries an enforced role/permission check; flag admin endpoints "hidden" only by the UI, and mutating verbs that lack the guard their GET sibling has.
- Deny-by-default: authorization is default-deny through a central mechanism (middleware/policy), not a scattered allowlist of blocked routes that new handlers silently bypass (`anyRequest().permitAll()`, route ordering that runs the handler before the guard).
- Privilege escalation: request-settable `role`/`isAdmin`/`scope`/`tenant` fields (vertical); list/search/export endpoints that return rows across owners or tenants (horizontal).
- Mass assignment (BOPLA write side): whole-body binding to an entity (`Object.assign(user, req.body)`, `permit!`, `new Model(req.body)`) lets a client set protected fields; require an allowlist.
- Excessive data exposure (BOPLA read side): serializers/DTOs returning full entities (password hashes, internal flags, other users' PII) because the client is trusted to ignore them.
- Multi-tenant isolation: every query scoped by a tenant id derived from the session (row-level security or a mandatory ORM filter), never from a request-supplied tenant header that can be swapped.
- Trust placement: JWT claims (`role`, `tenant`) verified server-side (signature, not just decode); CORS is not used as access control; client-supplied `X-User-Id` headers not trusted at the app tier; signed URLs and storage keys scoped to the requester.
- Paper controls to hunt: a `@PreAuthorize`/policy class defined but never applied; an `isOwner()` helper written, tested, and never called (or its return ignored); tenant filtering in the UI but not in the API; CORS locked down and treated as the boundary while endpoints behind it require no authorization.

**Authentication and Session Management** (AUTHN) - OWASP A07:2025 / A07:2021, ASVS V6/V7/V9/V10, NIST SP 800-63B-4, RFC 9700, RFC 8725
- Password storage uses a memory-hard/adaptive KDF (argon2id, scrypt, bcrypt, or PBKDF2-HMAC-SHA256 at current floors), never a fast digest (MD5/SHA-*) applied to a password, and never unsalted or a single global salt.
- Credential verification and all secret/token/MFA-code comparisons are constant-time (`bcrypt.compare`, `hmac.compare_digest`, `timingSafeEqual`), not `==`/`.equals()`.
- Brute-force and credential-stuffing defenses (per-account and per-IP throttling, lockout, or CAPTCHA) are enforced server-side on login, MFA-verify, and reset endpoints; breached-password screening over arbitrary complexity rules.
- MFA is actually enforced on the auth path, not just a stored flag; codes are single-use and rate-limited; no alternate login route bypasses it.
- Session IDs come from a CSPRNG with sufficient entropy, are regenerated on privilege change (no fixation), have absolute and idle timeouts, and are invalidated server-side on logout (not just cookie-cleared). Session cookies set `Secure`, `HttpOnly`, and `SameSite`, and the token is not also exposed to JavaScript.
- JWTs: an explicit algorithm allowlist (reject `alg:none` and RS256->HS256 confusion), a strong non-hardcoded key, and validation of signature, `exp`, `iss`, `aud`; no sensitive data in the (base64, not encrypted) payload.
- OAuth/OIDC: Authorization Code + PKCE (not Implicit or Password grant); `redirect_uri` validated by exact match (not `startsWith`/regex); `state` and `nonce` generated, bound to the session, and verified.
- Recovery: reset tokens are CSPRNG, single-use, short-lived, invalidated on use and password change; auth errors are generic (no user enumeration); no hardcoded/default/backdoor credentials or `if env==dev: skip_auth` branches.
- Paper controls to hunt: a constant-time helper defined but the login path still uses `==`; MFA shown in the UI but never verified server-side; lockout middleware that excludes `/login`; logout that clears the cookie but never revokes the token; a strong password policy at registration that the reset/admin-set path skips.

**Injection and Unsafe Input Handling** (INJ) - OWASP A05:2025 (Injection), A01:2025 (SSRF), A08 (Integrity), A03/A10:2021; CWE-89/78/79/918/22/502/1336/611/601/1321
- SQL/NoSQL injection: string-concatenated or interpolated queries, `.raw()`/`.extra()`/`text()` fed user input, MongoDB query objects built from `req.body` or `{$where: input}`; require bound parameters (and confirm the params are passed separately, not pre-substituted). Allowlist dynamic identifiers (table/column/ORDER BY) that cannot be parameterized.
- Command injection: `exec`/`system`/`popen`/`child_process.exec`/`subprocess(shell=True)` with interpolated input; require an argv array with the shell disabled, and `--` separators or value allowlists for argument injection.
- XSS: request/DB values rendered to HTML with auto-escaping disabled (`|safe`, `mark_safe`, triple-stash, `Html.Raw`, `dangerouslySetInnerHTML`, `v-html`, `[innerHTML]`) and context-mismatched encoding; DOM XSS from `location`/`postMessage` into `innerHTML`/`eval`/`document.write`.
- SSRF: user-controlled URLs/hosts into outbound fetchers (webhooks, image/avatar-from-URL, link preview, SSO metadata); require a destination allowlist (a blocklist of `localhost`/`127.0.0.1` is bypassable via `169.254.169.254`, `[::1]`, decimal/hex IPs, DNS rebinding, redirects); the resolved IP must be re-checked after redirects.
- Path traversal and Zip Slip: filesystem paths built from input without canonicalization (`realpath`/`resolve`) plus a base-dir containment check; archive extraction that writes entries outside the target dir.
- Insecure deserialization: native deserializers on untrusted bytes (Java `readObject`, Python `pickle`/`yaml.load`, PHP `unserialize`, Ruby `Marshal.load`, .NET `BinaryFormatter`, Jackson/fastjson polymorphic typing); require a data-only format with a schema (or `yaml.safe_load`).
- Template and code injection: templates compiled from user input (SSTI); `eval`/`exec`/`new Function`/`setTimeout(string)`/EL/OGNL/SpEL on untrusted input.
- Also: LDAP/XPath injection, HTTP response splitting and log injection (CR/LF), XXE (DTDs and external entities not disabled), open redirect (`?next=` into `redirect()` without a same-origin check), and prototype pollution (recursive merge/set copying `__proto__`).
- Second-order: data stored safely then concatenated into a query/command/template later without re-encoding; trust must not be assumed because the value "came from the database."
- Paper controls to hunt: a `sanitizeInput()`/`escapeSql()` defined but never called on the path to the sink; a parameterized API defeated by pre-substituting the value; an SSRF "allowlist" that is actually a tiny blocklist; auto-escaping enabled globally while the real output paths use `|safe`; XML hardening on one parser while another path (SOAP/SVG/SAML) uses defaults; client-side-only validation presented as the control.

**Cryptography and Data Protection** (CRYPTO) - OWASP A04:2025 / A02:2021, ASVS V11/V12, NIST SP 800-131A/52/57
- No deprecated or broken primitives (MD5, SHA-1, DES/3DES, RC4, ECB mode) for confidentiality or integrity; prefer authenticated AEAD (AES-GCM, ChaCha20-Poly1305).
- IVs/nonces are unique and unpredictable per encryption; no hardcoded, all-zero, or reused IV; GCM nonces never reused under a key.
- All security-sensitive randomness (tokens, salts, IVs, OTPs, session IDs, reset tokens) comes from a CSPRNG (`secrets`, `crypto.randomBytes`, `SecureRandom`), never `Math.random`/`java.util.Random`/`rand()`, and `SecureRandom` is not fixed-seeded.
- No home-rolled crypto (XOR "encryption", bespoke key-stretching); use vetted libraries.
- Keys, signing secrets, and salts are not hardcoded; keys come from a KMS/secrets manager or environment, with rotation support (a key-id on ciphertext that code actually honors) and adequate key sizes (RSA >= 2048, EC >= P-256).
- TLS enforced for all sensitive data in transit (no `http://` for auth/PII, no plaintext DB/cache links, HSTS present); TLS 1.2+ only, weak/NULL/EXPORT/RC4/non-PFS ciphers disabled; certificate and hostname validation never disabled (`verify=False`, `rejectUnauthorized:false`, `InsecureSkipVerify:true`, all-trusting `TrustManager`, `curl -k`).
- Sensitive data (PII/PHI/PAN, credentials, tokens) encrypted at rest (field- or storage-level, including backups), not written to logs, not cached (`Cache-Control: no-store`), and not placed in URL query strings.
- Paper controls to hunt: a `CryptoUtil` with AES-GCM that the persistence path never calls; "TLS required" while a plaintext port is still bound; a strong hasher imported but the login path still uses legacy SHA-256 with no upgrade-on-login; cert validation disabled in a reachable `dev` branch; a KMS client with a hardcoded fallback key that is what actually runs; a constant-time helper that the webhook HMAC check bypasses with `==`.

**Secrets Management** (SECRET) - CWE-798/259/312/532/540, OWASP A07:2025 / A02:2021; includes CI/CD credential hygiene
- Hardcoded credentials in source (literal `password=`/`api_key=`/`secret=`/`token=` with a string RHS, not a `getenv`/config call) and recognizable provider key shapes (`AKIA...`, `AIza...`, `sk_live_`, `ghp_`, `xox...`, PEM private-key blocks).
- Committed credential files (`.env`, `credentials.json`, `*.pem`/`*.p12`, `id_rsa`, `service-account*.json`, `kubeconfig`, filled `.npmrc`) tracked by git rather than gitignored, plus `.gitignore`/`.dockerignore` gaps (a `.env` ignored only after it was already committed stays in the index and history).
- Secrets live in version-control history even when removed from HEAD; scan all history, not just the working tree; a deleted-but-unrotated secret is still live.
- Client-side exposure: server secrets shipped to the browser via `NEXT_PUBLIC_*`/`REACT_APP_*`/`VITE_*` or read in client components, and secrets embedded in mobile/desktop binaries.
- Secrets logged or echoed (Authorization header, DB URL with password, whole config/request objects in error handlers), and secrets baked into image layers (Dockerfile `ARG`/`ENV` secrets, `COPY .env`) recoverable from `docker history`.
- CI/CD secret hygiene: plaintext tokens in workflow files instead of `${{ secrets.X }}`/vault refs; `echo $SECRET`/`set -x` leaking masked values; long-lived static cloud keys where OIDC federation is available.
- A real secrets manager is actually read by the code (SDK calls present), not just named in docs; no default/example credentials (`admin/admin`, `changeme`, `SECRET_KEY='dev'`) left active; long-lived static credentials have a rotation path.
- Secret scanning (gitleaks/detect-secrets/trufflehog) runs in a pre-commit hook and/or CI and actually fails the build.
- Paper controls to hunt: a tidy `.env.example` while the real `.env` is also tracked; a secrets manager with a hardcoded fallback that runs in practice; a scanner step with `continue-on-error`/`|| true` or scoped only to HEAD; a `.secrets.baseline` generated with `--all-files` that mass-allowlists live secrets; "moved to env vars" where the env file is committed; base64 in a k8s Secret treated as encryption; a secret deleted from a file but never rotated.

**Security Misconfiguration and Hardening** (MISCFG) - OWASP A02:2025 / A05:2021, ASVS V14, OWASP Secure Headers; includes CI/CD access-control gates
- Security headers: a real (enforcing, not report-only) Content-Security-Policy without `unsafe-inline`/`unsafe-eval`; HSTS with a long max-age and an HTTP->HTTPS redirect; `X-Content-Type-Options: nosniff`; clickjacking protection (`frame-ancestors`/`X-Frame-Options`); a tightening `Referrer-Policy`; applied globally, not on one route.
- CORS: no `Access-Control-Allow-Origin: *` with credentials, no reflected `Origin`, no `startsWith`/regex allowlist a sibling domain satisfies, and `null` origin rejected.
- Production hardening: debug mode off (`DEBUG=True`, `app.run(debug=True)`, `NODE_ENV` not production, Werkzeug console); no verbose stack traces / SQL errors / framework version banners returned to clients; no default secret keys or sample apps; no exposed management surfaces (Swagger/GraphQL introspection, Spring Actuator `/env`/`/heapdump`, `phpinfo`, served `.git`/`.env`); no directory listing.
- Cookies, TLS, and HTTP methods: secure cookie defaults; no weak TLS / disabled outbound cert verification; only the HTTP methods in use accepted (TRACE off).
- Resource controls: rate limiting / throttling on auth, reset, OTP, search, and expensive endpoints; request body-size limits; bounded pagination (API4:2023, CWE-770/400).
- File upload: allowlist plus magic-byte validation (not extension/Content-Type blocklist), size caps, sanitized filenames, and storage outside the web root.
- Insecure default permissions (world-readable config, public bucket ACLs, `0777` dirs) and hardening that is not applied uniformly across environments (no test asserting headers are present).
- CI/CD access control: least-privilege `GITHUB_TOKEN`/job permissions (no `write-all`); required-reviewer / environment-protection gates before prod deploys; no self-approval, `enforce_admins` not disabled, force-push to protected branches blocked.
- Paper controls to hunt: a headers middleware configured but not mounted (or mounted after the routes); a CSP that is report-only or contains `unsafe-inline`; a CORS allowlist that actually reflects `Origin`; debug gated behind an env var that defaults on; a custom error handler that catches one type while others fall through to the verbose default; rate limiting on a health check but not on login; cookie flags dropped by a later override; "validated uploads" that are an extension blocklist; an admin/actuator endpoint protected only by an obscure path or a frontend guard; a manual approval that the change author can self-approve.

**Dependencies and Software Supply Chain** (SUPPLY) - OWASP A03:2025 (Supply Chain) / A06+A08:2021, SLSA v1.2, SBOM (CycloneDX/SPDX), OWASP CI/CD Top 10
- Known-vulnerable versions: cross-reference locked versions against advisories (OSV, GitHub Advisory, `npm audit`, `pip-audit`); flag ranges with known CVEs (Log4Shell, vulnerable lodash/axios, etc.).
- Pinning and integrity: a committed lockfile in sync with the manifest, no floating specifiers (`^`/`~`/`*`/`latest`, unbounded `>=`, `:latest` images without a digest), per-package hashes enforced at install (`npm ci`, `pip install --require-hashes`, `yarn --immutable`).
- Dependency confusion and typosquatting: unscoped internal package names with no private-registry pinning in `.npmrc`/`pip.conf`; near-miss names (`reqeusts`, `crossenv`) and low-download/recently-published packages pinned for core functionality.
- Transitive and maintenance risk: vulnerable transitives with no `overrides`/`resolutions` to force-patch; abandoned/archived/deprecated packages with unpatched CVEs.
- Install-time and acquisition risk: dependency `postinstall`/`preinstall` hooks (and whether `ignore-scripts` is set); `curl ... | sh`/`wget | sh` and HTTP downloads with no checksum/signature; runtime (vs build-time) fetching; license risk (copyleft into proprietary distribution).
- Provenance and SBOM: signatures/attestations verified (Sigstore/cosign, npm provenance, SLSA Build L2/L3); an SBOM generated at build time from the real graph; SCA runs in CI and gates on new high/critical advisories.
- CI/CD pipeline supply chain: third-party Actions pinned to a full commit SHA (not a mutable `@v4`/`@main` tag, the tj-actions/changed-files vector); no Poisoned Pipeline Execution (`pull_request_target`/`workflow_run` checking out and running fork code with secrets in scope, or untrusted event fields interpolated into a `run:` shell step); artifacts published with signatures and pulled by immutable digest.
- Paper controls to hunt: a committed lockfile while CI runs `npm install` (not `npm ci`); a stale, hand-written, transitive-omitting SBOM; an audit step with `|| true`/`continue-on-error`/`--audit-level=none`; `ignore-scripts` set locally but not in CI/Docker; scoped packages with no registry restriction; a `SECURITY.md` claiming SLSA/signature verification with no `cosign verify` anywhere; Dependabot/Renovate present but disabled or its PRs never merged; vendored code with an upstream-version comment but missing later CVE fixes.

**API and Web Service Security** (APISEC) - OWASP API Security Top 10 2023 (API-surface-specific residue; BOLA/BFLA/Broken-Auth live in AUTHZ/AUTHN)
- Excessive data exposure (API3): handlers returning the raw ORM object or `fields = '__all__'` instead of an explicit response DTO, leaking sensitive fields the client is trusted to ignore.
- Resource consumption (API4): no rate limiting on auth/OTP/reset/search/export (and auth not held to a stricter limit); client-controlled `limit`/`page_size` with no server max; missing body-size and upload caps; per-request paid actions (SMS/email/LLM spend) with no quota; GraphQL with no query depth/complexity/cost limit and array-batched operations bypassing per-request limits.
- Sensitive business-flow abuse (API6): high-value flows (checkout, signup, reservation, coupon/referral redemption) reachable purely via API with no anti-automation control.
- SSRF on the API surface (API7): webhook-target registration, import-from-URL, and link preview without a scheme/host allowlist and RFC1918/loopback/link-local blocking; redirect-following and DNS-rebinding gaps.
- API misconfiguration and inventory (API8/API9): verbose errors and permissive CORS on API responses; GraphQL introspection/Playground or Swagger UI exposed in production; old/unretired API versions (`/v1`, `/internal`, `/beta`) still mounted with weaker auth; shadow endpoints present in code but absent from the OpenAPI/GraphQL schema; non-prod routes (`if (env !== 'production')`) reachable.
- Unsafe consumption of third-party APIs (API10): upstream/partner responses passed straight into SQL/shell/templates or echoed to clients; outbound integration clients with TLS verification disabled, no timeout, and redirect-following that can exfiltrate a bearer token.
- Webhooks: inbound receivers verify the provider HMAC signature with replay protection; outbound senders sign payloads and apply the SSRF allowlist.
- Paper controls to hunt: a global rate limiter the auth routes are mounted before; a careful response DTO that one export/GraphQL/v1 path bypasses with the raw object; an SSRF validator that checks the host before the redirect hop; mass-assignment protection on create but raw `req.body` on update; a CORS config that names origins in a comment while the middleware reflects `Origin`; TLS enforced in the main client but `verify=False` in one "temporary" partner client; a deprecated `/v1` still mounted on the origin behind a WAF that only fronts the gateway.

**Logging, Monitoring and Data Privacy** (LOGPRIV) - OWASP A09:2025 / A09:2021; privacy part conditional on regulated data (GDPR, PCI-DSS v4.0.1, HIPAA 164.312, SOC 2)
- Security events logged: both success and failure for auth, logout, password reset, MFA, and token issuance, with principal id, source IP, and timestamp; access-control denials (the 403/`ForbiddenException` branch) are not silently dropped; high-value/state-changing actions (payments, role grants, admin CRUD, bulk export, deletion) leave an actor-action-target audit record.
- Logs are safe: no secrets/credentials/Authorization headers, no PII/PHI/full PAN (mask to first6/last4 per PCI), no whole serialized domain objects; user input is neutralized against CR/LF log injection (CWE-117).
- Logs are usable and durable: each record has a correlation/request id, actor, UTC timestamp, action, and outcome (CWE-223); security events are not emitted at a level dropped in production; logs ship to a separate append-only/WORM sink the app's own account cannot rewrite; clocks are synchronized.
- Detection: alerting/thresholds on repeated auth failures, privilege escalation, and error spikes (the 2025 A09 "alerting" gap), routed to a channel someone reads; logging cannot be silently disabled or fail unnoticed.
- Data privacy (conditional on regulated data): PII/PHI/PAN is identified/classified; data minimization (no `SELECT *` returning SSN/DOB to a name-only UI); retention/deletion exists (TTL, purge job, right-to-erasure that also reaches backups/caches/indexes/logs); regulated fields encrypted at rest and PAN rendered unreadable; consent/lawful basis enforced in code before processing/tracking; reads of regulated records audited (HIPAA 164.312(b), PCI Req 10); third-party data sharing bounded; DSAR access/export/rectification has a code path. Pick the regime from the data (PCI for card data, GDPR for EU personal data, HIPAA for US health data, SOC 2 for B2B attestation).
- Paper controls to hunt: a logger configured but never called in the failed-auth/403 branches; a `redact()`/`maskPII()` wired into one formatter while most statements bypass it; a documented retention policy with no job/TTL that deletes anything; a right-to-erasure endpoint that only soft-deletes and leaves copies in logs/backups; a consent banner the backend ignores; alerts routed to a dead/muted channel; "centralized" logs the app can still delete; a disk-encryption claim while PII columns are plaintext; a stale data map that no longer matches the schema; a compliance badge with no controls in code.

**Cloud, Container and Infrastructure-as-Code Security** (IAC) - CONDITIONAL on Dockerfiles, K8s/Helm manifests, or IaC files; CIS Docker/K8s/AWS, NIST SP 800-190, K8s Pod Security Standards
- Dockerfile: a non-root `USER` after installs; a digest-pinned base image (not `:latest`); no secrets in `ARG`/`ENV`/`COPY` (recoverable from layers; use `--mount=type=secret`); a minimal base (distroless/slim) without leftover build tools; `HEALTHCHECK` present; `COPY` over remote `ADD`.
- Kubernetes: no `privileged`/`hostPID`/`hostIPC`/`hostNetwork`; a `securityContext` with `runAsNonRoot`, `allowPrivilegeEscalation: false`, `readOnlyRootFilesystem`, and `drop: ["ALL"]` capabilities; no sensitive `hostPath` (especially `/var/run/docker.sock`); resource limits set; least-privilege RBAC (no `verbs/resources/apiGroups: ["*"]`, no cluster-admin bindings, `automountServiceAccountToken: false`); a default-deny NetworkPolicy; Pod Security Admission set to `enforce` (not `warn`/`audit`).
- Cloud/IaC: no public object storage (S3 public-access-block all-true, no `acl=public-read`, no `Principal:"*"`); no `0.0.0.0/0` ingress to SSH/RDP/DB ports; encryption at rest on RDS/EBS/S3/etc.; no publicly accessible databases; no wildcard IAM (`Action:"*"`/`Resource:"*"`, `*FullAccess`, `iam:PassRole` with `*`); no hardcoded secrets in `.tf`/`.tfvars`/values.yaml or plaintext k8s Secret manifests; IMDSv2 required (`http_tokens=required`); audit logging (CloudTrail/flow logs) and KMS key rotation on.
- Pipeline: image scanning/SBOM and signature/admission verification; IaC scanning (Checkov/Trivy/kube-linter) in CI that actually blocks on high/critical.
- Paper controls to hunt: a PSA label set to `warn`/`audit` only; an S3 public-access-block resource not attached to the bucket; pod-level `runAsNonRoot` overridden by a container `runAsUser: 0` or a root image; a KMS block referencing the wrong/no `kms_key_id`; a restrictive IAM policy written but never attached while a `*FullAccess` policy grants the real access; an IMDSv2 block on a template the running instances do not use; a Checkov/Trivy step with `--soft-fail`/`|| true`; a k8s Secret used while the same value is also a plaintext env var; a non-root Dockerfile that re-escalates via `sudo` at runtime.

**AI / LLM Application Security** (LLMSEC) - CONDITIONAL on LLM/AI usage; OWASP Top 10 for LLM Applications 2025, NIST AI 600-1, MITRE ATLAS
- Prompt injection (LLM01): untrusted user input concatenated/interpolated into the prompt or system message with no role separation; indirect injection from retrieved/fetched content (web, email, PDF, RAG docs, tool output) acted on as trusted.
- Improper output handling (LLM05): model output passed to `eval`/`exec`/`pickle.loads`/`subprocess(shell=True)` (RCE), interpolated into SQL (injection), rendered with `dangerouslySetInnerHTML`/`|safe`/unsanitized Markdown (XSS), or used as a URL/path that is fetched/opened (SSRF/traversal) without validation.
- Excessive agency (LLM06): high-impact tools (delete, transfer funds, send email, run shell, modify infra) with no human-in-the-loop confirmation or per-action authorization; tools running with broad/ambient credentials instead of scoped per-user least privilege; autonomous loops with no max-iteration or cost/step budget.
- System prompt leakage (LLM07): secrets (API keys, connection strings) embedded in the system prompt; authorization rules enforced only by prompt instructions ("only admins may...") rather than code.
- Sensitive information disclosure (LLM02): PII/PHI/secrets or other users' data placed into context or returned without redaction or scoping; conversation logs storing full sensitive prompts.
- RAG and supply chain (LLM08/LLM04/LLM03): vector retrieval that does not apply the requesting user's permission/tenant filter (cross-tenant leakage); documents embedded from untrusted sources with no validation (RAG poisoning); training/fine-tune data or model weights loaded from unverified sources (`torch.load`/pickle of remote checkpoints, HuggingFace repo with no revision pin/hash).
- Unbounded consumption (LLM10): no per-user rate limit, `max_tokens`/context cap, request-size validation, or spend guardrail; agent fan-out/recursion with no global token/step budget and no timeout.
- Misinformation (LLM09): high-stakes output consumed with no grounding, citation check, or human review.
- Paper controls to hunt: a prompt-injection/guardrail filter defined but never called before the model request; a system prompt whose rules are the only enforcement; an output validator that runs in non-blocking mode or is swallowed by a `try/except`; a RAG pipeline that advertises per-document access control but whose similarity query has no ACL filter; gateway rate limiting that exempts the LLM/agent endpoint; a human-in-the-loop confirmation that defaults to auto-approve or only gates the first call in a loop.

### Phase 3 - Verify adversarially and cluster
- For each candidate, try to refute it: is there a guard, framework default, gateway/WAF, or test elsewhere that neutralizes it? Is the reachable path actually reachable given auth and config? Is it a documented, intentional trade-off? Adjust or drop.
- Assign Severity, Confidence, and Effort (definitions below).
- Default to caution: if you could not confirm reachability or the control's absence by reading the code, mark it Suspected and say what would confirm it (a specific request, a config value, a scanner run).
- Cluster repeated instances of one underlying problem into a single systemic pattern, keeping the instance IDs as members.

### Phase 4 - Score
First decide which dimensions are **active** vs **N/A** based on the surfaces found in Phase 0. Score each active dimension 0-100 on control adequacy (justified by its findings). The overall score is the weighted average of the active dimensions.

| Dimension | Weight | Applies |
|---|---|---|
| Authorization and Access Control (AUTHZ) | 18% | always |
| Injection and Unsafe Input Handling (INJ) | 16% | always |
| Authentication and Session Management (AUTHN) | 15% | always (if any auth surface; else fold its weight) |
| Cryptography and Data Protection (CRYPTO) | 11% | always |
| Security Misconfiguration and Hardening (MISCFG) | 9% | always |
| Dependencies and Software Supply Chain (SUPPLY) | 9% | always |
| Secrets Management (SECRET) | 8% | always |
| API and Web Service Security (APISEC) | 6% | if an API/web surface exists |
| Logging, Monitoring and Data Privacy (LOGPRIV) | 4% | always (privacy half only if regulated data) |
| Cloud, Container and Infrastructure-as-Code Security (IAC) | 2% | only if container/IaC files exist |
| AI / LLM Application Security (LLMSEC) | 2% | only if LLM/AI is used |

**Conditional re-normalization:** when a conditional dimension is N/A, drop it from the table and re-normalize the remaining weights to sum to 100 by proportional scaling (do not zero-and-keep, which would deflate the score). When AI/LLM or Cloud/IaC is present, re-normalization naturally raises its effective contribution above its 2-point baseline, which is intended (the baseline only stops these from dominating a generic score). Report which dimensions were active vs N/A so the score is reproducible.

Score bands (per dimension and overall): 90-100 = A (exemplary), 80-89 = B (solid, minor issues), 70-79 = C (adequate, real gaps), 60-69 = D (weak, systemic problems), 0-59 = F (failing, critical deficiencies).

**Risk does not average away.** A single Critical finding caps its dimension at 69 and caps the overall at 79 until resolved. Treat severity independently of the weighted average: the following are Critical regardless of the numeric score: an unauthenticated or trivially exploitable IDOR/BOLA on PII or financial objects; a user-settable role/privilege field; broken multi-tenant isolation; RCE via injection or insecure deserialization; `alg:none`/unsigned-JWT acceptance; reversible or fast-hashed password storage; a confirmed live committed secret; a public storage bucket or `0.0.0.0/0` to a database; or prompt injection feeding a shell/eval/SQL sink. Justify every dimension score against its specific findings. No number without a reason.

### Phase 5 - Prioritize
Definitions:
- **Severity** - Critical (remotely or trivially exploitable, leading to RCE, auth bypass, mass data exposure, privilege escalation, or financial loss; act immediately) / High (a serious vulnerability exploitable under realistic conditions or a missing control on a sensitive flow; act this cycle) / Medium (a real weakness exploitable only with preconditions, in defense-in-depth, or on a lower-value surface; schedule it) / Low (minor hardening gap or theoretical issue; batch it).
- **Confidence** - Confirmed (verified by reading the code; the source-to-sink path and the absence of a compensating control are reproducible from the cited evidence) / Likely (strong evidence resting on a stated runtime, config, or deployment assumption) / Suspected (inferred without confirming reachability or the control's absence; verify before acting).
- **Effort** - S (localized, under ~1 hour) / M (a few files, ~half a day) / L (cross-cutting or needs design, multiple days).

Bucket every finding: **Quick wins** (High/Critical, Confirmed, S), **Plan now** (High/Critical, M or L), **Verify first** (any Suspected, especially anything whose reachability needs a running instance or a scanner), **Backlog** (Low). Order the "What to fix first" list as the union of Quick wins and Plan now, Critical before High, breaking ties toward findings that also close a systemic pattern or sit on a primary trust boundary.

### Phase 6 - Write secaudit.md
Write to `<codebase-root>/secaudit.md` with these sections in order. Keep finding IDs stable using a dimension prefix and number: AUTHZ, AUTHN, INJ, CRYPTO, SECRET, MISCFG, SUPPLY, APISEC, LOGPRIV, IAC, LLMSEC (for example `AUTHZ-001`).

1. **Title and banner** - project name; a line stating this is a read-only security audit, the date, that no exploits were run, and that the report is self-contained.
2. **Snapshot** - project, state (commit or branch), languages, size, frameworks, entry points, deployment context and data sensitivity, security surfaces present vs N/A, evident maturity, audit coverage (exhaustive or sampled, with what was sampled), exclusions.
3. **Attack surface and trust boundaries** - the half-page map from Phase 1: entry points, trust boundaries, sensitive assets, roles, and the highest-risk flows traced.
4. **Overall score** - `NN/100 - Grade X (label)`, a two-to-four sentence specific security verdict, and a one-line calibration note. Then a scorecard table: Dimension, Score, Grade, Weight (after re-normalization), Active/N-A, one-line specific verdict; final row is the weighted overall. State which conditional dimensions were dropped and how weights were re-normalized.
5. **What to fix first** - the ordered priority list. Each line: `[ID] title - severity, effort - one-line why`.
6. **Strengths (preserve these)** - the controls the codebase gets right, each with evidence. The acting agent must not remove these while fixing other issues.
7. **Systemic patterns (root causes)** - one entry per recurring root cause: what it is, the member finding IDs, and the one root fix.
8. **Findings** - sorted by severity then dimension. Each finding is a self-contained block in this exact shape:

   ```
   ### [AUTHZ-001] <title>
   - Severity: <Critical/High/Medium/Low> | Confidence: <Confirmed/Likely/Suspected> | Effort: <S/M/L> | Dimension: <name>
   - Location: `file:line` (and other locations)
   - Evidence: <what the code does now, precisely, including the source-to-sink path>
   - Attack path: <who, from where, with what input, to what effect; the precondition>
   - Impact: <the concrete consequence; what an attacker gains>
   - Recommendation: <specific change and the safe pattern; not a platitude; no working exploit>
   - Verify the fix: <a test to add, a request whose response should change, or a check to run>
   - References: <CWE / OWASP IDs, e.g. CWE-89, A05:2025>
   - Related: <systemic pattern or finding IDs, or "none">
   ```

9. **Dimension notes** - one short subsection per active dimension tying the score to its findings, and a line for each N/A dimension saying why it was skipped.
10. **Remediation plan** - the four buckets (Quick wins, Plan now, Verify first, Backlog) listed by ID, with Plan now in suggested order.
11. **Scope and limitations** - what was and was not examined, sampling decisions, whether any finding needs a running instance or a scanner to confirm, and assumptions (deployment context, threat model) that would change conclusions if untrue.
12. **How to use this report (for the acting agent)** - include this protocol verbatim:
    1. Triage by severity and confidence. Confirmed Critical and High are safe to act on now, in the order in "What to fix first". Re-verify any Suspected finding against the cited code (and its reachability) before changing anything.
    2. Fix root causes first; prefer systemic patterns (a central authorization or validation layer) over individual leaves.
    3. Preserve the strengths; do not remove a working control while fixing another issue.
    4. Confirm the stated assumption on Likely findings before acting.
    5. One finding, one change, verified: after each fix run its "Verify the fix" step; keep changes atomic and traceable to the finding ID.
    6. Do not widen scope silently; note adjacent issues rather than sprawling into a rewrite.
    7. Re-run the audit to measure progress; confirm findings are resolved, not relocated, and watch for regressions in the strengths.

### Phase 7 - Report in chat
After the file is written, print a concise summary to the chat so the user sees the result without opening the file. Include, in this order:
- One headline line: `Security audit complete: NN/100 (Grade X)` followed by the one-line security verdict.
- The scorecard table (active dimensions plus the weighted overall; note any N/A dimensions).
- "What to fix first": the top three to five items, each `[ID] title - severity, effort`.
- Counts: number of findings by severity (for example `Critical 2, High 5, Medium 8, Low 6`).
- The path to the full report: `Full report: ./secaudit.md`.
Keep it tight. The file holds the detail; the chat holds the verdict and the next actions.

---

## Quality gates (self-check before declaring done)

- Every finding cites at least one `file:line` and, where relevant, the source-to-sink path. Run the substitution test on each title and impact line; rewrite anything that would read true for a different repo.
- Every finding states an attack path and precondition; presence alone is not enough.
- Every dimension score has a justification tied to specific findings, and conditional re-normalization is shown.
- Every finding has Severity, Confidence, and Effort set, and CWE/OWASP references.
- Every recommendation says what to change, the safe pattern, and how to verify it. No platitudes and no working exploit code.
- Repeated issues are clustered into systemic patterns; there are not many near-identical findings left loose.
- Paper controls were actively hunted, not just absences (declared-but-unwired guards, validators never called, scanners with `continue-on-error`).
- Suspected findings are clearly marked with what would confirm them.
- The attack-surface/trust-boundary map and the Strengths section are present and evidence-backed.
- Scope, deployment-context calibration, and limitations are stated honestly.
- The "How to use this report" protocol is present.
- The report is at the codebase root, named exactly `secaudit.md`, no source files were changed, no exploit was run, and the chat summary was printed.

## Notes
- Read-only and non-destructive. Use search and read tools to investigate, and shell commands only for inspection (manifests, line counts, version-control and history state, listing dependency versions). Do not edit source, run migrations, execute the project's code, run exploits, or touch any live system.
- Reason about exploitability from the code; never weaponize. The report describes weaknesses and fixes, not attacks others can copy-paste.
- A green scanner proves nothing on its own. Prefer source-to-sink and control-to-code evidence over scanner summaries, and explicitly hunt the paper controls a passing scan can mask.
- Scale effort to blast radius and exposure: spend the most time on internet-facing entry points, authentication and authorization, and the code that guards money, secrets, and personal data.
- For a large codebase, sample deliberately (entry points, auth and access-control code, query and command sinks, secret handling, security config) and declare exactly what you sampled.
- Cite both OWASP 2025 and 2021 category IDs in findings where helpful, since many programs still reference 2021.
