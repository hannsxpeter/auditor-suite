# QUAL: Code Quality and Maintainability

Weight 15. Always active.
Owns: the cost of reading and changing the code: long or complex functions, duplicated logic, misleading names, dead code, marker comments, type and lint escape hatches, magic values, and inconsistent style.
Not here: files or classes with many unrelated responsibilities (ARC-R3); competing designs for one concern (ARC-R6); comments that contradict the code (DOC-R4); deprecated library APIs (DEP-R3); a validator that never runs on an input path (SEC-R1).
Standards: CWE-1121, CWE-1041, CWE-561, CWE-546, CWE-1106 (CISQ maintainability weaknesses).
Read first: the load-bearing files on your Map, the largest source files (the ARC-R3 command), and the linter and type-checker config (.eslintrc, tsconfig.json, pyproject.toml, setup.cfg, .golangci.yml).

## Cards

### QUAL-R1 A function too long or too branchy to hold in your head
- Leads: `scan.sh QUAL-R1` lists long parameter lists and deeply nested branches. Also open the longest functions in the largest files.
- Confirm: a function or method runs past about 60 lines, nests conditionals or loops four or more levels deep, takes six or more parameters, or chains several unrelated steps (validation, pricing, persistence, notification), so a change to one step risks the others.
- Not a finding if: the length is a flat table, a switch over many simple cases, generated code, or a test with long fixture data.
- Severity: High when the function is load-bearing (on a flow from your Map that handles money, auth, or data writes) and has no direct test; Medium otherwise.
- Fix: extract each step into a named function with explicit inputs and outputs, and replace deep nesting with early returns.
- Verify the fix: each extracted function has a unit test, and the original reads as a short sequence of calls.
- Refs: CWE-1121, CWE-1124, CWE-1064

### QUAL-R2 Copy-pasted logic that should be one function
- Leads: no search pattern. Note near-identical blocks while you read, then search for a distinctive line from one copy to find the others.
- Confirm: the same logic (a calculation, validation, query, or formatting rule) appears in two or more places, so a fix must be made in each, and the copies may already differ.
- Not a finding if: the copies look alike but change for different reasons (test setup, two independent API versions).
- Severity: High when the copies already disagree on a business rule; Medium when they still match; Low for small helpers.
- Fix: extract one shared function in the module that owns the concept, and call it from each place.
- Verify the fix: a search for the distinctive line returns one hit, and one test covers the shared function.
- Refs: CWE-1041

### QUAL-R3 A name that says something the code does not do
- Leads: no search pattern. Check names in the load-bearing code you read, especially functions named get, is, has, check, or calculate, and values with units.
- Confirm: a name contradicts the behavior (`getUser` that also creates or writes, `isValid` that returns a string, `calculateTotal` that also sends an email, `amount` in cents in one module and dollars in another), or a load-bearing function has a name that says nothing (`handle`, `process`, `data2`, `tmp`).
- Not a finding if: the name follows a documented framework convention.
- Severity: Medium when a caller already misuses it (read the callers); Low otherwise.
- Fix: rename it to say what it does (`getOrCreateUser`, `amountCents`) and update every caller.
- Verify the fix: a search for the old name returns no hits.
- Refs: CWE-1099

### QUAL-R4 Dead code: unreachable branches, unused exports, commented-out blocks
- Leads: `scan.sh QUAL-R4` lists commented-out code and always-false branches. For unused exports, search each exported name for callers.
- Confirm: code can never run (after a return, under `if False`, behind a flag that is always off), an exported function or module has no callers, or a block of code is commented out.
- Not a finding if: the export is a library's public API; the flag is set per environment (read the config).
- Severity: Medium when dead code in a load-bearing file looks like the live path and misleads readers; Low otherwise.
- Fix: delete it; version control keeps the history.
- Verify the fix: the build, type check, and tests pass without it, and a search for its name finds no callers.
- Refs: CWE-561, CWE-1164

### QUAL-R5 TODO, FIXME, and HACK markers pile up untracked
- Leads: `scan.sh QUAL-R5` lists the markers. Count them per file and read the ones in load-bearing files.
- Confirm: markers accumulate (several in one module, or dozens across the code) with no issue link or owner, so known work and known risks live only in comments. When a marker admits a real bug ("FIXME: double-charges on retry"), confirm the bug in the code and file it under the dimension that owns it; this card owns the untracked pile.
- Not a finding if: each marker links to a tracked issue, or there are only a few and they note harmless future work.
- Severity: Medium for a cluster of untracked markers in a load-bearing module; Low otherwise.
- Fix: turn each marker into a tracked issue and replace the comment with the issue link; fix or delete the stale ones.
- Verify the fix: `scan.sh QUAL-R5` lists only markers that carry an issue link.
- Refs: CWE-546

### QUAL-R6 Type or lint checks switched off where the code needs them
- Leads: `scan.sh QUAL-R6` lists `any`, forced casts, and suppression comments (`@ts-ignore`, `eslint-disable`, `# type: ignore`, `# noqa`, `@SuppressWarnings`, `nolint`, `.unwrap()`).
- Confirm: escape hatches cluster in load-bearing code (untyped `any` on request bodies or money values, casts that assert a shape nobody checked, whole files under `@ts-nocheck` or `eslint-disable`), or the checker config turns strictness off (`"strict": false`, `ignore_errors = true`).
- Not a finding if: the suppression is narrow, has a comment explaining why, and sits behind a runtime check of the value.
- Severity: High when an unchecked cast or `any` on outside data hides a shape the code then trusts for money or permission decisions; Medium otherwise.
- Fix: type the boundary once (a schema such as zod or pydantic validates outside data), then remove the casts and suppressions behind it.
- Verify the fix: the type checker passes in strict mode on the file with the suppressions removed.
- Refs: CWE-704, CWE-1127

## Also check
- Magic numbers and strings (timeouts, limits, prices, status codes as bare literals) that should be named constants.
- Mixed styles and idioms for the same thing (callbacks next to promises, two naming schemes) that raise the cost of every edit; file under QUAL when it is style, ARC-R6 when it is two designs.

## Paper controls (look protective, protect nothing)
- A linter or formatter configured but no script or CI step runs it.
- Strict type checking enabled in config, then switched off file by file with `@ts-nocheck` or a top-level `# type: ignore`.
- A complexity or line-length rule set so high that nothing can fail it.
