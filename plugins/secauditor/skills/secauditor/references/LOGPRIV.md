# LOGPRIV: Logging, Monitoring and Data Privacy

Weight 4. Always active; the privacy cards apply when the code handles personal, health, or payment data.
Owns: security event logging and audit trails, personal data in logs, log integrity and durability, alerting, and privacy controls in code (minimization, retention and deletion, consent, access auditing of regulated records).
Not here: secrets in logs (SECRET-R5); stack traces sent to clients (MISCFG-R3); encryption of stored data (CRYPTO-R6).
Standards: OWASP A09:2025 (A09:2021), CWE-778, 117, 223, 359; GDPR, PCI DSS v4.0.1 Requirement 10, HIPAA 164.312(b), SOC 2 (pick the regime from the data).
Read first: the logger setup and its formatters, the auth and admin handlers, and where personal, health, or payment data is stored and deleted.

## Cards

### LOGPRIV-R1 Security events are not logged
- Leads: `scan.sh LOGPRIV-R1` lists logger calls in auth, admin, and permission-denied branches.
- Confirm: failed and successful logins, password resets, MFA events, token issuance, access denials (the 403 branch), and high-value actions (payments, role changes, exports, deletions) leave no log or audit record with actor, action, target, time, and outcome.
- Not a finding if: an audit middleware or ORM hook records these events (read where it is mounted).
- Severity: Medium; High for systems holding money or regulated data, where you cannot investigate an incident without them.
- Fix: log security events through one audit helper with actor, action, target, UTC timestamp, outcome, and request ID.
- Verify the fix: a failed login and a 403 each produce one audit line in a test.
- Refs: CWE-778, OWASP A09:2025

### LOGPRIV-R2 Personal or payment data written to logs
- Leads: `scan.sh LOGPRIV-R2` lists logging of user objects, request bodies, emails, card numbers, and health fields.
- Confirm: logs receive whole user or request objects, full card numbers, national IDs, health data, or other personal data beyond an ID.
- Not a finding if: a redaction layer covers that logger and path (read it), or only opaque IDs are logged.
- Severity: High for payment or health data (PCI requires masking to first six and last four at most); Medium otherwise.
- Fix: log IDs instead of objects and mask sensitive fields at the logger.
- Verify the fix: a test log line for a checkout contains no full card number or email.
- Refs: CWE-532, CWE-359, PCI DSS 3.4 and 10

### LOGPRIV-R3 Log lines can be forged or lack correlation
- Leads: `scan.sh LOGPRIV-R3` lists string-built log messages that include request data.
- Confirm: user input is written into logs without neutralizing CR and LF (forged entries), records have no request or correlation ID, or security events log at a level production drops.
- Not a finding if: a structured logger escapes values and adds a request ID automatically.
- Severity: Low to Medium.
- Fix: use structured logging with escaped fields and a request ID on every record.
- Verify the fix: a username containing a newline produces one log record.
- Refs: CWE-117, CWE-223

### LOGPRIV-R4 No alerting on attacks, or logs the app can rewrite
- Leads: read the monitoring and alerting config and the log shipping setup.
- Confirm: nothing alerts on repeated auth failures, privilege changes, or error spikes, alerts go to an unmonitored channel, or logs stay only where the application account can delete or edit them.
- Not a finding if: the repo shows alert rules and an append-only or separate log sink.
- Severity: Medium; High for regulated systems.
- Fix: ship logs to a separate append-only sink and alert on auth-failure bursts, privilege changes, and error spikes.
- Verify the fix: the alert rules exist in config and target a monitored channel.
- Refs: OWASP A09:2025, CWE-778

### LOGPRIV-R5 Regulated personal data has no minimization, retention, or deletion path
- Leads: `scan.sh LOGPRIV-R5` lists `SELECT *` on user tables, deletion and export handlers, and retention jobs.
- Confirm: applies only when personal, health, or payment data is present. Queries return sensitive fields a feature does not use; there is no retention job or TTL; deletion (right to erasure) only soft-deletes and leaves copies in logs, caches, search indexes, or backups; consent is shown but the backend never checks it before processing or tracking; or reads of regulated records are not audited.
- Not a finding if: the code implements the control (cite it) or the data is not regulated.
- Severity: High for health or payment data and for erasure that does not erase; Medium otherwise.
- Fix: select only needed fields, add a retention job, make erasure reach every copy, check consent server-side, and audit reads of regulated records.
- Verify the fix: a deletion test finds no copy of the user in the tables, caches, and indexes the code writes to.
- Refs: CWE-359, GDPR Articles 5 and 17, HIPAA 164.312(b), PCI DSS 10

## Also check
- Clocks and timestamps in UTC across services.
- Third-party data sharing (analytics, support tools) bounded to what the feature needs.
- A data-subject access or export path when GDPR applies.

## Paper controls (look protective, protect nothing)
- A logger configured but never called in the failed-auth or 403 branches.
- A `redact()` or `maskPII()` wired into one formatter while most log statements bypass it.
- A documented retention policy with no job or TTL that deletes anything.
- A right-to-erasure endpoint that only soft-deletes.
- A consent banner the backend ignores.
- Alerts routed to a dead or muted channel, or "centralized" logs the app can still delete.
