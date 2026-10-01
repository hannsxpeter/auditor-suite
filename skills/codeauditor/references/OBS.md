# OBS: Observability and Operability

Weight 5. Always active.
Owns: whether the running system can be seen and operated: what is logged and whether logs leak secrets or personal data, metrics, tracing, and error reporting, health and readiness checks, configuration kept out of code and set per environment, schema migrations, and a reproducible build and run.
Not here: secrets hardcoded in code or config (SEC-R5); errors caught and dropped before anything could log them (ERR-R1); lockfiles and version pins (DEP-R5); migration design in depth (dbauditor); analytics project keys shared by every environment, and test or CI traffic counted in product analytics (productauditor MET-R6); billing provider test or sandbox mode selected for production (productauditor BILL-R2).
Standards: CWE-532, CWE-778, CWE-1051, OWASP A09:2025, the Twelve-Factor App (config, logs, build and run).
Read first: the logger setup, the health endpoints, the config loader, the Dockerfile, Procfile, or deploy manifests, the migrations folder, and the CI workflows. Calibrate each card to the project's maturity: a weekend script needs none of the metrics a production service does, and the Calibration line should say which bar you used.

## Cards

### OBS-R1 Secrets or personal data written to logs
- Leads: `scan.sh OBS-R1` lists log and print calls that mention passwords, tokens, keys, cookies, headers, request bodies, or card data.
- Confirm: a log line includes a password, token, API key, session cookie, Authorization header, card number, or other personal data (email, address, government ID), directly or by logging a whole request, header set, or user object.
- Not a finding if: a redaction filter or serializer strips those fields before output (read it); the value logged is a hash or the last four digits.
- Severity: High for passwords, tokens, keys, and card data; Medium for other personal data; Low for internal IDs.
- Fix: log IDs instead of objects, add a redaction filter for sensitive keys at the logger, and purge or rotate what was already logged.
- Verify the fix: a test that logs a request carrying a password and an Authorization header finds both redacted in the output.
- Refs: CWE-532, OWASP A09:2025

### OBS-R2 Failures and key operations leave no useful log
- Leads: `scan.sh OBS-R2` lists print and console calls used as logging. Read the error handler and the payment, auth, and job code on your Map for log calls.
- Confirm: the error handler or a critical operation (payment, login, data export, job failure) logs nothing, or only free text with no level, request ID, or record ID, so an operator cannot tell what failed for whom; or logging is `print` and `console.log` noise with no levels.
- Not a finding if: a framework or middleware logs these events with context (read its config); the project is a small script whose printed output is its interface.
- Severity: High for a production service where money, auth, or data-loss failures leave no trace; Medium otherwise.
- Fix: use one structured logger with levels, log each failure once at the boundary with the request ID, record ID, and error, and remove debug prints.
- Verify the fix: a forced failure in each critical operation produces one structured error line with the IDs.
- Refs: CWE-778, OWASP A09:2025

### OBS-R3 No metrics, tracing, or error reporting on critical operations
- Leads: `scan.sh OBS-R3` lists metrics, tracing, and error-reporting libraries and calls. No hits means none is wired.
- Confirm: a production service has no way to see the error rate, latency, or failures of its critical operations: no metrics, no traces, and no error reporter (Sentry or similar), or the reporter is installed but never initialized.
- Not a finding if: the platform provides them (read the deploy config: a managed runtime with built-in metrics and log-based alerts); the project is a library, CLI, or prototype where this bar does not apply (say so on the Calibration line).
- Severity: High for a production service handling money or user data with no error reporting at all; Medium otherwise.
- Fix: initialize an error reporter at startup, and emit a counter and a latency histogram for each critical operation.
- Verify the fix: a forced error appears in the error reporter, and the metrics endpoint or dashboard shows the counter.
- Refs: CWE-778, OWASP A09:2025

### OBS-R4 Health check reports healthy without checking what serving needs
- Leads: `scan.sh OBS-R4` lists health, readiness, liveness, ping, and status endpoints and probe settings.
- Confirm: the only health endpoint, or the one the load balancer or orchestrator uses for readiness, returns 200 without checking the dependencies needed to serve (database, cache, queue), so traffic keeps flowing to an instance that cannot serve; or the check catches every error and still returns 200.
- Not a finding if: it is a liveness endpoint (the process is up) and a separate readiness endpoint checks the dependencies. Liveness must not check dependencies: if it does, one database outage makes the orchestrator restart every instance.
- Severity: High when it is the only signal the load balancer uses for a production service; Medium otherwise.
- Fix: keep liveness shallow, and add a readiness endpoint that checks each required dependency with a short timeout and returns 503 on failure.
- Verify the fix: with the database stopped, readiness returns 503 and liveness still returns 200.
- Refs: none

### OBS-R5 Environment-specific configuration hardcoded in code
- Leads: `scan.sh OBS-R5` lists hardcoded hosts, URLs, ports, and branches on the environment name.
- Confirm: values that differ per environment (service URLs, hosts, ports, bucket names, feature switches) are literals in code or picked by `if env == "production"` branches, so changing one needs a code change and a deploy; or one config file serves every environment with no override.
- Not a finding if: the literal is a development default that an environment variable overrides (read the loader); it is a fixed third-party endpoint that is the same in every environment.
- Severity: High when production hosts or buckets are hardcoded so test or staging runs can reach them; Medium otherwise.
- Fix: read per-environment values from environment variables or per-environment config, loaded and validated in one config module at startup.
- Verify the fix: starting the app with another environment's variables changes the value with no code change.
- Refs: CWE-1051

### OBS-R6 Schema changed by startup auto-sync or by hand, not by versioned migrations (quick)
- Leads: `scan.sh OBS-R6` lists schema-sync calls and migration tools.
- Confirm: the app creates or alters its schema at startup on the production path (`db.create_all()`, `sequelize.sync({ alter: true })` or `{ force: true }`, TypeORM `synchronize: true`, GORM `AutoMigrate`), or schema changes are applied by hand (a `schema.sql` with no migration history).
- Not a finding if: the call runs only in tests or a local development script (read where it is called); versioned migrations exist and run as a release step.
- Severity: Critical when a destructive sync can run against production data (`force: true` and `drop_all()` drop tables, and TypeORM `synchronize` drops columns removed from entities); High for other auto-sync in production; Medium for hand-applied schema changes.
- Fix: generate versioned migrations (Alembic, Prisma Migrate, Flyway, Django or Rails migrations), run them as a release step, and remove the startup sync.
- Verify the fix: a fresh database reaches the current schema by running the migrations alone, and app startup changes no schema.
- Refs: none

### OBS-R7 No reproducible build or documented way to run in production
- Leads: inventory.sh lists CI and container files; `scan.sh OBS-R7` lists start commands in Dockerfiles, Procfiles, and scripts.
- Confirm: nothing in the repo shows how production is built and started (no Dockerfile, Procfile, platform config, or documented command); CI tests one artifact while the deploy builds another; or production starts a development server (`flask run`, `npm run dev`, `manage.py runserver`).
- Not a finding if: the project is a library, CLI, or prototype with no deployment; the README points to a platform config kept outside the repo.
- Severity: High when production runs a development server or an artifact CI never tested; Medium otherwise. A development server running with debug on is SEC-R7.
- Fix: add one build and start definition (a Dockerfile or Procfile) that CI and the deploy both use, with a production server (gunicorn, uvicorn, node with `NODE_ENV=production`).
- Verify the fix: CI builds the image the deploy runs, and the start command launches the production server.
- Refs: none

## Also check
- Log levels set per environment, with debug logging off in production.
- Configuration validated at startup, failing fast on a missing or malformed setting instead of at first use.
- Alerts: errors and failed jobs reach a channel someone reads.

## Paper controls (look protective, protect nothing)
- A health endpoint that catches every exception and returns 200.
- An error reporter (Sentry or similar) in the manifest but never initialized, or initialized with an empty DSN in production.
- A structured logger configured while most modules still call `print` or `console.log`.
- A metrics endpoint exposed with no metric recorded on the critical paths.
