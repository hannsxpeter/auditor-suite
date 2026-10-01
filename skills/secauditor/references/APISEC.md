# APISEC: API and Web Service Security

Weight 6. Active when HTTP routes or API handlers exist.
Owns: the API-surface residue of the OWASP API Top 10: unbounded resource consumption (rate limits outside login, page sizes, body and upload caps, GraphQL cost), sensitive business flows open to automation, API inventory (old versions, shadow and non-production routes, exposed schema explorers), unsafe consumption of third-party APIs, and webhook signing.
Not here: object- and property-level access (AUTHZ); login throttling and authentication (AUTHN); SSRF (INJ-R4); CORS and verbose errors (MISCFG); TLS on outbound clients (CRYPTO); deprecation signals and breaking-change versioning of the product's own public API (productauditor SHIP-R5, SHIP-R6); an unreleased feature's route that skips the release flag the UI checks (productauditor SHIP-R2).
Standards: OWASP API Security Top 10 2023 (API4, API6, API8, API9, API10), CWE-770, 400, 345.
Read first: the route table and its versions, the rate-limit and body-parser setup, GraphQL server options, webhook receivers and senders, and outbound integration clients.

## Cards

### APISEC-R1 Expensive or bulk endpoints without rate limits or size caps
- Leads: `scan.sh APISEC-R1` lists rate-limit middleware, body-parser limits, `limit`, `page_size`, and `per_page` handling.
- Confirm: search, export, report, upload, or other expensive endpoints have no per-client rate limit; a client-supplied `limit` or `page_size` has no server maximum; request bodies or uploads have no size cap; or per-request paid actions (SMS, email, LLM calls) have no quota.
- Not a finding if: a gateway or middleware limits these exact routes before the handler (cite the config); the server clamps page sizes.
- Severity: High when a single client can run up cost or take the service down; Medium otherwise.
- Fix: rate-limit per client on expensive routes, clamp `limit` to a server maximum, cap body and upload sizes, and put quotas on paid actions.
- Verify the fix: `?limit=100000` returns at most the maximum page size, and the limiter returns 429 past its threshold.
- Refs: CWE-770, CWE-400, API4:2023

### APISEC-R2 GraphQL without depth, complexity, or batching limits
- Leads: `scan.sh APISEC-R2` lists GraphQL server setup, `introspection`, depth-limit, and cost plugins.
- Confirm: the GraphQL server has no query depth, complexity, or cost limit, accepts arrays of operations that bypass per-request limits, or leaves introspection and a playground on in production.
- Not a finding if: depth and cost limits are configured and introspection is disabled in production (cite both).
- Severity: High for no depth or cost limit on a public endpoint; Medium for introspection alone.
- Fix: add depth and cost limits, cap batch size, and disable introspection and playgrounds in production.
- Verify the fix: a query nested beyond the limit is rejected before execution.
- Refs: CWE-770, API4:2023, API8:2023

### APISEC-R3 High-value business flow open to automation
- Leads: read the checkout, signup, coupon, referral, reservation, and gift-card handlers named in the route table.
- Confirm: a flow with monetary or scarcity value can be driven purely through the API at machine speed with no anti-automation control (per-account limits, velocity checks, CAPTCHA, or one-use tokens).
- Not a finding if: the flow has per-account or per-device limits enforced on the server.
- Severity: High for money, credits, or scarce inventory; Medium otherwise.
- Fix: enforce per-account and per-device limits and single-use tokens on the flow.
- Verify the fix: a test that redeems the same coupon twice or signs up 50 accounts from one client is refused.
- Refs: API6:2023, CWE-799

### APISEC-R4 Old, shadow, or non-production API routes still mounted
- Leads: `scan.sh APISEC-R4` lists `/v1`, `/beta`, `/internal`, `/debug`, and routes guarded by `NODE_ENV` or environment checks, plus Swagger and API docs routes.
- Confirm: an older API version with weaker checks, an internal or debug route, a non-production route that production can reach, or an endpoint missing from the published schema is mounted; or Swagger UI or schema explorers are open in production.
- Not a finding if: the route is removed at build time or unreachable in production (cite the gate).
- Severity: High when the older or shadow route skips auth or checks the current version has; Medium otherwise.
- Fix: remove or protect retired and internal routes, keep the API inventory in step with the code, and disable docs explorers in production.
- Verify the fix: the old and internal routes return 404 under production settings.
- Refs: API9:2023, API8:2023, CWE-1059

### APISEC-R5 Webhooks received without signature verification, or sent without signing
- Leads: `scan.sh APISEC-R5` lists webhook routes and signature header handling (`stripe-signature`, `x-hub-signature`, HMAC).
- Confirm: an inbound webhook acts on the payload without verifying the provider signature (with a constant-time comparison and replay protection by timestamp or event ID), or outbound webhooks are sent unsigned.
- Not a finding if: the provider SDK verifies the signature before the handler reads the body (read the order).
- Severity: High when the webhook changes money, orders, or accounts; Medium otherwise.
- Fix: verify signatures with the provider SDK or a constant-time HMAC check over the raw body, reject stale timestamps, and dedupe event IDs; sign outbound payloads.
- Verify the fix: a test that posts a payload with a wrong signature gets 400 and changes nothing.
- Refs: CWE-345, CWE-347, API10:2023

### APISEC-R6 Third-party API responses trusted as safe input
- Leads: `scan.sh APISEC-R6` lists outbound client calls whose responses reach queries, templates, shells, or redirects.
- Confirm: data from a partner or upstream API is passed into SQL, a shell, a template, or a redirect, or echoed to clients without validation; or the integration client has no timeout and follows redirects that could carry a bearer token elsewhere.
- Not a finding if: responses are validated against a schema before use and the client pins timeouts and redirect rules.
- Severity: High when the response reaches an injection sink; Medium otherwise.
- Fix: validate third-party responses against a schema, treat them as untrusted input at every sink, and set timeouts and redirect limits.
- Verify the fix: a test with a malicious upstream response is rejected by validation.
- Refs: API10:2023, CWE-20

## Also check
- Mass assignment protection on create but raw `req.body` on update (file under AUTHZ-R3).
- A careful response DTO that one export, GraphQL, or v1 path bypasses with the raw object (file under AUTHZ-R6).

## Paper controls (look protective, protect nothing)
- A global rate limiter mounted after the routes it should cover.
- A deprecated `/v1` still mounted on the origin behind a WAF that only fronts the gateway.
- Webhook signature code that computes the HMAC but never compares it, or compares with `==`.
- API docs claiming a version is retired while its router is still registered.
