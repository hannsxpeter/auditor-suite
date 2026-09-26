# ARC: Architecture and Design

Weight 15. Always active.
Owns: how the code is divided and connected: layering and dependency direction, circular dependencies, module cohesion (god files and classes), business rules separated from transport and storage, coupling to other modules' internals, one way to build each concern, over-engineering, per-request data held in shared state, and structure that breaks the architecture the project declares.
Not here: one function that is too long or complex (QUAL-R1); copy-pasted logic (QUAL-R2); two packages that do one job (DEP-R4); docs that describe features the code lacks (DOC-R2); a bypassed layer whose skipped rule is an authorization check (SEC-R2).
Standards: CWE-1047, CWE-1054, CWE-1057, CWE-1068 (CISQ maintainability weaknesses).
Read first: the Map you wrote (modules, layers, flows), the folder layout, and any architecture doc (ARCHITECTURE.md, docs/, a README "Architecture" section) or import-lint rule.

## Cards

### ARC-R1 Code bypasses a layer the project declares, or dependencies point the wrong way
- Leads: `scan.sh ARC-R1` lists modules that import the database driver, ORM, or db module. Compare that list with the layers on your Map and in any architecture doc.
- Confirm: the project declares layers (folders such as `services/` or `repositories/`, an architecture doc, or an import-lint rule), and a handler, view, or UI component reaches past them to the database, an external client, or another layer's internals; or a lower layer imports an upper one (a model or repository that imports a route or the request object).
- Not a finding if: the project is small and flat by design, with no declared service or repository layer (handlers that use the ORM directly are then the design, not a violation); the direct access is a documented exception.
- Severity: High when the bypass skips a rule the layer enforces (validation, transactions, cache invalidation); Medium otherwise.
- Fix: route the call through the layer that owns it (for example `orders.cancel(order_id, user)` instead of an UPDATE in the handler), and add an import-lint rule (eslint `no-restricted-imports`, import-linter, ArchUnit) so the rule stays enforced.
- Verify the fix: `scan.sh ARC-R1` no longer lists the handler, and the import-lint rule fails on a deliberate violation.
- Refs: CWE-1054, CWE-1057, CWE-1068

### ARC-R2 Modules depend on each other in a cycle
- Leads: `scan.sh ARC-R2` lists imports placed inside functions (a common workaround for cycles) and comments that mention circular imports. Then read the imports at the top of the modules on your Map.
- Confirm: module A imports B and B imports A, directly or through a short chain, or an import was moved into a function body to break a cycle.
- Not a finding if: the deferred import only delays a heavy optional dependency and no cycle exists; the import is type-only (`import type`, `if TYPE_CHECKING:`) and creates no runtime cycle.
- Severity: High when the cycle already causes import-order bugs on a real path (a name that is undefined or None at import time, a partially initialized module error); Medium otherwise.
- Fix: move the shared piece into a third module that both import, or invert the dependency with a callback or interface.
- Verify the fix: `madge --circular` (JS), import-linter or `pydeps --show-cycles` (Python), or the compiler (Go) reports no cycle, and the deferred import moves back to the top.
- Refs: CWE-1047

### ARC-R3 God module: one file or class owns many unrelated responsibilities
- Leads: the largest source files. Run `git ls-files | grep -E '\.(py|js|jsx|ts|tsx|rb|go|java|kt|cs|php|rs|swift)$' | xargs wc -l | sort -rn | head -15` and open the biggest ones.
- Confirm: one file or class mixes three or more unrelated responsibilities (for example HTTP handling, pricing rules, email sending, and report formatting), most flows on your Map pass through it, and changes for unrelated features all touch it.
- Not a finding if: the file is long but does one thing (a parser, a generated client, a constants table, a migration); it is a thin router that only delegates.
- Severity: High when it is load-bearing and has no tests; Medium otherwise.
- Fix: split it by responsibility into modules named for what they own, moving one responsibility at a time behind tests.
- Verify the fix: each new module has one reason to change, and the old file's line count and import count drop.
- Refs: CWE-1080

### ARC-R4 Business rules tangled with transport, storage, or I/O
- Leads: route handlers, controllers, CLI commands, and job handlers longer than about 30 lines (from your Map). No search pattern.
- Confirm: a handler makes business decisions (prices, eligibility, state transitions, limits) inline with request parsing, SQL, and response formatting, so the rule cannot be called or tested without HTTP or a database; or the same rule is written separately in two entry points (an API route and a job) and the copies differ.
- Not a finding if: the handler only parses input, calls one domain function, and formats the result.
- Severity: High when the two copies of a rule already disagree; Medium otherwise.
- Fix: move the rule into a plain function or service with explicit inputs and outputs, and call it from every entry point.
- Verify the fix: a unit test calls the rule with no HTTP and no database, and each entry point calls that one function.
- Refs: none

### ARC-R5 Modules reach into each other's internals or share mutable global objects
- Leads: `scan.sh ARC-R5` lists imports of private names, deep relative imports, and writes to global objects.
- Confirm: a module imports another's private names (`_helper`, `/internal/`), changes another module's state, or several modules read and write one global object, so one logical change forces edits across many files.
- Not a finding if: both files belong to one package that owns them; the global is read-only configuration set once at startup.
- Severity: Medium; Low when only one caller reaches in.
- Fix: expose a small public function for what callers need and make the rest private; pass state explicitly instead of through globals.
- Verify the fix: `scan.sh ARC-R5` no longer lists the import, and a change to the internals needs no change in the callers.
- Refs: CWE-1061, CWE-1108

### ARC-R6 The same concern is built several different ways
- Leads: compare how two or three similar features do data access, validation, errors, configuration, and outbound HTTP. No search pattern.
- Confirm: the code has two or more competing approaches to one concern (two HTTP client wrappers, three validation styles, config read in several ways, some routes through the service layer and others not) with no documented reason, so every change must be made several ways.
- Not a finding if: a migration from the old approach to the new one is documented and in progress (a note, an issue, or a deprecation marker).
- Severity: Medium; Low when a small codebase has only two approaches.
- Fix: pick one approach, write it down in CONTRIBUTING or ARCHITECTURE, and migrate the others to it.
- Verify the fix: a search for the old approach's entry point returns no hits.
- Refs: none

### ARC-R7 Indirection with no second use (over-engineering)
- Leads: `scan.sh ARC-R7` lists factory, strategy, adapter, provider, base, and interface types. Count the implementations of each.
- Confirm: an abstraction serves a variation the code does not have: an interface with one implementation and no test double, a factory that builds one class, a plugin system with one plugin, a generic repository that wraps one ORM call, or options nothing reads.
- Not a finding if: the second implementation is a test double that tests use, or the abstraction is a published extension point for users.
- Severity: Medium when the indirection makes a main flow hard to trace; Low otherwise.
- Fix: inline the single implementation and delete the layer; bring it back when a second case exists.
- Verify the fix: the flows on your Map pass through fewer files, and the tests still pass.
- Refs: none

### ARC-R8 Per-request data kept in module-level or global state that concurrent requests share (quick)
- Leads: `scan.sh ARC-R8` lists `global` statements and mutable module-level variables. Read where each is written.
- Confirm: a handler or job stores request- or user-specific data (the current user, tenant, cart, or request parameters) in a module-level variable, class attribute, or singleton, and the server runs requests concurrently (threads, async tasks, or several workers per process), so one request can read another's value.
- Not a finding if: the framework scopes the state to the request (Flask `g`, `contextvars`, Node `AsyncLocalStorage`, a per-request container); the server handles one request at a time by configuration (read it); the global is a read-only cache of data that is the same for every user.
- Severity: Critical when the shared value carries identity, permissions, or personal data, so one user can act as, or see the data of, another; High for other per-request values.
- Fix: keep per-request data in local variables or the framework's request context (`contextvars.ContextVar`, `AsyncLocalStorage`, Flask `g`).
- Verify the fix: a test that runs two concurrent requests for different users sees each response carry only its own user's data.
- Refs: CWE-362, CWE-488, CWE-567

## Also check
- Names that no longer match what the code inside does (a `utils` module holding business rules, a `services/` folder holding HTTP handlers).
- Entry points (scheduled jobs, message consumers, CLI commands) that bypass the path web requests take and skip its rules.
- Where state lives: in-process caches, singletons, or files on local disk that stop the app from running as two instances.

## Paper controls (look protective, protect nothing)
- An architecture doc or layer diagram that no import rule enforces and the code no longer follows.
- A repository or service layer that most callers skip.
- A `services/` layer whose functions only forward to the ORM while the handlers keep the business rules.
- A dependency-injection container that is configured but bypassed by direct imports and constructors.
