# DBSEC: Security and Data Protection at the Database Layer

Weight 12. Always active. Floor dimension: one Critical finding here holds the overall score at 69.
Owns: the database-specific security slice: injection into SQL and NoSQL queries, database roles and grants, row-level security and tenant isolation in the database, database credentials, network exposure and authentication of the datastore, and protection of sensitive data at rest, in transit, and in backups.
Not here: application authorization and tenant checks in handlers, secrets other than database credentials, and password hashing code (secauditor); search results that bypass tenant filters (SEARCH-R5); multi-tenant unique constraints (CONSTRAINTS-R3); erasure that misses copies (INTEGRITY, Also check).
Standards: CWE, OWASP Top 10 2025 (A05 Injection, A02 Security Misconfiguration, A04 Cryptographic Failures, A01 Broken Access Control), PCI DSS v4.0.1 requirement 3, PostgreSQL privileges and row security docs.
Read first: every place a query string is built, the connection configuration for each environment, grants and policies in migrations, infrastructure files that create or expose the datastore, and seed data.

## Cards

### DBSEC-R1 Request input reaches SQL or a NoSQL query as text (quick)
- Leads: `scan.sh DBSEC-R1` lists queries built by concatenation, interpolation, or format strings, and raw-query escape hatches.
- Confirm: a value from a request, message, file, or another user's stored data is concatenated, interpolated, or formatted into query text (`WHERE`, `VALUES`, `ORDER BY`, `LIMIT`, DDL), or passed to a raw escape hatch without bound parameters: `.raw()`, `.extra()`, `RawSQL`, SQLAlchemy `text()` with an f-string, Sequelize `query` without `replacements` or `bind`, Prisma `$queryRawUnsafe`, Knex `whereRaw('col = ' + v)`, a dbt model templating an untrusted variable; or a JSON object from the request reaches a MongoDB filter unparsed (`{"$gt": ""}`, `$where`). Name the source and the sink in Evidence.
- Not a finding if: the value is bound (`?`, `$1`, `:name`, Prisma `$queryRaw` tagged templates, postgres.js `sql` templates); a dynamic identifier (sort column, table) is looked up in a fixed allowlist or map before use (read it); the value is a constant or deploy-time configuration.
- Severity: Critical when any request, message, or file input reaches the sink; High when only an authenticated operator or internal job controls the value.
- Fix: bind every value; map identifiers through an allowlist (`const col = SORTS.get(String(req.query.sort)) || 'created_at'`); for MongoDB, cast inputs to the expected scalar type and reject objects.
- Verify the fix: a test sends `' OR '1'='1` (or `{"$ne": null}`) and gets no extra rows; no concatenated query text remains on the path.
- Refs: CWE-89, CWE-943, OWASP A05:2025 (A03:2021), SQL Antipatterns "SQL Injection"

### DBSEC-R2 The application connects as a superuser or table owner, or grants are broader than it needs
- Leads: `scan.sh DBSEC-R2` lists connection users, GRANT statements, and role attributes.
- Confirm: the runtime connection user is `postgres`, `root`, `sa`, an admin, or the owner of the tables, or has `SUPERUSER` or `BYPASSRLS`; migrations grant `ALL`, grant `TO PUBLIC`, or grant `pg_read_all_data` or `pg_write_all_data`; or the app and the migration tool share one identity with DDL rights.
- Not a finding if: a separate least-privilege role runs the app and the privileged identity runs only migrations (cite both); the config is for local development only.
- Severity: High on a production configuration (an injected query gets full DDL and DML, and row-level security does not apply to owners and superusers); Medium when you cannot tell which config production uses.
- Fix: a per-service role with DML on its own tables only; DDL reserved to a separate migration role; on PostgreSQL before 15, `REVOKE CREATE ON SCHEMA public FROM PUBLIC`.
- Verify the fix: `SELECT rolsuper, rolbypassrls FROM pg_roles WHERE rolname = 'app'` returns false, false, and `DROP TABLE` as the app role fails.
- Refs: CWE-250, CWE-269; PostgreSQL docs, Privileges

### DBSEC-R3 Database reachable from the internet, or running with default, empty, or trust authentication (quick)
- Leads: `scan.sh DBSEC-R3` lists bind addresses, published database ports, public-access flags, and authentication settings.
- Confirm: a production or shared datastore listens publicly or is open to the internet (`listen_addresses = '*'` with `0.0.0.0/0` in `pg_hba.conf`, `bind-address = 0.0.0.0`, a firewall or security group allowing `0.0.0.0/0` on 5432, 3306, 1433, 27017, 6379, or 9042, `publicly_accessible = true`, a compose file publishing the port on a server); or its authentication is default, empty, or off (`trust` in `pg_hba.conf`, `POSTGRES_HOST_AUTH_METHOD=trust`, `postgres/postgres`, a blank `sa` password, `MYSQL_ALLOW_EMPTY_PASSWORD`, MongoDB without authorization enabled, Redis without `requirepass` or ACLs, or with `protected-mode no`).
- Not a finding if: the file serves only local development or CI (its name, comments, or README say so) and binds to localhost or a private network; a network control in front of the database blocks public access (cite it).
- Severity: Critical when a production or internet-facing datastore is exposed or uses default or empty credentials; High for a shared staging environment; Low for a development file that publishes the port to the local network.
- Fix: private subnet, no public IP, ingress only from the app's security group; `scram-sha-256` authentication with generated credentials from a secret store; auth and private binding for Redis and MongoDB.
- Verify the fix: the port is unreachable from outside the network, and the config has no `trust` lines and no `0.0.0.0/0` ingress on database ports.
- Refs: CWE-1188, CWE-306, CWE-521, OWASP A02:2025

### DBSEC-R4 A live database credential is committed to the repository or its history (quick)
- Leads: `scan.sh DBSEC-R4` lists connection strings with inline passwords and database password assignments, including seed files; run `git log -p -S 'postgres://' --all` (and the other schemes) to search history.
- Confirm: a real password or credentialed connection string (`postgres://user:pass@db.prod.internal/app`, `DB_PASSWORD=...`, a JDBC URL with `password=`) is in a tracked file or in git history; deleting it from HEAD does not revoke it.
- Not a finding if: the value is a placeholder or a local throwaway (`changeme`, `localhost`, `example`, a CI service-container password); it is read from the environment or a secret manager at runtime.
- Severity: Critical when the credential looks live (a non-local host, a production or staging name, or deploy config uses it); High for a shared non-production credential.
- Fix: rotate first, then remove the value and load it from the environment or a secret manager; rewriting history does not replace rotation.
- Verify the fix: the old credential is rejected by the database, and a secret scan of the history finds no live credential.
- Refs: CWE-798

### DBSEC-R5 Sensitive data stored in plaintext columns (quick)
- Leads: `scan.sh DBSEC-R5` lists columns named like identity, card, health, bank, token, and password data.
- Confirm: a column stores government IDs (`ssn`, `national_id`, `passport_number`), full card numbers (`pan`, `card_number`), card verification codes (`cvv`, `cvc`), health data (`mrn`, `diagnosis`), bank account numbers, access tokens for other systems, or passwords as plain text or under a fast unsalted hash (MD5, SHA-1, unsalted SHA-256), and at least one write path stores it without encrypting or tokenizing it. Read every writer: model-level encryption that bulk imports or raw SQL skip still leaves plaintext rows.
- Not a finding if: the column holds a provider token or the last four digits; every write path encrypts with a key held outside the database (pgcrypto with an app-held key, Always Encrypted, client-side field-level encryption); passwords use argon2id, bcrypt, or scrypt. Names, emails, phone numbers, and addresses in an ordinary app are not a finding here unless the README names a regulation that requires encrypting them.
- Severity: Critical for card numbers, government IDs, health records, bank account numbers, and passwords in plaintext or under a fast hash, and for any stored CVV (it may not be kept after authorization at all, even encrypted); High for other sensitive data the README says is regulated.
- Fix: stop storing CVV; tokenize card data through the payment provider; encrypt other sensitive columns with keys held outside the database or move them to a vault; hash passwords with argon2id or bcrypt and rehash at next sign-in.
- Verify the fix: a row read directly with SQL shows ciphertext or a token, and no cvv or cvc column remains.
- Refs: CWE-311, CWE-312, CWE-916, PCI DSS v4.0.1 req. 3.3 and 3.5, OWASP A04:2025

### DBSEC-R6 Tenant isolation is not enforced by the database, or row-level security is bypassed (quick)
- Leads: `scan.sh DBSEC-R6` lists tenant columns, row-level security statements, policies, and session settings.
- Confirm: a multi-tenant schema (`tenant_id`, `org_id`, or `workspace_id` on shared tables) where a query on tenant data lacks the tenant filter; or isolation depends only on hand-written `WHERE tenant_id = ...` in each query, with no central scope and no row-level security; or RLS exists but does not apply: `ENABLE ROW LEVEL SECURITY` without `FORCE` while the app connects as the table owner, an app role with `BYPASSRLS` or superuser, a policy on `current_setting('app.tenant_id')` set with `SET` instead of `SET LOCAL` on pooled connections (the next request inherits the last tenant), or a view without `security_invoker` that reads past RLS.
- Not a finding if: RLS is forced for a non-owner app role and the tenant setting is transaction-scoped (`SET LOCAL`, `set_config(..., true)`); each tenant has its own database.
- Severity: Critical when a tenant-data query lacks the filter, when RLS is present but bypassed, or when isolation rests only on hand-written WHERE clauses; High when a mandatory central scope (a default scope, a scoped repository) enforces the tenant in the app but the database does not.
- Fix: enable and force RLS on tenant tables with policies on `current_setting('app.tenant_id')`, set it with `SET LOCAL` in each transaction, and connect as a non-owner role without `BYPASSRLS`.
- Verify the fix: a test running as tenant A that selects tenant B's rows through the app role gets zero rows.
- Refs: CWE-639, OWASP A01:2025; PostgreSQL docs, Row Security Policies

### DBSEC-R7 Connections without verified TLS, or sensitive data unencrypted at rest or in backups
- Leads: `scan.sh DBSEC-R7` lists TLS options, storage encryption settings, and dump commands.
- Confirm: a connection that crosses an untrusted network does not verify the server (`sslmode=disable`, `prefer`, or `require` instead of `verify-full`; `rejectUnauthorized: false`; JDBC `useSSL=false` or `trustServerCertificate=true`; MongoDB without `tls=true`); or infrastructure code creates a datastore holding sensitive data with storage encryption off; or dumps and backups are written unencrypted or committed to the repository.
- Not a finding if: the database is on the same host or a private link (cite the IaC or README); the platform encrypts storage by default and the IaC does not turn it off.
- Severity: High when credentials or sensitive data cross the internet, or a dump with real data is committed; Medium otherwise.
- Fix: `sslmode=verify-full` with the provider's CA bundle; storage encryption with a managed key; encrypted dumps kept out of the repository.
- Verify the fix: the client config shows certificate verification with a CA, and the IaC plan shows encryption enabled.
- Refs: CWE-295, CWE-311, CWE-319; PostgreSQL docs, SSL Support

## Also check
- No audit trail of reads and writes on sensitive tables (who read or changed a salary or a health record).
- A view that exposes sensitive columns to a role that should not see them (`CREATE VIEW ... AS SELECT * FROM users`).
- `SECURITY DEFINER` functions without a fixed `search_path`, or owned by a superuser: a caller can hijack the objects they resolve.

## Paper controls (look protective, protect nothing)
- RLS enabled but not forced while the app owns the table: every policy is silently skipped (DBSEC-R6).
- An RLS policy keyed to a session setting that pooled connections leave stale.
- A column "encrypted in the model" but stored as plain `TEXT`, with bulk imports or raw SQL skipping the encryption (DBSEC-R5).
- `sslmode=require`: it encrypts but does not verify the server, so a man in the middle still works.
- A password under a fast unsalted hash labeled "hashed".
- A credential deleted from HEAD but live in history and never rotated (DBSEC-R4).
- SQL Server Dynamic Data Masking treated as access control: it masks display only, and anyone who can query can infer the values.
