# codeauditor

Audit the codebase in the current working directory end to end, then do two things:

1. **Write a report** named `codeaudit.md` at the root of that codebase.
2. **Display the results in this chat**: the overall score, the scorecard, and the top fixes (see "Report in chat" below). Do not finish silently.

This is **read-only analysis**. Do not modify any source file. The only file you create is `codeaudit.md`. If an optional path or scope was provided as an argument, audit that subtree; otherwise audit the whole codebase rooted at the working directory.

The report is written for a reader who has **no memory of the audit**, typically an AI agent that will open `codeaudit.md` later and decide, on its own, what to fix. Every finding must therefore stand alone: cite exact locations (`path/to/file.ext:line`), carry its own context, and say how to verify the fix. If a finding cannot be acted on by someone who only has the report and the code, it is not finished.

---

## Operating principles (non-negotiable)

These govern the whole audit. A report that violates any of them is not done.

1. **Evidence over assertion.** No claim without a concrete, checkable reference (`file:line`). Apply the substitution test to every sentence about the code: if you could swap in a different project and it would read equally true, it is filler. Cut it or make it specific. "Error handling is weak" fails. "`api/users.ts:88` returns HTTP 200 on a validation failure, so callers cannot detect bad input" passes.
2. **Verify against reality.** Read the code, not the comments, names, or docs. Names lie, comments rot, READMEs drift. When a doc, config, or comment claims one thing and the code does another, that gap is itself a finding.
3. **Refuse theater. Hunt for paper constructs.** The most dangerous defects look robust but carry no weight: a try/catch that swallows the error, a validator defined but never called, middleware registered but not applied to the routes it should guard, a test that asserts nothing, a health check that returns 200 without checking a dependency, a rate limiter that does not limit. Flag anything that exists for appearance but does not do its job.
4. **Find the root, not the leaves.** If the same mistake appears in twelve places, that is one systemic finding ("there is no input-validation layer"), not twelve. Cluster instances into a class-level finding so the reader fixes the cause once.
5. **Verify adversarially.** For every candidate finding, try to refute it before keeping it. Is there a guard elsewhere? A test that covers it? Is it deliberate? Assign a confidence level. When you cannot confirm by reading, mark it Suspected so the acting agent re-checks before changing anything.
6. **Calibrate to the project.** Grade against the project's evident ambition and maturity, not an absolute ideal. A weekend script is not held to the operability bar of a payment platform. State your calibration.
7. **Be honest about scope.** Say what you examined and what you did not. If you sampled instead of reading exhaustively, say so. Never imply completeness you did not achieve.
8. **Score with reasons, not vibes.** Every dimension score is justified against its findings. No number appears without the evidence that produced it.
9. **Name the strengths.** Record what the codebase does well, with evidence, so the acting agent preserves those patterns instead of refactoring them away while fixing something else.
10. **Recommendations are specific and actionable.** Banned: "improve error handling," "add more tests," "refactor for clarity." Required: what to change, where, and how to confirm it worked.

---

## Method

Run these phases in order. Use search to find candidates, then **read the cited code to confirm** before recording anything. A search hit is a lead, not a finding.

### Phase 0 - Orient
- Detect languages, frameworks, runtimes, build system, and package manager from manifests (for example `package.json`, `pyproject.toml`, `go.mod`, `Cargo.toml`, `pom.xml`, `Gemfile`).
- Measure size (file count, rough lines of code) and use it to decide exhaustive vs. sampled reading. Declare which in the report.
- Locate entry points: main, server bootstrap, route definitions, CLI handlers, scheduled jobs, message consumers.
- Read the README and docs to learn the project's intended behavior and evident maturity (prototype, internal tool, production service, public library). You will check code against these claims and calibrate scoring to this maturity.
- Identify what to exclude: vendored dependencies, generated code, build output, large fixtures. Record exclusions.
- If version control is present, record the current commit or branch.
- If the target is not actually a codebase (empty directory, documents only), say so plainly in chat and stop. Do not invent findings.

### Phase 1 - Map
- Trace two or three primary flows end to end (for example an inbound request from entry point through business logic to the data store and back, or a CLI invocation from argument parsing to side effect). Note every layer crossed.
- Build a mental model: modules and responsibilities, boundaries, the direction dependencies point, where state and config live, external integrations.
- Identify load-bearing code (touched by many flows, or guarding security and data integrity) vs. periphery. Spend effort proportional to blast radius.
- Note where the actual structure contradicts the architecture the docs or names imply.

### Phase 2 - Analyze across every lens
For each candidate issue capture three things: the location (`file:line`), what the code does now, and why that is a problem. Do not score yet.

**Security**
- Authentication: how are identities established? session or token handling, expiry, rotation, fixation, secure and http-only cookie flags, constant-time credential comparison.
- Authorization: is every sensitive operation access-checked on the server? Look for missing object-level checks (a user fetching another user's record by id). Are checks centralized or scattered and easy to forget?
- Injection: trace untrusted input into SQL and other queries (SQL injection), shell or process calls (command injection), file paths (traversal), rendered HTML (XSS), template engines (template injection), deserializers, and outbound URLs (SSRF).
- Secrets: hardcoded keys, passwords, or tokens in source or committed config; secrets in logs; committed env files.
- Cryptography: home-rolled crypto, weak modes (ECB), static or reused IVs, fast or unsalted hashes for passwords, missing constant-time comparison.
- Exposure: debug endpoints reachable in production, default credentials, verbose errors leaking internals, permissive CORS, open redirects.
- Declared vs. enforced (paper trust boundary): a security middleware defined but not applied to the routes it should guard; a validator that exists but is never called; an auth check missing from one handler in a set. These are the highest-value findings because the code reads as protected but is not.
- AI or LLM features: prompt-injection surfaces, unbounded or unguarded tool calls, code that trusts model output as if validated.

**Architecture and Design**
- Boundaries and layering: are there clear layers, and do dependencies flow in one sensible direction (no presentation layer reaching straight into the database)?
- Coupling: modules that know too much about each other's internals; circular dependencies; one logical change forcing edits across many files.
- Cohesion: god files, classes, or functions doing many unrelated things.
- Separation of concerns: business logic tangled with transport, persistence, or I/O.
- Consistency: are similar features built the same way, or does each reinvent the wheel?
- Abstraction fit: over-engineering (indirection for a problem that does not have it) and under-abstraction (the same logic copy-pasted instead of shared).
- Drift: does the real structure match the documented or intended architecture?

**Code Quality and Maintainability**
- Complexity hotspots: deeply nested conditionals, long parameter lists, high branching.
- Size: functions and files too long to hold in your head, doing more than one thing.
- Duplication: copy-pasted blocks and near-duplicate logic that should be shared.
- Naming: misleading or vague names; names that contradict what the code does.
- Dead code: unreachable branches, unused exports, commented-out blocks.
- Magic values: unexplained numbers and strings that should be named constants.
- Consistency: mixed styles and idioms that raise the cost of every edit.
- Markers: count TODO, FIXME, HACK, XXX. Tracked anywhere, or accumulating silently?
- Type safety where the language supports it: escape hatches like untyped `any`, unchecked casts, disabled checks.

**Testing and Verification**
- Coverage of what matters: are the critical paths (authentication, authorization, payments, data mutations, anything irreversible) actually tested?
- Test quality, not count: do tests assert meaningful outcomes, or merely execute code? Look for tests with no assertions, `assert true`, snapshot-only tests never reviewed, and over-mocked tests that end up testing the mock.
- Test types present (unit, integration, end to end) and the gaps.
- Determinism: tests depending on real time, randomness, network, or ordering are flaky by construction.
- Are tests run automatically, or do they exist but never run?
- Edge and error cases, not just the happy path.
- Drift: a coverage badge or claim that does not match the actual tests.

**Error Handling and Resilience**
- Swallowed errors: empty catch blocks, catch-log-and-continue where continuing is wrong, ignored error return values.
- Lost context: errors rethrown without their cause, or collapsed into generic messages.
- I/O safety: missing timeouts and retries on network and disk calls; retries with no backoff (retry storms).
- Transactional integrity: multi-step operations that can partially complete with no rollback, leaving inconsistent state.
- Resource cleanup: files, connections, locks, or threads leaked on error paths.
- Failure visibility: do failures surface where someone can act on them, or vanish silently?

**Performance and Efficiency**
- Algorithmic complexity on hot paths: nested loops over large inputs, quadratic work where linear would do.
- Data access: N+1 query patterns, queries inside loops, query shapes implying a missing index, loading whole tables without pagination.
- Caching: absent where obviously beneficial, or present with invalidation bugs.
- Blocking work: synchronous I/O on a request or hot path; long CPU work blocking an event loop.
- Memory: large allocations, unbounded growth, leaks.
- Network: over-fetching, chatty call patterns, oversized payloads.
- Without a profiler you are reasoning from the code. Mark performance findings Suspected unless the code evidence is unambiguous, and say what would confirm them.

**Dependencies and Supply Chain**
- Known-vulnerable versions: reason from package and version against your knowledge of advisories; where uncertain, mark Suspected and recommend the ecosystem's audit tool.
- Staleness: dependencies several majors behind, or abandoned and unmaintained.
- Deprecated APIs in active use.
- Bloat: unused dependencies, and multiple packages doing the same job.
- Pinning: a committed lockfile? versions pinned or floating in a way that breaks reproducible builds?
- Licensing red flags for how the project is distributed.
- Surface area: a small utility dragging in a large transitive tree.

**Documentation and Drift**
- README accuracy: do setup, build, and run instructions match the scripts and config? Follow them on paper.
- API and interface docs: pick several documented endpoints, flags, or env vars and verify each exists and behaves as documented.
- Missing or phantom docs: features that exist but are undocumented, and documented features that do not exist.
- Inline docs where the code is genuinely non-obvious; stale comments that now contradict the code.
- Onboarding: could a new contributor get the project running from the docs alone?

**Observability and Operability**
- Logging: present at the right boundaries? structured or just printf? leaking secrets or PII? signal or noise?
- Metrics and tracing for critical operations, or blind in production?
- Health and readiness checks: do they verify real dependencies, or return 200 unconditionally (a paper health check)?
- Configuration: separated from code? secrets from the environment or a secret store rather than the repo? per-environment config?
- Deployability: reproducible build, documented run, a sane story for schema or data migrations.
- Calibrate: scale these expectations to the project's maturity.

### Phase 3 - Verify adversarially and cluster
- For each candidate, try to refute it. Is there a guard, check, or test elsewhere that neutralizes it? Is it an intentional, documented trade-off? Adjust or drop.
- Assign Severity, Confidence, and Effort (definitions below).
- Default to caution: if you could not confirm by reading the code, mark it Suspected.
- Cluster repeated instances of one underlying problem into a single systemic pattern, keeping the instance IDs as members.

### Phase 4 - Score
Score each dimension 0-100. The overall score is the weighted average. These weights are defaults; re-weight only when the project type warrants it, and state the change and reason.

| Dimension | Weight |
|---|---|
| Security | 20% |
| Architecture and Design | 15% |
| Code Quality and Maintainability | 15% |
| Testing and Verification | 15% |
| Error Handling and Resilience | 10% |
| Performance and Efficiency | 8% |
| Dependencies and Supply Chain | 7% |
| Documentation and Drift | 5% |
| Observability and Operability | 5% |

Score bands (per dimension and overall): 90-100 = A (exemplary), 80-89 = B (solid, minor issues), 70-79 = C (adequate, real gaps), 60-69 = D (weak, systemic problems), 0-59 = F (failing, critical deficiencies).

Risk does not average away: a single Critical finding caps its dimension at 69 and caps the overall at 79 until resolved. Justify every dimension score against its specific findings. No number without a reason.

### Phase 5 - Prioritize
Definitions:
- **Severity** - Critical (exploitable vulnerability, data loss or corruption risk, or guaranteed production failure; act immediately) / High (serious defect or weakness likely to cause an incident or major drag; act this cycle) / Medium (a real problem degrading quality, correctness in edge cases, or velocity; schedule it) / Low (minor or cosmetic; batch it).
- **Confidence** - Confirmed (verified by reading the code; reasoning reproducible from the cited evidence) / Likely (strong evidence resting on a stated runtime or config assumption) / Suspected (inferred without confirmation; verify before acting).
- **Effort** - S (localized, under ~1 hour) / M (a few files, ~half a day) / L (cross-cutting or needs design, multiple days).

Bucket every finding: **Quick wins** (High/Critical, Confirmed, S), **Plan now** (High/Critical, M or L), **Verify first** (any Suspected), **Backlog** (Low). Order the "What to fix first" list as the union of Quick wins and Plan now, Critical before High, breaking ties toward findings that also close a systemic pattern.

### Phase 6 - Write codeaudit.md
Write to `<codebase-root>/codeaudit.md` with these sections in order. Keep finding IDs stable using a dimension prefix and number: SEC, ARC, QUAL, TEST, ERR, PERF, DEP, DOC, OBS (for example `SEC-001`).

1. **Title and banner** - project name; a line stating this is a read-only audit, the date, and that the report is self-contained.
2. **Snapshot** - project, state (commit or branch), languages, size, frameworks, entry points, evident maturity, audit coverage (exhaustive or sampled, with what was sampled), exclusions.
3. **Overall score** - `NN/100 - Grade X (label)`, a two-to-four sentence specific health verdict, and a one-line calibration note. Then a scorecard table: Dimension, Score, Grade, Weight, one-line specific verdict; final row is the weighted overall. A re-weighting note (default or the change and why).
4. **What to fix first** - the ordered priority list. Each line: `[ID] title - severity, effort - one-line why`.
5. **Strengths (preserve these)** - what the codebase does well, each with evidence. The acting agent must not refactor these away.
6. **Systemic patterns (root causes)** - one entry per recurring root cause: what it is, the member finding IDs, and the one root fix.
7. **Findings** - sorted by severity then dimension. Each finding is a self-contained block in this exact shape:

   ```
   ### [SEC-001] <title>
   - Severity: <Critical/High/Medium/Low> | Confidence: <Confirmed/Likely/Suspected> | Effort: <S/M/L> | Dimension: <name>
   - Location: `file:line` (and other locations)
   - Evidence: <what the code does now, precisely>
   - Impact: <the concrete consequence; why it matters>
   - Recommendation: <specific change and where; not a platitude>
   - Verify the fix: <a test to add, behavior to check, or command to run>
   - Related: <systemic pattern or finding IDs, or "none">
   ```

8. **Dimension notes** - one short subsection per dimension tying the score to its findings.
9. **Remediation plan** - the four buckets (Quick wins, Plan now, Verify first, Backlog) listed by ID, with Plan now in suggested order.
10. **Scope and limitations** - what was and was not examined, sampling decisions, and assumptions that would change conclusions if untrue.
11. **How to use this report (for the acting agent)** - include this protocol verbatim:
    1. Triage by severity and confidence. Confirmed Critical and High are safe to act on now, in the order in "What to fix first". Re-verify any Suspected finding against the cited code before changing anything.
    2. Fix root causes first; prefer systemic patterns over individual leaves.
    3. Preserve the strengths; do not refactor them away while fixing other issues.
    4. Confirm the stated assumption on Likely findings before acting.
    5. One finding, one change, verified: after each fix run its "Verify the fix" step; keep changes atomic and traceable to the finding ID.
    6. Do not widen scope silently; note adjacent issues rather than sprawling into a rewrite.
    7. Re-run the audit to measure progress; confirm findings are resolved, not relocated, and watch for regressions in the strengths.

### Phase 7 - Report in chat
After the file is written, print a concise summary to the chat so the user sees the result without opening the file. Include, in this order:
- One headline line: `Code audit complete: NN/100 (Grade X)` followed by the one-line health verdict.
- The scorecard table (all nine dimensions plus the weighted overall).
- "What to fix first": the top three to five items, each `[ID] title - severity, effort`.
- Counts: number of findings by severity (for example `Critical 2, High 5, Medium 8, Low 6`).
- The path to the full report: `Full report: ./codeaudit.md`.
Keep it tight. The file holds the detail; the chat holds the verdict and the next actions.

---

## Quality gates (self-check before declaring done)

- Every finding cites at least one `file:line`. Run the substitution test on each title and impact line; rewrite anything that would read true for a different repo.
- Every dimension score has a justification tied to specific findings.
- Every finding has Severity, Confidence, and Effort set.
- Every recommendation says what to change and how to verify it. No platitudes.
- Repeated issues are clustered into systemic patterns; there are not many near-identical findings left loose.
- Suspected findings are clearly marked.
- Strengths section is present and evidence-backed.
- Scope and limitations are stated honestly.
- The "How to use this report" protocol is present.
- The report is at the codebase root, named exactly `codeaudit.md`, no source files were changed, and the chat summary was printed.

## Notes
- Read-only. Use search and read tools to investigate, and shell commands only for inspection (manifests, line counts, version control state). Do not edit source, run migrations, or execute the project's own code as part of the audit.
- Scale effort to blast radius: spend the most time on the code the most flows depend on.
- For a large codebase, sample deliberately (entry points, hot paths, security-sensitive code, representative modules) and declare exactly what you sampled.
