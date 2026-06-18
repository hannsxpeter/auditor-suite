# dbauditor

A read-only **database audit** skill for AI coding agents. It audits the database layer of the codebase in the current working directory end to end (schema, relationships, indexing, queries, transactions, migrations, data protection, search, and scale), writes a scored, prioritized, self-contained `dbaudit.md` at the repo root, then prints the verdict in chat. It works from the schema files, migrations, ORM models, and queries in the repo: it never connects to a live database, never runs a migration, and never mutates data.

It is the data-layer counterpart to `codeauditor` (code quality), `uxauditor` (user experience), and `secauditor` (security), and it is **dual-compatible**: the same `SKILL.md` runs in both Claude Code and Codex.

- In **Claude Code**: invoke with `/dbauditor`
- In **Codex**: invoke with `$dbauditor`

## What it audits

The audit is grounded in the standard database-engineering literature (SQL Antipatterns by Bill Karwin; SQL Performance Explained / Use The Index, Luke by Markus Winand; Designing Data-Intensive Applications by Martin Kleppmann), the official PostgreSQL, MySQL/MariaDB, SQLite, SQL Server, and Oracle documentation, the strong_migrations and Squawk bodies of knowledge for lock-safe schema changes, and the relevant OWASP and NIST guidance for the database-security slice. It scores eleven dimensions, three of which are conditional on the project's surface:

| Dimension | Weight | Applies |
|---|---|---|
| Referential Integrity and Relationships (linkage) | 14% | always |
| Indexing Strategy | 13% | always |
| Query Performance and Access Patterns | 12% | always |
| Security and Data Protection at the DB layer | 12% | always |
| Schema Design and Data Modeling | 11% | always |
| Constraints and Data Validation | 10% | always |
| Transactions, Concurrency and Consistency | 9% | if a write path exists |
| Data Types and Storage Efficiency | 7% | always |
| Migrations and Schema Evolution | 6% | if migration tooling exists |
| Search and Text Retrieval | 4% | if a search surface exists |
| Scalability, Growth and Operations | 2% | always (re-weighted up on growth signals) |

Conditional dimensions are dropped and the remaining weights re-normalized when their surface is absent, so the score stays meaningful for any project type. A separate **non-relational and analytics lens** (MongoDB, DynamoDB, Cassandra, Redis, vector stores, Snowflake/BigQuery/dbt, time-series) re-points findings into the scored dimensions and recalibrates them, because denormalization is correct in a warehouse or a document store.

## How it works

The method runs in phases: orient and detect engines, surfaces, and the workload paradigm; map the data model and trace the highest-risk flows; analyze across every lens with `file:line` evidence and the data path; verify each candidate adversarially and cluster duplicates into systemic patterns; score with conditional re-normalization (a single Critical caps the dimension at 69 and the overall at 79, and a security or data-loss critical caps the overall grade outright); prioritize into Quick wins / Plan now / Verify first / Backlog; write `dbaudit.md`; and report the verdict in chat.

Two principles make it different from a linter:

- **It reads the shipped DDL, not the ORM's promise.** An ActiveRecord `validates_uniqueness_of`, a Prisma `@unique`, or a `belongs_to` enforces nothing in the database. Only a DB `UNIQUE`/`FOREIGN KEY`/`CHECK` does, and the gap between the model's claim and the migration is itself a finding.
- **It actively hunts paper controls.** A Postgres foreign key added `NOT VALID` and never validated, a `UNIQUE` on a nullable column that lets unlimited NULLs through, an index whose leftmost column no query filters, an inert `@Transactional`, RLS enabled but not `FORCE`d, an external search index kept in sync by best-effort dual-write: each looks protective and holds nothing.

Every finding is self-contained: an exact `file:line` and the data path, the concrete consequence and its blast radius, a specific fix with the **lock-safe migration** to apply it, a way to verify the fix, and a reference. An ownership map ensures each defect is scored by exactly one dimension instead of triple-counting across lenses.

## Install

The skill is a single `skills/dbauditor/SKILL.md`. Install it into whichever tool you use.

### Claude Code

As a personal skill:

```sh
mkdir -p ~/.claude/skills/dbauditor
cp skills/dbauditor/SKILL.md ~/.claude/skills/dbauditor/SKILL.md
```

Or install the whole repo as a Claude Code plugin (it ships a `.claude-plugin/plugin.json` manifest) via your plugin workflow, then invoke `/dbauditor`.

### Codex

```sh
mkdir -p ~/.codex/skills/dbauditor
cp skills/dbauditor/SKILL.md ~/.codex/skills/dbauditor/SKILL.md
```

Codex also reads skills from `~/.agents/skills/` and `.agents/skills/` (repo-local); any of these works. Invoke with `$dbauditor`, or run `/skills` to list.

## Usage

From the root of the project you want to audit:

- Claude Code: `/dbauditor` (optionally pass a subpath, schema name, or single engine to scope the audit)
- Codex: `$dbauditor`

The skill writes `dbaudit.md` to the audited project's root and prints the score, scorecard, and top fixes in chat.

## Output

`dbaudit.md` is written for a reader with no memory of the audit (typically another agent that will fix the findings). It contains the snapshot, the data-model map, the overall score and scorecard, "what to fix first", strengths to preserve, systemic root causes, the full findings, a remediation plan, scope and limitations, and a "how to use this report" protocol.

## License

MIT. See [LICENSE](LICENSE).
