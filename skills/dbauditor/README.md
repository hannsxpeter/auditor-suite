# dbauditor

A read-only **database audit** skill for AI coding agents, part of the [auditor-suite](../../README.md). It audits the database layer of the codebase in the current directory from its schema files, migrations, ORM models, and queries, writes a scored, prioritized, self-contained `dbaudit.md` at the project root, and prints the verdict in chat. It never connects to a database, never runs or generates migrations, and never touches data.

- Claude Code: `/dbauditor`
- Codex: `$dbauditor`
- Other Agent Skills harnesses: the harness's native skill invocation

## What it audits

Eleven dimensions, grounded in SQL Antipatterns (Karwin), Use The Index, Luke and SQL Performance Explained (Winand), Designing Data-Intensive Applications (Kleppmann), the PostgreSQL, MySQL, SQL Server, SQLite, and Oracle documentation, the strong_migrations and Squawk rules for lock-safe schema changes, and CWE, OWASP, and PCI DSS for the database-security slice.

| ID | Dimension | Weight | Active when |
|---|---|---|---|
| INTEGRITY | Referential Integrity and Relationships | 14 | always |
| INDEX | Indexing Strategy | 13 | always |
| QUERY | Query Performance and Access Patterns | 12 | always |
| DBSEC | Security and Data Protection at the Database Layer | 12 | always |
| SCHEMA | Schema Design and Data Modeling | 11 | always |
| CONSTRAINTS | Constraints and Data Validation | 10 | always |
| TXN | Transactions, Concurrency and Consistency | 9 | a write path exists |
| TYPES | Data Types and Storage Efficiency | 7 | always |
| MIGRATION | Migrations and Schema Evolution | 6 | migration tooling or DDL history exists |
| SEARCH | Search and Text Retrieval | 4 | a search or text-retrieval surface exists |
| SCALE | Scalability, Growth and Operations | 2 | always |

Weights re-normalize over the active dimensions, so a project without migrations or search is scored only on what it has. DBSEC and TYPES are floor dimensions: one Critical finding in either (injection, an exposed or default-password database, a committed live credential, plaintext card, identity, or health data, bypassed tenant isolation, float money) holds the overall score at 69 no matter how good the rest is.

Document, key-value, wide-column, search-engine, vector, warehouse, and time-series stores are covered by a lens (`references/nonrelational.md`) that files each finding under the scored dimension it belongs to and recalibrates for the paradigm: denormalization is correct in a warehouse or a document store.

Two principles make it more than a linter:

- **It reads the shipped DDL, not the ORM's promise.** A Rails uniqueness validation, a model-only association, or an ORM cascade enforces nothing against raw SQL, jobs, or a second service; the gap between model and migration is a finding.
- **It hunts paper controls.** A foreign key `NOT VALID` never validated, a `UNIQUE` on a nullable column, an index whose first column no query filters, queries that bypass the transaction handle, row-level security enabled but not forced, a search index synced by dual writes: each looks protective and holds nothing.

Every recommendation that changes a large table carries the lock-safe path (`CREATE INDEX CONCURRENTLY`, `NOT VALID` then `VALIDATE`, expand-contract, batched backfill), because the fix must not cause the outage.

## Modes

- `/dbauditor` or `/dbauditor full`: every active dimension and every card.
- `/dbauditor quick`: only the Critical-class cards; no numeric score. A good first pass for small models or large repos.
- `/dbauditor only=DBSEC,TYPES`: a subset of dimensions with a partial score.
- `/dbauditor db/migrate` (or `quick db/migrate`): limit the audit to a path.

## How it works

The skill is a short procedural spine (`SKILL.md`) plus files it reads only when needed:

- `references/protocol.md`: the shared rules for evidence, the finding format, severity, confidence, scoring, and finishing.
- `references/<DIM>.md`: one file of rule cards per dimension. Each card says where to look (a `scan.sh` lead or the files to read), how to confirm the defect, when it is not a finding, the severity, the fix with its lock-safe migration, and how to verify the fix. Every dimension also lists its paper controls.
- `references/nonrelational.md`: the store-specific checks for MongoDB, DynamoDB, Cassandra, Redis, search engines and vector stores, warehouses and dbt, and time-series databases.
- `references/facts.md`: dated engine and framework facts (for example `NULLS NOT DISTINCT` from PostgreSQL 15, MySQL CHECK enforcement from 8.0.16, ORM type defaults) with a review date.
- `references/example-report.md`: a complete report that passes the validator, as a format anchor.
- `scripts/`: read-only helpers. `inventory.sh` maps the project and decides the conditional dimensions (and says so when there is no database layer to audit); `scan.sh` turns cards into leads; `new-report.sh` writes the report skeleton; `score.sh` computes every score from the findings; `check-report.sh` validates the report, including that every cited `path:line` exists and contains the quoted code.
- `assets/`: the report template and the tables the scripts read (`skill.conf`, `dimensions.tsv`, `patterns.tsv`, `surfaces.tsv`).

The model does the judgment (reading the DDL and queries, confirming or refuting each lead, choosing severity from the card's conditions); the scripts do the bookkeeping. Scores are deterministic: the same findings always produce the same score.

## Install

Use the hub installer or the plugin marketplace; see the [suite README](../../README.md#install). A manual install must copy or link the whole skill directory (`SKILL.md`, `references/`, `scripts/`, `assets/`), not just `SKILL.md`.

## Output

`dbaudit.md` is written for a reader with no memory of the audit, typically another agent that will fix the findings: snapshot, data-model map, score and scorecard, what to fix first, strengths to preserve, systemic root causes, findings with `path:line` evidence and a way to verify each fix, dimension notes, a remediation plan, scope and limitations, and a protocol for the acting agent.

## License

MIT. See [LICENSE](LICENSE).
