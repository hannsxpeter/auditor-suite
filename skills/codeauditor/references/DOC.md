# DOC: Documentation and Drift

Weight 5. Always active.
Owns: whether the docs tell the truth about the code: setup, build, and run instructions; documented endpoints, flags, and settings; features documented but missing, or present but undocumented; comments and docstrings that contradict the code; and whether a newcomer could get the project running from the docs alone.
Not here: structure that breaks a declared architecture (ARC-R1); coverage and "fully tested" claims (TEST, Also check); code too complex to read without comments (QUAL-R1); customer-facing claims in pricing, marketing, help, release notes, and in-app copy, and product requirement docs, specs, roadmaps, and decision records marked done (productauditor CLM, CLM-R8); a kill switch that is read but cannot switch (productauditor SHIP-R3); a public contract change shipped with no changelog entry or version bump (productauditor SHIP-R6).
Standards: CWE-1059, CWE-1068, CWE-1116.
Read first: README, CONTRIBUTING, docs/, `.env.example`, the manifest's scripts (package.json `scripts`, Makefile, pyproject), and any API spec (OpenAPI, GraphQL schema).

## Cards

### DOC-R1 Setup, build, or run steps that do not work as written
- Leads: `scan.sh DOC-R1` lists commands in the docs. Check each one against the manifest scripts, Makefile targets, files, and versions it names.
- Confirm: following the README on paper fails: a command names a script or target that does not exist (`npm run dev` with no `dev` script), a path or file that is missing, or a runtime version the manifest contradicts; or a required step is missing (a database to create, a migration or seed to run).
- Not a finding if: the step exists under another documented name, or the doc says it is for a platform you cannot see.
- Severity: High when the broken step is the only documented way to run, deploy, or migrate the project; Medium otherwise.
- Fix: correct the command or add the missing step, and make the README's commands the ones CI runs.
- Verify the fix: a fresh clone, followed step by step, reaches a running app and a passing test run.
- Refs: CWE-1059

### DOC-R2 Documented setting, endpoint, or flag that the code does not have or handles differently
- Leads: `scan.sh DOC-R2` lists environment variables and endpoints named in the docs; DOC-R1's leads show the documented commands and their flags. Search the code for each name.
- Confirm: a documented environment variable is never read, an endpoint or CLI flag does not exist or takes different parameters, a documented default differs from the code's default, or a documented feature is absent.
- Not a finding if: the name is read indirectly (a config library that maps a prefix such as `APP_`, or a framework that reads the variable itself; read the loader).
- Severity: High when operators rely on the setting for safety or money (a documented limit, retry count, or kill switch that does nothing); Medium otherwise.
- Fix: implement the documented behavior or remove it from the docs; generate API docs from the code where possible (OpenAPI from the routes).
- Verify the fix: a search for the documented name finds the code that reads it, and a test that sets it sees the effect.
- Refs: CWE-1068

### DOC-R3 Code needs settings, or has features, that no doc mentions
- Leads: `scan.sh DOC-R3` lists environment and config reads in the code. Compare each with the README and `.env.example`.
- Confirm: the code requires a setting (it fails or misbehaves without it) that neither the README nor `.env.example` lists, or a user-facing feature, endpoint, or command has no documentation.
- Not a finding if: the setting has a safe default and is an advanced option; internal endpoints are documented elsewhere (read docs/).
- Severity: Medium when a required setting is undocumented, so the app cannot start from the docs alone; Low for undocumented optional features.
- Fix: list every required setting in `.env.example` and the README, with its purpose and a safe example value.
- Verify the fix: the app starts with only the documented settings.
- Refs: CWE-1059

### DOC-R4 Comment or docstring that contradicts the code
- Leads: no search pattern. Check the comments and docstrings on the functions you read for other cards: stated return values, units, side effects, and guarantees.
- Confirm: a comment or docstring says something the code does not do ("returns None when missing" but it raises; "amount in dollars" but callers pass cents; "thread-safe" over unsynchronized state; "validated upstream" where nothing validates).
- Not a finding if: the comment is clearly marked as a historical note.
- Severity: Medium when callers trust the wrong statement for money, security, or data handling; Low otherwise.
- Fix: correct the comment to match the code; if the comment states the intended behavior, fix the code instead and file the finding under the code's dimension.
- Verify the fix: the comment and the code agree, and a test pins the documented behavior.
- Refs: CWE-1116

## Also check
- Onboarding: can a new contributor get from clone to a running app and a passing test run with the docs alone (prerequisites, versions, seed data)?
- A version or changelog in the docs that does not match the manifest version.
- Inline docs missing where the code is genuinely non-obvious (an unusual algorithm, a workaround for an upstream bug).
- Architecture or API docs whose examples no longer run (renamed fields, old URLs).

## Paper controls (look protective, protect nothing)
- An OpenAPI or Swagger file that is neither generated from nor validated against the routes.
- A `.env.example` that lists settings the code no longer reads while the new required ones are missing.
- A CONTRIBUTING guide that names checks (lint, format, tests) that no script or CI step runs.
