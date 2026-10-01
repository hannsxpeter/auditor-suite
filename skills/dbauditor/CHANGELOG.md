# Changelog

All notable changes to dbauditor are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Since 2026-07-14 the
skill versions with the auditor-suite release train named in the hub
[`VERSION`](../../VERSION) file.

## [auditor-suite 1.2.0] - 2026-10-01

Released with productauditor, the suite's eighth auditor. The cards now name
the product topics that moved to it, and the shared scripts pick leads more
fairly and gain fixes.

### Changed

- `SKILL.md`: the judgment notes hand what billing and membership changes do
  to customers (a provider never called, a second subscription, usage billed
  for failed work, shared work lost when a member leaves) to productauditor.
- `TXN.md`: the Not here line hands usage billed for failed or unrequested
  operations and seat counts the provider never learns (productauditor
  BILL-R7), and a cancel or upgrade that never calls the billing provider or a
  second active subscription from checkout (productauditor BILL-R4), to
  productauditor. TXN-R3 and TXN-R4 keep idempotency and provider calls that
  diverge on a crash.
- `INTEGRITY.md`: the Not here line hands a subscription or plan copied from
  the billing provider with no webhook or reconciliation (productauditor
  BILL-R3), and whether a removed member's shared work should survive
  (productauditor CUST-R2), to productauditor. INTEGRITY-R2's Not a finding if
  gains a workspace's shared content reached from a user or membership delete.
- `SCHEMA.md`: the Not here line hands a plan or subscription status copied
  from the billing provider (productauditor BILL-R3) and an entitlement check
  that compares against a plan value billing never writes (productauditor
  ENT-R2) to productauditor.
- `SKILL.md`: when a probe is wrong and you move a dimension between the
  Active and Not applicable lines, keep its reason in parentheses, for example
  `MIGRATION (another service owns the schema)`; `check-report.sh` now
  requires one.
- `scan.sh`: when a card has more leads than `--max` (12 by default), it
  picks the ones it shows round-robin across files in path order (the first
  lead of each file, then the second of each, until the cap) and still prints
  them in path and line order. Before, it showed the first 12 in path order,
  so one file full of hits hid every file after it. `scan.sh --help` now
  explains `--max` and the selection.
- The scripts read an optional `SCAN_SKIP_RE` from `assets/skill.conf`, a
  regex of paths this auditor's scans and probes skip. dbauditor sets none, so
  the setting changes nothing here.
- Scans skip `productaudit.md`, the new auditor's report, as they skip the
  other reports.

### Fixed

- On macOS and with gawk, files such as `admin.js` and `admin.css` are no
  longer dropped from scans and probes as if they were minified bundles: the
  scripts now pass regexes to awk through `ENVIRON`, which keeps their
  backslashes.
- The file list leaves out symlinks, submodules, and tracked files that are
  deleted or outside a sparse checkout, so ripgrep and grep search the same
  files and no scan follows a link out of the project.
- Surface probes take their first hit in path and line order, so
  `inventory.sh` and `new-report.sh` cite the same hit on every run; ripgrep
  prints files in no fixed order.
- Reports are never written through a symlink, and the temporary file for a
  report write stays in the project, beside the report. `score.sh --write`
  keeps the report's permission bits and refuses a read-only report instead
  of replacing it.
- `check-report.sh` requires every dimension in exactly one of the Active and
  Not applicable lines (Not assessed in `only=` mode), with a reason in
  parentheses for each not-applicable dimension.
- Only the IDs after "Members:" count as systemic-pattern members, and CWE,
  CVE, and hash names (such as SHA-256) in a root fix or Related line are no
  longer read as finding IDs.
- `new-report.sh --mode only=` normalizes its list: spaces and empty items
  are dropped, and each ID is kept once.
- Leads no longer depend on the user's ripgrep config, `GREP_OPTIONS`, or
  locale.
- Projects inside a folder that an outer repository ignores are scanned.

## [auditor-suite 1.1.0] - 2026-09-26

Restructured so the skill works for small and local models as well as frontier
models. The audit knowledge is preserved; its shape changed.

### Changed

- `SKILL.md` is now a short spine (about 2,500 tokens, down from about 15,500):
  contract, modes, an eight-step workflow checklist, the dimension table, and
  judgment notes. Detail moved to files read only when a step needs them.
- Each dimension's checklist became rule cards in `references/<DIM>.md` (71
  cards, 21 of them tagged quick): where to look, how to confirm, when it is
  not a finding, severity, the fix with its lock-safe migration, and how to
  verify the fix. The eleven dimensions and their weights are unchanged.
- The ownership map became card placement: each defect has one card, and the
  other dimension's file names it on its "Not here" line.
- The "security and data-loss floor" is now two floor dimensions, DBSEC and
  TYPES: one Critical finding in either holds the overall score at 69. Scores
  are computed by `scripts/score.sh` from the findings, so re-runs are
  comparable; Suspected findings count half and never cap a score.
- SCALE keeps its fixed weight of 2 (scores stay reproducible); growth now
  raises the severity conditions in the SCALE cards instead of the weight.
- The non-relational and analytics lens moved to `references/nonrelational.md`;
  its findings use the scored dimension's ID instead of NOSQL or ANALYTICS.
- Findings drop the `Owner` field (the ID prefix is the owning dimension) and
  must quote the cited code in Evidence; `check-report.sh` verifies it. Medium
  findings go to a new Schedule bucket.

### Added

- Modes: `quick` (Critical-class cards only, no score), `only=DIM,DIM`, and a
  path scope.
- Read-only scripts: `inventory.sh` (which also stops the audit when there is
  no database layer), `scan.sh`, `new-report.sh`, `score.sh`, and
  `check-report.sh`.
- `references/example-report.md` (validated in CI against
  `tests/fixtures/dbauditor/`), `references/facts.md` (dated engine and ORM
  facts), `references/nonrelational.md`, and an eval case under
  `evals/dbauditor/`.
- Checks that were implicit before: queries that bypass the transaction handle
  (TXN-R7), schema changes made by ORM sync at startup (MIGRATION-R5), Laravel
  `foreignId()` and Rails `t.references` without a foreign key and Prisma
  `relationMode = "prisma"` (INTEGRITY-R1), PostgreSQL 18 `NOT ENFORCED`
  constraints (INTEGRITY-R3, CONSTRAINTS-R5), `UNIQUE (email, deleted_at)`
  letting live duplicates through (CONSTRAINTS-R2), DDL queued without a
  `lock_timeout` (MIGRATION-R2), and search results that skip the tenant filter
  (SEARCH-R5, promoted from a paper-control note).

### Fixed

- `now()` is stable, not volatile: `ADD COLUMN ... DEFAULT now()` does not
  rewrite the table on PostgreSQL 11 or later. The rewrite examples are now
  `gen_random_uuid()`, `random()`, and `clock_timestamp()`.
- Django `unique=True`, Prisma `@unique`, SQLAlchemy, TypeORM, and JPA unique
  settings do create constraints through generated migrations; the rule now
  says to check the migration. Rails and Laravel validations never do.
- Prisma `onDelete` is emulated in the client only under
  `relationMode = "prisma"`; otherwise Prisma Migrate writes it into the DDL.
- SQL Server: `READ_COMMITTED_SNAPSHOT` does not stop lost updates, while
  SNAPSHOT isolation detects write-write conflicts (error 3960) but still
  allows write skew.
- A 32-bit key makes inserts fail at 2,147,483,647; the read-only mode belongs
  to transaction ID wraparound, now described separately in SCALE.
- `DECIMAL` with no scale truncates cents on MySQL (10,0) and SQL Server
  (18,0); PostgreSQL `NUMERIC` with no precision is not a defect.
- Overlaps inside the skill now have one owner each: missing index versus
  missing foreign key (INDEX-R1 and INTEGRITY-R1); an unvalidated foreign key
  (INTEGRITY-R3) or CHECK (CONSTRAINTS-R5) rather than MIGRATION; a packed list
  of IDs (SCHEMA-R1) versus a weak junction table (INTEGRITY-R6); a missing
  unique on a natural key (CONSTRAINTS-R1, not SCHEMA); an idempotency key
  column without UNIQUE (CONSTRAINTS-R1) versus no key at all (TXN-R3);
  non-overlap and uniqueness races (CONSTRAINTS) versus write skew no
  constraint can express (TXN-R5); a rewritable predicate (QUERY-R4) versus an
  inherent expression that needs an index (INDEX-R5); leading-wildcard search
  (SEARCH-R1 behind a search feature, otherwise QUERY-R4); OFFSET and unbounded
  results (QUERY, not SCALE); random UUID keys (TYPES-R3, not SCALE); the
  statement timeout (QUERY-R7) versus pool capacity and role-default lock
  timeouts (SCALE); a parent key widened without its referencing columns
  (INTEGRITY-R5, not SCALE); the keyset tiebreaker (QUERY-R3, not SCALE); a
  cross-row copy (SCHEMA-R6) versus a same-row derived value (CONSTRAINTS-R5);
  soft delete split into INTEGRITY-R7, CONSTRAINTS-R2, and a SCHEMA design
  check.

## [auditor-suite 1.0.0] - 2026-07-14

Moved into the [auditor-suite](https://github.com/hannsxpeter/auditor-suite)
monorepo as `skills/dbauditor/`, with the standalone repo's full git history
preserved. Standalone versioning is retired; the skill now follows the
auditor-suite release train.

### Changed

- The standalone `.claude-plugin/plugin.json` manifest is retired; plugin
  packaging now lives in the hub under `plugins/dbauditor/`.
- The audit content in `SKILL.md` is unchanged from standalone 0.1.1.

## [0.1.1] - 2026-06-18

Standalone release from `hannsxpeter/dbauditor`. Documented dual invocation:
`/dbauditor` in Claude Code and `$dbauditor` in Codex. Full details in the git
history under `skills/dbauditor/`.

## [0.1.0] - 2026-06-18

First standalone release: the read-only database audit skill covering schema,
relationships, indexing, queries, transactions, migrations, data protection,
search, and scale, writing a scored, prioritized `dbaudit.md`.
