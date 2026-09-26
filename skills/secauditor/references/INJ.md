# INJ: Injection and Unsafe Input Handling

Weight 16. Always active.
Owns: untrusted data reaching an interpreter or a resource: SQL and NoSQL queries, OS commands, HTML output, outbound URLs (SSRF), file paths and archives, deserializers, templates and eval, redirects and headers, XML parsers, recursive merges, and second-order injection.
Not here: model output reaching a sink (LLMSEC); file upload validation (MISCFG); database roles and TLS (CRYPTO, and dbauditor for depth).
Standards: OWASP A05:2025 Injection (A03:2021), A01:2025 for SSRF (A10:2021), A08 for deserialization; CWE-89, 78, 79, 918, 22, 502, 1336, 94, 601, 113, 611, 1321.
Read first: every place request data enters (route handlers, webhook receivers, queue consumers, CLI args) and the query, shell, render, fetch, and file helpers they call.

## Cards

### INJ-R1 Request data concatenated into a SQL or NoSQL query (quick)
- Leads: `scan.sh INJ-R1` lists queries built with `+`, template literals, f-strings, `%`, `.format()`, and raw-query escape hatches.
- Confirm: a value that traces back to the request (or to stored user data) is joined into query text: string concatenation, `${}`, f-strings, `.raw()`, `.extra()`, `text(f"...")`, `$queryRawUnsafe`, `whereRaw('col=' + v)`, or a MongoDB filter built from `req.body` or `$where`.
- Not a finding if: the value is a constant or checked against an allowlist before use (typical for ORDER BY columns); values travel as bound parameters (`?`, `$1`, `:name`) passed separately.
- Severity: Critical when reachable by any user or anonymously; High when only an admin can reach it.
- Fix: bound parameters for values; an allowlist for identifiers that cannot be bound (table, column, sort direction); for MongoDB, cast inputs to expected types and reject objects where scalars are expected.
- Verify the fix: a test that sends `' OR '1'='1` returns the same rows as a normal term, and grep shows no string-built query at this call site.
- Refs: CWE-89, CWE-943, OWASP A05:2025

### INJ-R2 Request data reaches a shell or process call (quick)
- Leads: `scan.sh INJ-R2` lists `exec`, `system`, `popen`, `shell=True`, `child_process`, and `Runtime.exec` calls.
- Confirm: a request-derived value is interpolated into a command string, or passed as an argument that the program treats as an option (argument injection, for example a value starting with `-`).
- Not a finding if: the command is an argv array with the shell disabled and the value is validated or placed after `--`; the value comes only from trusted configuration.
- Severity: Critical (remote command execution).
- Fix: call the program with an argv array and no shell (`execFile`, `subprocess.run([...])`), validate values against an allowlist, and put `--` before user values.
- Verify the fix: a test with the value `x; id` runs no second command and the call site uses an argv array.
- Refs: CWE-78, CWE-88, OWASP A05:2025

### INJ-R3 Request or stored data rendered as HTML without escaping (quick)
- Leads: `scan.sh INJ-R3` lists `dangerouslySetInnerHTML`, `v-html`, `[innerHTML]`, `|safe`, `mark_safe`, `Html.Raw`, triple-stash, `innerHTML`, and `document.write`.
- Confirm: user-controlled text (from the request, the database, or `location`, `postMessage`, or `document.referrer`) reaches one of these sinks, or is placed into a script, attribute, or URL context with the wrong encoding.
- Not a finding if: the value passes through a sanitizer such as DOMPurify on the same path (read it); the value is a developer-controlled constant.
- Severity: Critical when stored and shown to other users or admins while session tokens are readable by script; otherwise High.
- Fix: keep the framework's auto-escaping; sanitize the rare HTML that must render with an allowlist sanitizer; add a CSP as defense in depth.
- Verify the fix: a test that stores `<img src=x onerror=alert(1)>` renders it as text.
- Refs: CWE-79, OWASP A05:2025

### INJ-R4 Server fetches a URL the client controls (SSRF) (quick)
- Leads: `scan.sh INJ-R4` lists `fetch`, `axios`, `requests.get`, `urlopen`, `http.Get`, and webhook or image-from-URL helpers fed from request data.
- Confirm: a URL or host from the request (or a stored webhook target) is fetched by the server with no allowlist of destinations, or the check happens before a redirect is followed.
- Not a finding if: the destination is checked against an allowlist of hosts after DNS resolution and after every redirect; the fetch runs in an isolated egress proxy (cite its config).
- Severity: Critical when the response is returned to the caller or the server can reach cloud metadata (169.254.169.254) or internal services; otherwise High.
- Fix: allowlist destination hosts, resolve and re-check the IP (block private, loopback, and link-local ranges), disable or re-check redirects, and never return raw responses.
- Verify the fix: a request with `url=http://169.254.169.254/` is rejected before any network call.
- Refs: CWE-918, OWASP A01:2025, API7:2023

### INJ-R5 File path built from request data without containment (quick)
- Leads: `scan.sh INJ-R5` lists `path.join`, `os.path.join`, `open`, `readFile`, `sendFile`, and archive extraction fed from request data.
- Confirm: a filename or path from the request is joined to a base directory and used to read, write, or serve a file with no canonicalize-then-check-prefix step; or an archive is extracted without checking each entry stays inside the target (Zip Slip).
- Not a finding if: the code resolves the real path and verifies it starts with the base directory; the framework call confines paths (for example Express `sendFile` with a `root` option); names are mapped through an ID lookup.
- Severity: Critical when it can write files or read secrets, keys, or source; otherwise High.
- Fix: resolve the path (`realpath`, `path.resolve`), reject it unless it stays under the base directory, or look files up by ID.
- Verify the fix: a request for `../../etc/passwd` (and its URL-encoded form) returns 400 or 404.
- Refs: CWE-22, CWE-23, OWASP A01:2025

### INJ-R6 Untrusted bytes passed to a native deserializer (quick)
- Leads: `scan.sh INJ-R6` lists `pickle.loads`, `yaml.load`, `readObject`, `unserialize`, `Marshal.load`, `BinaryFormatter`, and polymorphic JSON typing.
- Confirm: data from a request, cookie, queue, cache, or uploaded file reaches one of these deserializers.
- Not a finding if: the loader is the safe variant (`yaml.safe_load`, JSON with a schema) or the bytes are signed and verified first with a server-held key.
- Severity: Critical (remote code execution).
- Fix: use a data-only format (JSON) validated against a schema; never deserialize native objects from untrusted input.
- Verify the fix: the call site uses a data-only parser and a test with a crafted payload raises a validation error.
- Refs: CWE-502, OWASP A08:2025

### INJ-R7 Template or code built from input (template injection, eval) (quick)
- Leads: `scan.sh INJ-R7` lists `eval`, `new Function`, `exec(`, `render_template_string`, `Template(`, string `setTimeout`, and `vm.run`.
- Confirm: request-derived text is compiled as a template or evaluated as code (SSTI, eval, expression languages such as SpEL, OGNL, or EL).
- Not a finding if: only developer-authored templates are compiled and user values are passed as data to them.
- Severity: Critical (code execution or data access).
- Fix: pass user values as template variables; remove eval; use a sandboxed, logic-less template engine where users author templates.
- Verify the fix: input `{{7*7}}` renders as the literal text.
- Refs: CWE-1336, CWE-94, OWASP A05:2025

### INJ-R8 Redirect target or header value taken from the request
- Leads: `scan.sh INJ-R8` lists `redirect(` and header setters fed from request parameters such as `next`, `returnTo`, or `url`.
- Confirm: a redirect goes to a URL from the request with no same-origin or allowlist check (open redirect), or a request value containing CR or LF is written into a header.
- Not a finding if: only relative paths are accepted, or the target is matched against an allowlist; the framework rejects CR and LF in headers (most current ones do; check the version).
- Severity: Medium; High when it carries OAuth codes or tokens to the attacker.
- Fix: accept only relative paths or allowlisted hosts; strip CR and LF.
- Verify the fix: `?next=https://evil.example` redirects to the default page.
- Refs: CWE-601, CWE-113, OWASP A01:2025

## Also check
- XML parsers with DTDs or external entities enabled (XXE, CWE-611), including SOAP, SVG, and SAML paths that use a different parser than the hardened one. File under INJ.
- Recursive merge or set helpers that copy `__proto__` or `constructor` from input (prototype pollution, CWE-1321).
- LDAP and XPath queries built from input.
- Log lines that write raw input containing CR or LF (log forging, CWE-117); secrets in logs belong to SECRET.
- Second-order injection: data stored safely, then concatenated into a query, command, or template later. "It came from the database" is not a trust boundary.

## Paper controls (look protective, protect nothing)
- A `sanitizeInput()` or `escapeSql()` helper that is defined but never called on the path to the sink.
- A parameterized API defeated by building the string first and passing it as the query.
- An SSRF "allowlist" that is really a short blocklist of `localhost` and `127.0.0.1` (bypassed by `[::1]`, decimal IPs, DNS rebinding, and redirects).
- Auto-escaping enabled globally while the real output paths use `|safe` or `dangerouslySetInnerHTML`.
- XML hardening on one parser while another code path uses defaults.
- Client-side validation presented as the control.
