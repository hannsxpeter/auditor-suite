# CRYPTO: Cryptography and Data Protection

Weight 11. Always active.
Owns: encryption algorithms and modes, IVs and nonces, randomness for security values, home-rolled crypto, key handling and sizes, TLS in transit (inbound and outbound, including disabled certificate checks), and protection of sensitive data at rest, in caches, and in URLs.
Not here: password hashing and credential comparison (AUTHN); hardcoded keys and secret storage (SECRET); personal data in logs (LOGPRIV); database column encryption depth (dbauditor); customer-facing encryption guarantees the code contradicts (productauditor CLM-R5).
Standards: OWASP A04:2025 (A02:2021), ASVS V11 and V12, NIST SP 800-131A, 800-52, 800-57.
Read first: the crypto or security utility module, every place that encrypts, signs, or generates tokens, and the HTTP client and server setup.

## Cards

### CRYPTO-R1 Broken algorithm or mode protects confidentiality or integrity
- Leads: `scan.sh CRYPTO-R1` lists MD5, SHA-1, DES, 3DES, RC4, ECB, and `createCipher` (without iv) calls.
- Confirm: a deprecated primitive or mode protects data or integrity (not a cache key or checksum): MD5 or SHA-1 for signatures or integrity, DES, 3DES, RC4, AES in ECB mode, or an unauthenticated mode where tampering matters.
- Not a finding if: the hash is used only for non-security purposes (cache keys, ETags, deduplication) and says so.
- Severity: High when it protects secrets, tokens, or personal data; Medium otherwise.
- Fix: use authenticated encryption (AES-GCM or ChaCha20-Poly1305) and SHA-256 or better, through a vetted library.
- Verify the fix: the call site uses the AEAD API and a tampered ciphertext fails to decrypt.
- Refs: CWE-327, CWE-328, OWASP A04:2025

### CRYPTO-R2 Static, reused, or predictable IV, nonce, or security random value (quick)
- Leads: `scan.sh CRYPTO-R2` lists `Math.random`, `random.random`, `java.util.Random`, `rand()`, fixed IVs, and seeded `SecureRandom`.
- Confirm: tokens, salts, IVs, one-time codes, session IDs, or reset tokens come from a non-cryptographic generator; an IV or nonce is hardcoded, all zeros, or reused under the same key (fatal for GCM).
- Not a finding if: the value comes from a CSPRNG (`secrets`, `crypto.randomBytes`, `crypto.randomUUID`, `SecureRandom` unseeded).
- Severity: Critical when it makes session, reset, or auth tokens guessable or breaks GCM confidentiality; High otherwise.
- Fix: generate from the platform CSPRNG and a fresh random nonce per encryption.
- Verify the fix: the generator call is the CSPRNG and two encryptions of the same plaintext produce different ciphertexts.
- Refs: CWE-330, CWE-338, CWE-329, OWASP A04:2025

### CRYPTO-R3 Certificate or hostname verification disabled (quick)
- Leads: `scan.sh CRYPTO-R3` lists `verify=False`, `rejectUnauthorized: false`, `InsecureSkipVerify`, `NODE_TLS_REJECT_UNAUTHORIZED`, all-trusting TrustManagers, and `curl -k`.
- Confirm: an outbound TLS client (HTTP, database, SMTP, internal service) skips certificate or hostname checks on a path that runs in production.
- Not a finding if: the branch is test-only and cannot run in production (cite the gate); a pinned internal CA is configured instead.
- Severity: Critical when credentials, tokens, or personal data cross that connection; High otherwise.
- Fix: enable verification; trust a specific internal CA bundle if needed.
- Verify the fix: the client rejects a self-signed test server.
- Refs: CWE-295, CWE-297, OWASP A04:2025

### CRYPTO-R4 Sensitive data sent or served without TLS
- Leads: `scan.sh CRYPTO-R4` lists `http://` URLs for APIs, auth, and databases, and plaintext listeners.
- Confirm: credentials, tokens, or personal data travel over plain HTTP or an unencrypted database or cache link, or the server accepts plain HTTP with no redirect and no HSTS.
- Not a finding if: TLS terminates at a load balancer in front of a private network and the app is unreachable otherwise (cite the config); the URL is local development only.
- Severity: High on the internet; Medium inside a private network.
- Fix: use HTTPS and TLS links everywhere; add HSTS and an HTTP-to-HTTPS redirect; require TLS 1.2 or later.
- Verify the fix: every external URL in config uses `https://` and the server config sets HSTS.
- Refs: CWE-319, OWASP A04:2025, NIST SP 800-52

### CRYPTO-R5 Home-rolled crypto or weak key handling
- Leads: `scan.sh CRYPTO-R5` lists XOR "encryption", custom cipher functions, short RSA keys, and key derivation from plain strings.
- Confirm: the project implements its own cipher, stretch, or signature scheme; RSA keys are under 2048 bits or EC under P-256; a key is derived from a password with a single hash; or ciphertexts carry no key ID so keys can never rotate.
- Not a finding if: a vetted library does the work and the custom code only wraps it.
- Severity: High when it protects secrets or personal data; Medium otherwise.
- Fix: replace with a vetted library construction; use a KDF (HKDF, scrypt, argon2) for derived keys; store a key ID with each ciphertext.
- Verify the fix: the custom primitive is gone and key sizes meet the minimums.
- Refs: CWE-327, CWE-326, NIST SP 800-57

### CRYPTO-R6 Sensitive data stored or exposed in the clear
- Leads: `scan.sh CRYPTO-R6` lists sensitive fields (ssn, card, pan, dob, diagnosis, token) and responses cached or placed in URLs.
- Confirm: personal, health, or payment data is stored unencrypted where the domain requires protection, cached by browsers or proxies (`Cache-Control` missing `no-store` on sensitive responses), or placed in URL query strings where logs and referrers capture it.
- Not a finding if: storage-level encryption is configured and the data class does not need field-level protection (say which); the value is already tokenized.
- Severity: High for payment or health data; Medium otherwise.
- Fix: encrypt or tokenize sensitive fields, send `Cache-Control: no-store` on sensitive responses, and move sensitive values out of URLs.
- Verify the fix: the sensitive column holds ciphertext in a fixture row and the response headers include `no-store`.
- Refs: CWE-311, CWE-312, CWE-598, OWASP A04:2025

## Also check
- AES-GCM nonces reused under a key across restarts (a counter reset to zero).
- Keys loaded from a KMS with a hardcoded fallback key that is what actually runs (the hardcoded key itself is SECRET).
- TLS 1.0 or 1.1, NULL, EXPORT, RC4, or non-forward-secret ciphers enabled in server config.

## Paper controls (look protective, protect nothing)
- A `CryptoUtil` with AES-GCM that the persistence path never calls.
- "TLS required" in docs while a plaintext port is still bound.
- Certificate verification disabled in a `dev` branch that production can reach.
- A KMS client with a hardcoded fallback key that is used whenever the KMS call fails.
