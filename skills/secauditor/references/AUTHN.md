# AUTHN: Authentication and Session Management

Weight 15. Active when login, session, token, or password code exists.
Owns: how identity is established and kept: password storage, credential and token comparison, brute-force defenses on login, MFA, and reset, sessions and their cookies, JWT validation, OAuth and OIDC flows, account recovery, and trusting identity headers.
Not here: what an identified user may do (AUTHZ); secrets used to sign tokens (SECRET); TLS (CRYPTO); rate limits on non-auth endpoints (APISEC).
Standards: OWASP A07:2025 (A07:2021), ASVS V6, V7, V9, V10, NIST SP 800-63B-4, RFC 9700 (OAuth 2.0 security BCP), RFC 8725 (JWT BCP).
Read first: the login, logout, signup, reset, and MFA handlers, the session or token middleware, and the user model's password field.

## Cards

### AUTHN-R1 Passwords stored with a fast hash, no salt, or reversible encryption (quick)
- Leads: `scan.sh AUTHN-R1` lists MD5, SHA-1, SHA-256, and encryption calls near password code.
- Confirm: passwords are hashed with a general-purpose digest (MD5, SHA-1, SHA-256, even salted), a single global salt, or reversible encryption, or stored in plaintext.
- Not a finding if: an adaptive, memory-hard KDF is used (argon2id, scrypt, bcrypt, or PBKDF2-HMAC-SHA256 at current iteration counts); legacy hashes are upgraded on next login (read the code path).
- Severity: Critical: one database leak exposes every password.
- Fix: hash with argon2id or bcrypt through a maintained library and rehash legacy hashes on successful login.
- Verify the fix: the stored hash for a new user starts with the algorithm prefix (for example `$argon2id$` or `$2b$`).
- Refs: CWE-916, CWE-759, OWASP A04:2025, NIST SP 800-63B-4

### AUTHN-R2 Credentials, tokens, or codes compared with ordinary equality
- Leads: `scan.sh AUTHN-R2` lists `==` and `===` comparisons against passwords, hashes, tokens, signatures, and one-time codes.
- Confirm: a secret-dependent comparison uses `==`, `===`, `.equals()`, or `strcmp` instead of a constant-time function.
- Not a finding if: the library compares for you (`bcrypt.compare`, `argon2.verify`) or a constant-time helper is used (`hmac.compare_digest`, `crypto.timingSafeEqual`).
- Severity: Medium (a timing side channel); High for API keys or HMAC signatures checked over the network.
- Fix: use the library verify function or a constant-time comparison.
- Verify the fix: the call site uses the constant-time helper and a test still accepts valid and rejects invalid values.
- Refs: CWE-208, OWASP A07:2025

### AUTHN-R3 Tokens accepted without verifying signature, algorithm, or expiry (quick)
- Leads: `scan.sh AUTHN-R3` lists `jwt.decode`, `verify=False`, `algorithms` lists, and `ignoreExpiration`.
- Confirm: a JWT or signed token is decoded without signature verification, the algorithm list allows `none` or both HMAC and RSA algorithms (key confusion), or `exp`, `iss`, or `aud` are not checked.
- Not a finding if: verification pins one expected algorithm and checks signature, `exp`, `iss`, and `aud`; `decode` is used only for display after a separate verify.
- Severity: Critical: anyone can mint a token for any user or role.
- Fix: verify with a single pinned algorithm and required claims, for example `jwt.verify(token, key, { algorithms: ['HS256'], issuer, audience })`.
- Verify the fix: a test with an unsigned (`alg: none`) token and one with an expired token both get 401.
- Refs: CWE-347, CWE-345, RFC 8725, OWASP A07:2025

### AUTHN-R4 No brute-force defense on login, MFA, or password reset
- Leads: `scan.sh AUTHN-R4` lists login, MFA, OTP, and reset routes and any rate limiter or lockout.
- Confirm: login, MFA verification, or reset endpoints have no server-side throttling, lockout, or CAPTCHA per account and per IP, or the limiter is mounted after the auth routes or excludes them.
- Not a finding if: a limiter or lockout covers these exact routes before the handler (read the mount order); an identity provider handles login entirely.
- Severity: High on internet-facing login; Medium on internal tools.
- Fix: throttle per account and per IP on login, MFA, and reset; prefer breached-password screening over complexity rules.
- Verify the fix: the eleventh failed attempt within the window returns 429.
- Refs: CWE-307, OWASP A07:2025, NIST SP 800-63B-4

### AUTHN-R5 Session cookies or session lifecycle unsafe
- Leads: `scan.sh AUTHN-R5` lists cookie and session configuration.
- Confirm: session cookies lack `Secure`, `HttpOnly`, or `SameSite`; the session ID is not rotated on login or privilege change (fixation); sessions have no idle or absolute timeout; logout clears the cookie but does not end the session on the server; or the token is also exposed to JavaScript (for example in localStorage).
- Not a finding if: the framework defaults already set these flags (check the version and that nothing overrides them later).
- Severity: High when a flag gap enables theft or fixation of live sessions; Medium otherwise.
- Fix: set the flags, regenerate the session on login, enforce timeouts, and revoke on logout.
- Verify the fix: the Set-Cookie header on login carries `Secure; HttpOnly; SameSite=Lax` (or Strict) and a reused old session ID is rejected after logout.
- Refs: CWE-614, CWE-1004, CWE-384, CWE-613, ASVS V7

### AUTHN-R6 MFA, OAuth, or OIDC flow can be bypassed (quick)
- Leads: `scan.sh AUTHN-R6` lists MFA, OTP, OAuth, `redirect_uri`, `state`, and `nonce` handling.
- Confirm: MFA is a stored flag the login path never checks, or an alternate login route skips it; one-time codes are reusable or unthrottled; OAuth uses the implicit or password grant, matches `redirect_uri` by prefix or regex, or does not generate and check `state` and `nonce`; the authorization code flow lacks PKCE for public clients.
- Not a finding if: a maintained identity provider or library enforces these and the app does not override them.
- Severity: Critical when an attacker can log in as another user; High otherwise.
- Fix: verify MFA on every login path, make codes single-use and throttled, use authorization code with PKCE, match `redirect_uri` exactly, and bind `state` and `nonce` to the session.
- Verify the fix: a login that skips the MFA step for an MFA-enabled user gets no session.
- Refs: CWE-287, CWE-304, RFC 9700, OWASP A07:2025

### AUTHN-R7 Account recovery or default credentials let someone in (quick)
- Leads: `scan.sh AUTHN-R7` lists reset-token generation, default passwords, and auth bypass switches.
- Confirm: reset tokens come from a non-cryptographic source, never expire, or survive use or a password change; errors reveal whether an account exists (on a sensitive product); default, hardcoded, or backdoor credentials exist; or an environment flag skips authentication (`if env == 'dev': skip_auth`) and can be on in production.
- Not a finding if: tokens come from a CSPRNG, are single-use and short-lived, and the bypass switch cannot be enabled in production (cite the gate).
- Severity: Critical for working default or backdoor credentials and guessable reset tokens; Medium for account enumeration.
- Fix: CSPRNG single-use reset tokens with short expiry, invalidated on use and on password change; generic errors; remove defaults and bypasses.
- Verify the fix: a used or expired reset token is rejected, and the bypass flag no longer exists.
- Refs: CWE-640, CWE-798, CWE-204, OWASP A07:2025

### AUTHN-R8 Identity taken from a client-supplied header or claim without verification
- Leads: `scan.sh AUTHN-R8` lists reads of `X-User-Id`, `X-Forwarded-User`, `X-Remote-User`, and similar headers.
- Confirm: the app trusts an identity header or an unverified token claim set by the client, relying on a proxy that is not guaranteed to strip it.
- Not a finding if: the header is set by an authenticating proxy that strips client copies and the app is unreachable except through it (cite the config).
- Severity: Critical when the header is reachable from the internet; High otherwise.
- Fix: authenticate in the app, or verify a signed assertion from the proxy.
- Verify the fix: a direct request with `X-User-Id: 1` is treated as anonymous.
- Refs: CWE-290, OWASP A07:2025

## Also check
- Breached-password screening in place of arbitrary complexity rules (NIST 800-63B-4).
- Session IDs generated from a CSPRNG with enough entropy.
- Sensitive data in the JWT payload (it is base64, not encrypted).
- A strong password policy at signup that the reset or admin-set path skips.

## Paper controls (look protective, protect nothing)
- A constant-time helper defined while the login path still uses `==`.
- MFA shown in the UI but never verified on the server.
- Lockout middleware that excludes `/login`.
- Logout that clears the cookie but never revokes the token.
- A strong hasher imported while the login path still verifies legacy SHA-256 with no upgrade.
