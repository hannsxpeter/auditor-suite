# AUTHZ: Authorization and Access Control

Weight 18. Always active.
Owns: whether each operation checks that this caller may do this to this record: object-level and function-level checks, deny-by-default, privilege fields, mass assignment, excessive data exposure, tenant isolation.
Not here: how identity is established, tokens, sessions (AUTHN); rate limits (APISEC); the CORS configuration (MISCFG).
Standards: OWASP A01:2025 (A01:2021), API1, API3, and API5:2023, ASVS V8.
Read first: the route table, the auth or policy middleware and where it is mounted, and one handler per resource that reads or changes records.

## Cards

### AUTHZ-R1 Record read or changed by a request ID with no owner or tenant check (quick)
- Leads: `scan.sh AUTHZ-R1` lists record lookups that take an ID from the request.
- Confirm: the handler loads, updates, or deletes a record using an ID from the path, query, or body, and neither the query nor an earlier check ties the record to the signed-in user or tenant.
- Not a finding if: the query also filters by the session's user or tenant ID; a policy or middleware on this route checks ownership before the handler runs (read it); the record is public by design.
- Severity: Critical when reachable without authentication or when the record holds personal or financial data; otherwise High. Check write methods (PUT, PATCH, DELETE), not only reads.
- Fix: scope the query to the caller, for example `findOne({ id, ownerId: user.id })`, or call the central policy before acting.
- Verify the fix: a test where user B requests user A's record gets 403 or 404.
- Refs: CWE-639, OWASP A01:2025, API1:2023

### AUTHZ-R2 Privileged operation without an enforced role or permission check (quick)
- Leads: `scan.sh AUTHZ-R2` lists admin, internal, and management routes and role checks.
- Confirm: an admin or privileged route (user management, refunds, configuration, exports) runs without a server-side role or permission check, or its mutating verbs lack the guard its GET has.
- Not a finding if: a router-level guard covers the route (read where it is mounted); the route is unreachable in production (cite the gate).
- Severity: Critical when any signed-in or anonymous user can reach it; High when it needs an unusual precondition.
- Fix: enforce the role on the server for every verb through the central policy; hiding the link in the UI is not a control.
- Verify the fix: a request from a normal user to each verb returns 403.
- Refs: CWE-285, OWASP A01:2025, API5:2023

### AUTHZ-R3 Client can set protected fields such as role, owner, tenant, or price (quick)
- Leads: `scan.sh AUTHZ-R3` lists whole-body binds and protected fields assigned from the request.
- Confirm: request data is bound to a record wholesale (`Object.assign(user, req.body)`, `Model.create(req.body)`, `permit!`, `**request.json`), or a role, admin flag, owner, tenant, balance, or price is taken from the request.
- Not a finding if: an allowlist, DTO, or serializer strips protected fields first (read it); the field is recomputed on the server after binding.
- Severity: Critical when a user can raise their own privileges or take ownership; High otherwise.
- Fix: bind through an explicit allowlist of editable fields; set role, owner, and tenant from the session only.
- Verify the fix: a request that sends `"role": "admin"` leaves the stored role unchanged.
- Refs: CWE-915, OWASP A01:2025, API3:2023

### AUTHZ-R4 Tenant isolation depends on a value the client controls (quick)
- Leads: `scan.sh AUTHZ-R4` lists tenant, organization, and account IDs read from headers, query, or body.
- Confirm: queries on tenant data are scoped by an ID from a header, query string, or body instead of the session, or some tenant-data queries have no tenant filter at all.
- Not a finding if: the value is checked against the session's memberships before use; row-level security or a mandatory ORM scope enforces the tenant (read it).
- Severity: Critical, because one tenant can read or change another tenant's data.
- Fix: derive the tenant from the authenticated session and enforce it in one place (row-level security or a scoped repository).
- Verify the fix: a request that carries another tenant's ID returns only the caller's rows.
- Refs: CWE-639, OWASP A01:2025

### AUTHZ-R5 Authorization is opt-in per route instead of deny-by-default
- Leads: `scan.sh AUTHZ-R5` lists permit-all rules, auth skips, and public markers.
- Confirm: a new route is public unless someone remembers to add a guard: `anyRequest().permitAll()`, a list of protected paths, a guard mounted after the router, or `skip_before_action` on sensitive controllers.
- Not a finding if: a global guard runs first and public routes are explicit, reviewed exceptions.
- Severity: High on an internet-facing app; Medium on an internal tool.
- Fix: apply authentication and authorization globally and mark public routes explicitly.
- Verify the fix: a test that walks the route table and asserts each route is guarded or on the public allowlist.
- Refs: CWE-862, OWASP A01:2025, ASVS V8

### AUTHZ-R6 Responses expose fields the caller should not see
- Leads: `scan.sh AUTHZ-R6` lists handlers that return whole records and all-fields serializers.
- Confirm: a handler returns an ORM object, a full record, or a `fields = '__all__'` serializer, and the record includes password hashes, tokens, internal flags, or other users' personal data.
- Not a finding if: a DTO, serializer allowlist, or `toJSON` strips the sensitive fields (read it).
- Severity: High when secrets or other users' personal data leave; Medium for internal-only fields.
- Fix: return an explicit response type with an allowlist of fields.
- Verify the fix: the route's response body no longer contains the sensitive field names.
- Refs: CWE-213, OWASP API3:2023

## Also check
- List, search, and export endpoints that return rows across owners or tenants (file under AUTHZ-R1 or AUTHZ-R4).
- Signed URLs and storage keys that are not scoped to the requester.
- CORS treated as the access-control boundary while the endpoints behind it check nothing (the CORS setting itself is MISCFG).

## Paper controls (look protective, protect nothing)
- A policy decorator or `@PreAuthorize` defined but never applied to the routes it should guard.
- An `isOwner()` helper written and tested but never called, or its return value ignored.
- Tenant filtering in the UI but not in the API.
- A guard registered after the router, so the handler runs first.
