# TEST: Testing and Verification

Weight 15. Always active.
Owns: whether the tests would catch a regression in what matters: coverage of critical paths, assertions that check outcomes, mocks that leave the real code under test, determinism, whether tests run automatically and can fail the build, edge and error cases, and coverage claims.
Not here: the code defects a test would catch (file each in its own dimension and name the missing test in its Verify the fix); linters in CI (QUAL); build and deploy steps (OBS-R7).
Standards: none formal; judge against the project's own CI config and the flows on your Map.
Read first: the test folders and config (inventory.sh counts test files), the CI workflows, and the critical modules on your Map: authentication, authorization, payments, data writes, and anything irreversible.

## Cards

### TEST-R1 A critical path has no test that exercises it
- Leads: no search pattern. List the critical modules from your Map, then search the test folders for their function and route names.
- Confirm: authentication, authorization, a payment, a data mutation, or an irreversible action (delete, send, charge) has no test that calls it, or only its happy path is tested while its failure branches (declined card, missing record, permission denied) have none.
- Not a finding if: an integration or end-to-end test exercises the path through another entry point (read that test).
- Severity: High for money, auth, and irreversible actions; Medium for other data writes; Low for read-only paths.
- Fix: add a test for the path and for its main failure branch that asserts the stored state and the response.
- Verify the fix: the new test fails when the path's key line is broken on purpose, then passes when it is restored.
- Refs: none

### TEST-R2 Tests that run code but assert nothing
- Leads: `scan.sh TEST-R2` lists always-true, existence-only, and commented-out assertions and snapshot-only checks. Also read every test of the critical paths from TEST-R1.
- Confirm: a test calls the code and then asserts nothing, asserts only that a value exists or is truthy (`assert result`, `toBeDefined()`), asserts `True`, has its assertions commented out, or only compares snapshots that are regenerated without review.
- Not a finding if: the test checks that no error is raised and says so explicitly (`expect(fn).not.toThrow()`, a named smoke test documented as one).
- Severity: High when the hollow tests are the only tests of a critical path, because they stay green while the path is broken; Medium otherwise.
- Fix: assert the outcome: the returned value, the stored record, the response status and body, or the call to the outside service with its arguments.
- Verify the fix: breaking the code under test on purpose makes the test fail.
- Refs: none

### TEST-R3 Tests mock the code they claim to test
- Leads: `scan.sh TEST-R3` lists mocks, patches, and stubs in test files.
- Confirm: a test replaces the unit under test (or every function it calls, including its own module's) with mocks and then asserts on the mocks, so the real logic never runs; or it asserts only that a mock was called, not what the code produced.
- Not a finding if: the mocks replace only outside boundaries (network, clock, payment provider) and the assertions check the unit's own output or stored state.
- Severity: High when this is the only test of a critical path; Medium otherwise.
- Fix: mock only the outside boundary, run the real unit, and assert its output or stored state.
- Verify the fix: breaking the unit's logic on purpose makes the test fail.
- Refs: none

### TEST-R4 Tests that depend on real time, randomness, network, or order
- Leads: `scan.sh TEST-R4` lists clock reads, sleeps, random values, and real URLs in test files.
- Confirm: a test's result depends on the wall clock (`datetime.now`, `Date.now`, midnight or month end), a sleep for timing, unseeded randomness, a real network call, or state left by another test, so it can pass or fail with no code change.
- Not a finding if: the clock and randomness are injected or frozen (freezegun, `jest.useFakeTimers`, a seeded generator) and network calls hit a local stub.
- Severity: High when flaky tests are already skipped or retried in CI to keep the build green (read the CI config); Medium otherwise.
- Fix: inject the clock and the random source, freeze time in tests, stub network calls, and reset shared state for each test.
- Verify the fix: the suite passes when run in random order and with the clock set to 23:59:59 on the last day of a month.
- Refs: none

### TEST-R5 Tests exist but never run, or cannot fail the build
- Leads: `scan.sh TEST-R5` lists test commands in CI files and skipped tests.
- Confirm: no CI workflow runs the tests; the test step has `continue-on-error: true` or `|| true`; the test command matches no files (a wrong path or pattern) and still passes; or tests on critical paths are marked skip, xit, or disabled with no linked issue.
- Not a finding if: another pipeline runs them (a Makefile target called from CI, a separate workflow; read it).
- Severity: High when no automated run exists or the step cannot fail; Medium for skipped tests.
- Fix: run the suite in CI on every push and pull request with a failing exit code, and fix or delete the skipped tests.
- Verify the fix: a pull request with a deliberately failing test shows a failed check.
- Refs: none

## Also check
- Which test types exist (unit, integration, end to end) and the obvious gaps, such as no test that touches the real database schema or crosses the HTTP boundary.
- Edge and error cases: empty input, limits, duplicates, concurrent requests, and failures of dependencies, not just the happy path.
- A coverage badge or a README claim ("fully tested", "95% coverage") that the tests do not support. It files here, not under DOC: the fix is tests or an honest claim, one finding either way.

## Paper controls (look protective, protect nothing)
- A coverage threshold that is configured but not enforced in CI (`--cov-fail-under` missing, the coverage job allowed to fail).
- A test runner told to pass when it finds no tests (`jest --passWithNoTests`, a pattern that matches no files); pytest instead exits 5 when it collects nothing.
- Test files whose tests have only `pass`, `TODO`, or `assert True` bodies.
