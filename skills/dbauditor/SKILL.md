---
name: dbauditor
description: Audits the database layer of a codebase (referential integrity, indexes, queries, database security, schema design, constraints, transactions, data types, migrations, search, and growth) from its schema files, migrations, ORM models, and queries, and writes dbaudit.md, a scored, prioritized, self-contained report, then prints the verdict in chat. Use when the user asks for a database audit, a schema or data-model review, an index or query performance review, a migration safety check, or a pre-launch database check. Read-only: never connects to a database, never runs or generates migrations, never touches data. Modes: full (default), quick (Critical-class triage), only=DIM,DIM, or a path. Invoke with /dbauditor in Claude Code or $dbauditor in Codex.
allowed-tools: 'Bash(bash "${CLAUDE_SKILL_DIR}/scripts/*)'
---

# dbauditor

**You are now running this audit. Do it yourself, starting now, by working through the Workflow below with your own tools.** Nothing runs in the background. The audit is finished only when `check-report.sh` prints OK and you have sent the chat summary.

Audits the database layer of the codebase in the current directory and writes `dbaudit.md` at its root: scored, prioritized, and self-contained, so another agent holding only the report and the code can fix what it finds. Then prints the verdict in chat.

## Contract

- Read-only. Create or change no file except `dbaudit.md` at the project root. Never run the project, its tests, builds, migrations, or seed scripts; never call a network service or a model.
- Never connect to a database: no queries, no `EXPLAIN`, no generated migrations. Work from schema files, migrations, ORM models, queries, and config. When a verdict depends on row counts, query plans, or production settings you cannot see, lower the confidence and say what would confirm it.
- Allowed: reading and searching files, read-only shell commands (`git log`, `git show`, `ls`, `wc`), and this skill's scripts. The scripts only read, except `new-report.sh` and `score.sh --write`, which write only `dbaudit.md`.
- Evidence: every finding cites a `path:line` you opened and quotes the code there. A `scan.sh` lead is a place to read, never a finding by itself.
- Finish by sending the output of `score.sh --chat`. Never finish silently.

## Paths

`${CLAUDE_SKILL_DIR}` is this skill's folder, the one that contains this SKILL.md; Claude Code fills it in. If you still see the literal text `${CLAUDE_SKILL_DIR}`, replace it with that folder's absolute path in every command. Run every command from the project root.

## Modes

Text after the skill name picks the mode:
- nothing or `full`: every active dimension, every card.
- `quick`: only the cards tagged (quick), the Critical-class checks; no numeric score.
- `only=DBSEC,TYPES`: only those dimensions, every card; the score is labeled partial.
- a path, alone or after a mode (`quick db/migrate`): audit only that part of the tree.

## Workflow

Copy this checklist into your notes and tick each step as you finish it.

- [ ] 1. Run `bash "${CLAUDE_SKILL_DIR}/scripts/inventory.sh"` (add the path if scoped). If it prints NO SOURCE CODE FOUND, tell the user and stop. If it prints `domain surface: NOT FOUND` and reading the code confirms there is no schema, migration, model, query, or datastore config, tell the user there is no database layer to audit and stop.
- [ ] 2. Read `${CLAUDE_SKILL_DIR}/references/protocol.md` (the rules for every finding) and `${CLAUDE_SKILL_DIR}/references/example-report.md` (a finished report).
- [ ] 3. Run `bash "${CLAUDE_SKILL_DIR}/scripts/new-report.sh" --mode <mode>` (add the path if scoped). It creates `dbaudit.md` and lists the active dimensions. Fill the Snapshot lines, naming the engine and its version, the ORM or query layer, and the migration tool. Trace the data model (entities and relationships, hot queries, write paths, growth-bearing tables) and the two or three highest-risk flows (a hot list query and the indexes it can use; a money movement with its transaction, constraints, and types; a parent delete and its cascade or orphans), and write the Map section. If inventory.sh or the code shows a document, key-value, wide-column, search-engine, vector, warehouse, or time-series store, read `${CLAUDE_SKILL_DIR}/references/nonrelational.md` now.
- [ ] 4. Work each active dimension in the listed order:
  - a. Read `${CLAUDE_SKILL_DIR}/references/<DIM>.md`.
  - b. Run `bash "${CLAUDE_SKILL_DIR}/scripts/scan.sh" <DIM>`. In quick mode run `bash "${CLAUDE_SKILL_DIR}/scripts/scan.sh" quick --show-cards` once instead of a and b.
  - c. For every card, read the code at each lead and the files its Leads line names, then apply Confirm, Not a finding if, and Severity. Refute before you record (protocol section 5).
  - d. Add each confirmed finding under `## Findings` in the exact block format (protocol section 2).
  - e. Fill the dimension's notes: `- Checked:` lists every card ID you worked, `- Note:` says what you found.
- [ ] 5. Merge repeats into one finding, write Systemic patterns, Strengths (each with a `path:line`), and Scope and limitations.
- [ ] 6. Run `bash "${CLAUDE_SKILL_DIR}/scripts/score.sh" --write`, then write the Verdict and Calibration lines.
- [ ] 7. Run `bash "${CLAUDE_SKILL_DIR}/scripts/check-report.sh"`. Fix every problem it lists and rerun until it prints `check-report: OK`.
- [ ] 8. Run `bash "${CLAUDE_SKILL_DIR}/scripts/score.sh" --chat` and send its output as your final message.

Stop early only if inventory.sh finds no source code or no database layer, or if you cannot read the files; then say so and write no report.

## Dimensions

| ID | Dimension | Weight | Active when | Cards |
|---|---|---|---|---|
| INTEGRITY | Referential Integrity and Relationships | 14 | always | references/INTEGRITY.md |
| INDEX | Indexing Strategy | 13 | always | references/INDEX.md |
| QUERY | Query Performance and Access Patterns | 12 | always | references/QUERY.md |
| DBSEC | Security and Data Protection at the Database Layer | 12 | always | references/DBSEC.md |
| SCHEMA | Schema Design and Data Modeling | 11 | always | references/SCHEMA.md |
| CONSTRAINTS | Constraints and Data Validation | 10 | always | references/CONSTRAINTS.md |
| TXN | Transactions, Concurrency and Consistency | 9 | a write path exists | references/TXN.md |
| TYPES | Data Types and Storage Efficiency | 7 | always | references/TYPES.md |
| MIGRATION | Migrations and Schema Evolution | 6 | migration tooling or DDL history exists | references/MIGRATION.md |
| SEARCH | Search and Text Retrieval | 4 | a search or text-retrieval surface exists | references/SEARCH.md |
| SCALE | Scalability, Growth and Operations | 2 | always | references/SCALE.md |

new-report.sh decides the conditional dimensions from probes and prints why; if a probe is wrong, move the ID between the Active and Not applicable lines, keep its reason in parentheses, for example `MIGRATION (another service owns the schema)`, and say why in Scope and limitations. Weights re-normalize over the active dimensions. DBSEC and TYPES are floor dimensions: one Critical finding in either (injection, a public or default-password database, a committed live credential, plaintext card, identity, or health data, bypassed tenant isolation, float money) holds the overall score at 69, however good the rest is.

## How to judge

This audit covers the data layer: how data is modeled, how rows are linked and kept consistent, how queries reach them, how concurrent writes stay correct, how the schema changes, how the database protects data, how search works, and whether the design survives growth. Code quality belongs to codeauditor and the application security surface to secauditor; DBSEC covers only the database slice (injection sinks, roles and grants, row-level security, database credentials, data at rest). Touch other areas only where they create a database defect. What billing and membership changes do to customers (a provider never called, a second subscription, usage billed for failed work, shared work lost when a member leaves) belongs to productauditor.

- Verify against the shipped DDL, not the ORM model. Read the migrations or schema dump. A uniqueness validation, an association, or a cascade that exists only in the model enforces nothing against raw SQL, jobs, or a second service; the gap between model and DDL is a finding, often the most serious one.
- Hunt paper controls first: a foreign key `NOT VALID` never validated, a `UNIQUE` on a nullable column, an index whose first column no query filters, a transaction whose queries bypass the transaction handle, row-level security enabled but not forced, a timeout lost through a pooler, a search index synced by dual writes. Every dimension file lists the ones to hunt.
- Blast radius decides severity. A missing index on a ten-row lookup table is not the missing index on the hot orders join; float money in a log table is not float money in the ledger. Spend the most effort on money, identity, tenant isolation, referential integrity, and the hot-path queries. In a sampled codebase, read the schema dump, the whole migration history, the hot-path queries, and the money, identity, search, and growth tables first, and name what you sampled in Snapshot.
- You cannot see row counts, plans, or production settings. When a verdict depends on them, use Likely or Suspected and name what would confirm it (a row count, an `EXPLAIN`, an index-usage statistic, a config value). Never claim you profiled a database.
- Calibrate to the paradigm. In a warehouse or a document store, denormalization is correct; there the risks are documents that grow without bound, hot partitions, and access patterns the keys do not model. Write the paradigm, the data sensitivity and tenancy, and the assumed scale on the Calibration line.
- Every fix must be migration-safe. A recommendation that changes a large table includes the lock-safe path (`CREATE INDEX CONCURRENTLY`, `NOT VALID` then `VALIDATE`, expand-contract, batched backfill); otherwise the fix causes the outage.
- Engine behavior depends on the version (`NULLS NOT DISTINCT` from PostgreSQL 15, MySQL CHECK enforcement from 8.0.16). Check `references/facts.md` before relying on one, and state the version you assumed.
- Name what holds, so the fixer keeps it: real foreign keys with deliberate delete rules, bound parameters throughout, `NUMERIC` money, keyset pagination, partitions with a retention job, uniqueness enforced by the database.

## Reference files

- `references/protocol.md`: evidence rules, finding format, severity, confidence, scoring, modes, finishing.
- `references/example-report.md`: a complete report that passes check-report.sh.
- `references/facts.md`: dated engine and framework facts (version-specific behavior, ORM defaults), with the date they were last reviewed.
- `references/nonrelational.md`: checks for document, key-value, wide-column, search, vector, warehouse, and time-series stores, each filed under a scored dimension.
- `references/INTEGRITY.md`, `references/INDEX.md`, `references/QUERY.md`, `references/DBSEC.md`, `references/SCHEMA.md`, `references/CONSTRAINTS.md`, `references/TXN.md`, `references/TYPES.md`, `references/MIGRATION.md`, `references/SEARCH.md`, `references/SCALE.md`: the cards for each dimension.
- `assets/report-template.md`: the report skeleton new-report.sh fills.
