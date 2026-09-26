# Answer key: secauditor full-audit

Never copied into the eval workspace. Lines refer to files under repo/.

## Planted defects

| Grader | Location | Card | Expected severity | Defect |
|---|---|---|---|---|
| finds-order-idor | src/routes/orders.js:12 | AUTHZ-R1 | Critical | `GET /orders/:id` loads any order by ID with no customer check |
| finds-refund-role | src/routes/admin.js:12 | AUTHZ-R2 | Critical | `POST /admin/refunds` needs only a login, not the admin role (`GET /stats` has it) |
| finds-search-sqli | src/routes/search.js:8 | INJ-R1 | Critical | search term concatenated into SQL on an unauthenticated route |
| finds-preview-ssrf | src/routes/preview.js:7 | INJ-R4 | High | server fetches any URL from the query string |
| finds-files-traversal | src/routes/files.js:8 | INJ-R5 | High | `path.join(uploadDir, req.params.name)` then `sendFile` with no containment check |
| finds-jwt-none | src/auth/tokens.js:9 | AUTHN-R3 | Critical | `jwt.verify` allows the `none` algorithm, so unsigned tokens are accepted |
| finds-md5-passwords | src/auth/passwords.js:4 | AUTHN-R1 | Critical | passwords hashed with unsalted MD5, compared with `===` |
| finds-secret-fallback | src/config.js:2 | SECRET-R2 | High | hardcoded JWT secret fallback used whenever the env var is unset |
| finds-cors-reflect | src/server.js:10 | MISCFG-R2 | High | CORS reflects any Origin and allows credentials |
| finds-stack-traces | src/errors.js:5 | MISCFG-R3 | Medium | error handler returns stack traces to clients |
| finds-lodash-version | package.json:15 | SUPPLY-R1 | Medium | lodash pinned to 4.17.15, which has published prototype-pollution and command-injection advisories |

## Decoys (safe; flagging them is a false positive)

| Grader | Location | Why it is safe |
|---|---|---|
| ignores-invoices | src/routes/invoices.js:8 | the lookup is scoped with `AND customer_id = ?` bound to `req.user.id` |
| ignores-reports | src/routes/reports.js:9 | `sort` is checked against the `SORTABLE` allowlist before interpolation; values are bound |

## Strengths worth naming

- Parameterized queries everywhere except search (`src/db.js:6`).
- A rate limiter on `/login` (`src/server.js:15`).
- `requireAdmin` checks the role on `GET /admin/stats` (`src/middleware/auth.js:17`).
