# Code audit: tinyledger

> Read-only code audit of the code as written, 2026-09-26. The project's code, tests, and builds were not run. Mode: full. Scope: whole project.
> Self-contained: every finding cites the file and line it is about, so an agent holding only this report and the code can act on it. Written with codeauditor (auditor-suite 1.1.0).

## Snapshot

- Project: tinyledger (commit 3f9c2a1 on main)
- Stack: JavaScript on Node.js 22, Express 4, better-sqlite3 (SQLite), the built-in `node:test` runner.
- Size and coverage: 3 source files, about 115 lines, plus the README, the manifest, and one CI workflow; read exhaustively.
- Maturity and exposure: a personal tool for one household, bound to 127.0.0.1 with no login (README); it holds real balances, so integrity matters more than scale.
- Active dimensions: SEC, ARC, QUAL, TEST, ERR, PERF, DEP, DOC, OBS
- Not applicable: none
- Not assessed: none
- Excluded: none

## Map

Two modules; dependencies point one way. `src/server.js` holds three Express routes and one error middleware (`src/server.js:26`). `src/ledger.js` opens the SQLite file, applies versioned migrations (`src/ledger.js:17`), and implements the three operations. State lives only in the SQLite file named by `LEDGER_DB` (`src/server.js:4`); there is no external integration. The load-bearing code is `transfer()`.

- Transfer: `POST /transfers` (`src/server.js:12`) checks `cents` (`src/server.js:14`) and calls `ledger.transfer` (`src/server.js:17`), which runs two UPDATEs (`src/ledger.js:34-35`).
- Import: `POST /import` (`src/server.js:21`) passes the lines to `importEntries`, which inserts them one at a time (`src/ledger.js:42`).
- Startup: `openDb` applies pending migrations in one transaction (`src/ledger.js:20`), then the server binds 127.0.0.1:3000 (`src/server.js:31`).

## Overall score

<!-- BEGIN GENERATED: score (score.sh --write fills this block; do not edit it by hand) -->
**Overall: 79/100, Grade C (adequate, real gaps)**

| Dimension | Score | Grade | Weight | Critical | High | Medium | Low | Suspected |
|---|---:|---|---:|---:|---:|---:|---:|---:|
| SEC Security | 100 | A | 20.0% | 0 | 0 | 0 | 0 | 0 |
| ARC Architecture and Design | 100 | A | 15.0% | 0 | 0 | 0 | 0 | 0 |
| QUAL Code Quality and Maintainability | 100 | A | 15.0% | 0 | 0 | 0 | 0 | 0 |
| TEST Testing and Verification | 100 | A | 15.0% | 0 | 0 | 0 | 0 | 0 |
| ERR Error Handling and Resilience | 65 | D | 10.0% | 1 | 1 | 0 | 0 | 0 |
| PERF Performance and Efficiency | 98 | A | 8.0% | 0 | 0 | 0 | 0 | 1 |
| DEP Dependencies and Supply Chain | 97 | A | 7.0% | 0 | 0 | 1 | 0 | 0 |
| DOC Documentation and Drift | 100 | A | 5.0% | 0 | 0 | 0 | 0 | 0 |
| OBS Observability and Operability | 100 | A | 5.0% | 0 | 0 | 0 | 0 | 0 |
| **Overall** | **79** | **C** | 100% | 1 | 1 | 1 | 0 | 1 |

Caps applied: overall held at 79 (one Critical finding).
Findings: Critical 1, High 1, Medium 1, Low 0 (Suspected, not yet confirmed: 1).
Computed by score.sh from the findings below (rules: references/protocol.md, Scoring).
<!-- END GENERATED: score -->

Verdict: tinyledger is small and mostly careful: bound values everywhere, a schema that refuses negative balances, versioned migrations, and tests that assert real balances. Its serious gap is atomicity: `transfer()` loses or invents money when an account ID is wrong, and the async handlers hang or stop the server on any ledger error. Both top fixes take minutes.

Calibration: a single-user localhost tool, graded hard on data integrity because it holds real balances, and lightly on operations and scale.

## What to fix first

<!-- BEGIN GENERATED: fix-first (score.sh --write) -->
1. [ERR-001] transfer() debits and credits in two unchecked statements with no transaction - Critical, effort S. Money can vanish or appear from nowhere.
2. [ERR-002] Async route handlers never reach the error middleware under Express 4 - High, effort S. One bad request can stop the server.
<!-- END GENERATED: fix-first -->

## Strengths (preserve these)

- The schema guards the data: `CHECK (cents >= 0)` (`src/ledger.js:7`), a foreign key from entries to accounts (`src/ledger.js:11`), and foreign keys switched on (`src/ledger.js:19`).
- Versioned migrations run in one transaction (`src/ledger.js:20-24`), and every statement binds its values with `?` (`src/ledger.js:39`).
- Imports are idempotent (`INSERT OR IGNORE` on the unique `bank_ref`), and a test proves it (`test/ledger.test.js:31-36`).
- `POST /transfers` rejects non-integer and non-positive amounts first (`src/server.js:14`).

## Systemic patterns (root causes)

- SYS-1: `src/ledger.js` runs every data write in SQLite autocommit mode; only `openDb` uses `db.transaction()`. Members: ERR-001, PERF-001. Root fix: wrap each write function in `db.transaction()`, as `openDb` already does for migrations.

## Findings

### [ERR-001] transfer() debits and credits in two unchecked statements with no transaction
- Severity: Critical | Confidence: Confirmed | Effort: S | Dimension: ERR
- Location: `src/ledger.js:33-36`
- Evidence: `transfer()` runs `UPDATE accounts SET cents = cents - ? WHERE id = ?` and then the matching credit as two autocommit statements and never checks `.changes`; `from` and `to` arrive unchecked from the request body (`src/server.js:17`).
- Impact: Money can vanish or appear from nowhere. A transfer to an account ID that does not exist debits the sender and credits nobody; a `from` ID that does not exist credits money never debited. Nothing records why the balances stop adding up.
- Recommendation: run both statements inside `db.transaction()` in `transfer()`, and throw inside it unless each `run()` reports `changes === 1`, so a bad ID rolls the whole transfer back.
- Verify the fix: a test that transfers 100 cents from alice to account 999 expects an error and both balances unchanged.
- References: CWE-755, OWASP A10:2025
- Related: SYS-1

### [ERR-002] Async route handlers never reach the error middleware under Express 4
- Severity: High | Confidence: Confirmed | Effort: S | Dimension: ERR
- Location: `src/server.js:12` (also `src/server.js:21`)
- Evidence: both handlers are `async (req, res) => {` with no try/catch, and `package.json:16` asks for Express 4, which ignores the promise a handler returns, so ledger errors never reach the middleware at `src/server.js:26`.
- Impact: One bad request can stop the server. An overdraft (the `CHECK (cents >= 0)` constraint throws) or an import line naming a missing account gets no response, and on Node.js 15 or later the unhandled rejection ends the process.
- Recommendation: remove `async` from both handlers (the ledger calls are synchronous), so thrown errors reach the error middleware.
- Verify the fix: a transfer larger than the balance gets a JSON error response, and `GET /accounts` still answers afterwards.
- References: CWE-755, OWASP A10:2025
- Related: none

### [PERF-001] importEntries() commits every imported line separately
- Severity: Medium | Confidence: Suspected | Effort: S | Dimension: PERF
- Location: `src/ledger.js:41-43`
- Evidence: the loop runs `count += insert.run(e.ref, e.accountId, e.cents, e.memo).changes` per line with no enclosing transaction, so SQLite commits and syncs each INSERT on its own.
- Impact: Large imports are slow and freeze the app. A few thousand lines cost a few thousand disk syncs, and better-sqlite3 is synchronous, so `POST /import` blocks every other request meanwhile. Suspected: export sizes and the disk are not visible.
- Recommendation: run the loop inside `db.transaction()`; the `INSERT OR IGNORE` on `bank_ref` already makes a retry safe.
- Verify the fix: time an import of 5,000 lines before and after; the transaction version should finish many times faster.
- References: CWE-1050
- Related: SYS-1

### [DEP-001] No lockfile, so every install resolves new dependency versions
- Severity: Medium | Confidence: Confirmed | Effort: S | Dimension: DEP
- Location: `package.json:14-17` (also `.github/workflows/test.yml:13`)
- Evidence: dependencies are caret ranges (`"express": "^4.21.2"`), inventory.sh found no lockfile, and CI runs `npm install`.
- Impact: Builds are not reproducible. Two installs of one commit can run different Express and better-sqlite3 versions, so a green CI run proves little about the next install.
- Recommendation: commit `package-lock.json` and change the CI step to `npm ci`.
- Verify the fix: CI passes with `npm ci`, and two clean installs print identical versions in `npm ls`.
- References: OWASP A03:2025
- Related: none

## Dimension notes

### SEC: Security
- Checked: SEC-R1, SEC-R2, SEC-R3, SEC-R4, SEC-R5, SEC-R6, SEC-R7, SEC-R8
- Note: no findings: localhost-only by design, bound values everywhere, and no secrets, crypto, debug flags, or model calls.

### ARC: Architecture and Design
- Checked: ARC-R1, ARC-R2, ARC-R3, ARC-R4, ARC-R5, ARC-R6, ARC-R7, ARC-R8
- Note: no findings: two modules with one-way dependencies; the shared database handle (`src/server.js:4`) holds no per-request data.

### QUAL: Code Quality and Maintainability
- Checked: QUAL-R1, QUAL-R2, QUAL-R3, QUAL-R4, QUAL-R5, QUAL-R6
- Note: no findings: short functions, clear names, no dead code, markers, or suppressions.

### TEST: Testing and Verification
- Checked: TEST-R1, TEST-R2, TEST-R3, TEST-R4, TEST-R5
- Note: no findings: tests assert stored state for a transfer, an overdraft, and a repeated import, and CI runs them on every push. ERR-001's Verify the fix adds the missing-account case.

### ERR: Error Handling and Resilience
- Checked: ERR-R1, ERR-R2, ERR-R3, ERR-R4, ERR-R5, ERR-R6
- Note: ERR-001 and ERR-002. The generic body at `src/server.js:28` is fine: the line before it logs the error with its stack.

### PERF: Performance and Efficiency
- Checked: PERF-R1, PERF-R2, PERF-R3, PERF-R4, PERF-R5
- Note: PERF-001. `listAccounts()` loads every account, but a household has a handful.

### DEP: Dependencies and Supply Chain
- Checked: DEP-R1, DEP-R2, DEP-R3, DEP-R4, DEP-R5, DEP-R6
- Note: DEP-001. Both packages are used, Node.js 22 is supported (references/facts.md), Express 4 is one major behind (below DEP-R2's bar), and no advisory is known for these ranges.

### DOC: Documentation and Drift
- Checked: DOC-R1, DOC-R2, DOC-R3, DOC-R4
- Note: no findings: the commands match `package.json:8-9`, `LEDGER_DB` is read at `src/server.js:4`, and the documented endpoints exist.

### OBS: Observability and Operability
- Checked: OBS-R1, OBS-R2, OBS-R3, OBS-R4, OBS-R5, OBS-R6, OBS-R7
- Note: no findings at this calibration: localhost binding by design, versioned migrations, and an error middleware that logs once ERR-002 is fixed.

## Remediation plan

<!-- BEGIN GENERATED: plan (score.sh --write) -->
- Quick wins (Critical or High, not Suspected, effort S): ERR-001, ERR-002
- Plan now (Critical or High, not Suspected, effort M or L), in this order: none
- Verify first (Suspected; confirm against the code before acting): PERF-001
- Schedule (Medium): DEP-001
- Backlog (Low): none
<!-- END GENERATED: plan -->

## Scope and limitations

Read all six files; ran nothing (not the server, `npm test`, or `npm audit`). PERF-001 needs a timed import to confirm. ERR-002's crash assumes Node.js 15 or later, which `engines` requires. If the app is ever exposed beyond 127.0.0.1, the missing login becomes a Critical SEC finding; have secauditor review it.

## How to use this report (for the acting agent)

1. Triage by severity and confidence. Confirmed Critical and High findings are safe to act on now, in the order under "What to fix first". Re-verify every Suspected finding against the cited code before changing anything.
2. Confirm the stated assumption on Likely findings before acting.
3. Fix root causes first: prefer a systemic pattern's root fix over its individual members.
4. Preserve the strengths; do not refactor them away while fixing something else.
5. Fix the root cause in the module that owns it, keep public interfaces stable unless the finding is about them, and add the test named in Verify the fix before you refactor around it.
6. One finding, one change, verified: after each fix, run its "Verify the fix" step and keep the change traceable to the finding ID.
7. Do not widen scope silently; note adjacent issues instead of sprawling into a rewrite.
8. Re-run the audit to measure progress: confirm findings are resolved, not relocated, and that the strengths did not regress.
