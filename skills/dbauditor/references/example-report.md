# Database audit: harbor-stays-bookings

> Read-only database audit of the code as written, 2026-09-26. No database was connected, no migration was run, and no data was touched. Mode: full. Scope: whole project.
> Self-contained: every finding cites the file and line it is about, so an agent holding only this report and the code can act on it. Written with dbauditor (auditor-suite 1.1.0).

## Snapshot

- Project: harbor-stays-bookings (example fixture; no git history of its own)
- Stack: TypeScript, Prisma 5 (`@prisma/client`), PostgreSQL 16, Prisma Migrate with one migration
- Size and coverage: 4 source files (2 TypeScript, 1 Prisma schema, 1 SQL migration), about 80 lines; read exhaustively
- Maturity and exposure: production booking service for a group of 12 hotels (README); the booking flow is public, the guest search is used by front-desk staff
- Active dimensions: INTEGRITY, INDEX, QUERY, DBSEC, SCHEMA, CONSTRAINTS, TXN, TYPES, MIGRATION, SEARCH, SCALE
- Not applicable: none
- Not assessed: none
- Excluded: none

## Map

Two tables: `Room` (unique `code`, `DECIMAL(10,2)` rate) and `Booking`. The one link, `Booking.roomId` to `Room.id`, is DB-enforced with `ON DELETE RESTRICT` (`prisma/migrations/20240201090000_init/migration.sql:27`); no cross-service links, derived stores, or replicas. The only write path is the single-statement booking insert (`src/bookings.ts:12`), the only place money is written; `Booking` grows by about 300 rows a day.

Flows traced: (1) public booking: overlap check by room and dates (`src/bookings.ts:6`) with no `roomId` index and no exclusion constraint, then the total computed as a float (`src/bookings.ts:13`) and stored as `DOUBLE PRECISION` (`prisma/migrations/20240201090000_init/migration.sql:17`). (2) front-desk search: `contains` in insensitive mode (`src/bookings.ts:19`), a leading-wildcard `ILIKE` with no trigram index.

## Overall score

<!-- BEGIN GENERATED: score (score.sh --write fills this block; do not edit it by hand) -->
**Overall: 69/100, Grade D (weak, systemic problems)**

| Dimension | Score | Grade | Weight | Critical | High | Medium | Low | Suspected |
|---|---:|---|---:|---:|---:|---:|---:|---:|
| INTEGRITY Referential Integrity and Relationships | 100 | A | 14.0% | 0 | 0 | 0 | 0 | 0 |
| INDEX Indexing Strategy | 97 | A | 13.0% | 0 | 0 | 1 | 0 | 0 |
| QUERY Query Performance and Access Patterns | 100 | A | 12.0% | 0 | 0 | 0 | 0 | 0 |
| DBSEC Security and Data Protection at the Database Layer | 100 | A | 12.0% | 0 | 0 | 0 | 0 | 0 |
| SCHEMA Schema Design and Data Modeling | 100 | A | 11.0% | 0 | 0 | 0 | 0 | 0 |
| CONSTRAINTS Constraints and Data Validation | 90 | A | 10.0% | 0 | 1 | 0 | 0 | 0 |
| TXN Transactions, Concurrency and Consistency | 100 | A | 9.0% | 0 | 0 | 0 | 0 | 0 |
| TYPES Data Types and Storage Efficiency | 69 | D | 7.0% | 1 | 0 | 0 | 0 | 0 |
| MIGRATION Migrations and Schema Evolution | 100 | A | 6.0% | 0 | 0 | 0 | 0 | 0 |
| SEARCH Search and Text Retrieval | 98 | A | 4.0% | 0 | 0 | 0 | 0 | 1 |
| SCALE Scalability, Growth and Operations | 100 | A | 2.0% | 0 | 0 | 0 | 0 | 0 |
| **Overall** | **69** | **D** | 100% | 1 | 1 | 1 | 0 | 1 |

Caps applied: TYPES held at 69 (one Critical finding); overall held at 69 (a Critical finding in a floor dimension).
Findings: Critical 1, High 1, Medium 1, Low 0 (Suspected, not yet confirmed: 1).
Computed by score.sh from the findings below (rules: references/protocol.md, Scoring).
<!-- END GENERATED: score -->

Verdict: A small, well-typed schema with one money defect and two missing database guarantees. Booking totals are `DOUBLE PRECISION` computed with JavaScript floats, which holds the score at 69 because TYPES is a floor dimension, and double bookings are stopped only by a read before the insert.

Calibration: a production OLTP service taking public bookings and money at modest scale (400 rooms, 300 bookings a day, PostgreSQL 16); index severities held at Medium because the tables are still small.

## What to fix first

<!-- BEGIN GENERATED: fix-first (score.sh --write) -->
1. [TYPES-001] Booking.totalPrice stores each booking's charge as DOUBLE PRECISION, computed with JavaScript floats - Critical, effort M. booking totals are approximations (3 nights at 109.90 is stored as 329.70000000000005), so invoices, refunds, and revenue sums fail exact reconcili...
2. [CONSTRAINTS-001] Double bookings are prevented only by a read before the insert in createBooking - High, effort M. two guests booking the same room for overlapping dates at the same moment both pass the check, and both bookings are confirmed.
<!-- END GENERATED: fix-first -->

## Strengths (preserve these)

- Room rates are `DECIMAL(10,2)` (`prisma/migrations/20240201090000_init/migration.sql:5`).
- The hand-written `Booking_dates_check` rejects inverted stays in the database (`prisma/migrations/20240201090000_init/migration.sql:30`).
- `ON DELETE RESTRICT` means deleting a room can never remove its bookings (`prisma/migrations/20240201090000_init/migration.sql:27`).
- Stay dates are `DATE` and `createdAt` is `TIMESTAMPTZ(3)` (`prisma/migrations/20240201090000_init/migration.sql:15`).

## Systemic patterns (root causes)

- SYS-1: the database gets only what Prisma generates by default, though the team already hand-writes SQL for `Booking_dates_check`. Members: CONSTRAINTS-001, INDEX-001. Root fix: review each generated `migration.sql` against the queries and invariants, declare `@@index([roomId, checkIn])`, and add the exclusion constraint beside `Booking_dates_check`.

## Findings

### [TYPES-001] Booking.totalPrice stores each booking's charge as DOUBLE PRECISION, computed with JavaScript floats
- Severity: Critical | Confidence: Confirmed | Effort: M | Dimension: TYPES
- Location: `prisma/migrations/20240201090000_init/migration.sql:17` (also `prisma/schema.prisma:24`, `src/bookings.ts:13`)
- Evidence: the migration creates `"totalPrice" DOUBLE PRECISION NOT NULL` (schema: `totalPrice Float`), and `createBooking` stores `totalPrice: Number(room.nightly) * nights`, turning the decimal rate into a binary float.
- Impact: booking totals are approximations (3 nights at 109.90 is stored as 329.70000000000005), so invoices, refunds, and revenue sums fail exact reconciliation with the payment provider.
- Recommendation: declare `totalPrice Decimal @db.Decimal(12, 2)` and compute `room.nightly.mul(nights)`. At this size one `ALTER COLUMN "totalPrice" TYPE numeric(12,2)` is fine; on a large table use a new column, dual writes, and a batched backfill.
- Verify the fix: `information_schema.columns` shows `numeric` for `Booking.totalPrice`, and a test booking 3 nights at 109.90 stores exactly 329.70.
- References: CWE-1339, SQL Antipatterns "Rounding Errors"
- Related: none

### [CONSTRAINTS-001] Double bookings are prevented only by a read before the insert in createBooking
- Severity: High | Confidence: Confirmed | Effort: M | Dimension: CONSTRAINTS
- Location: `src/bookings.ts:6-8` (also `prisma/migrations/20240201090000_init/migration.sql:11`)
- Evidence: `createBooking` calls `prisma.booking.findFirst(` for an overlapping stay, then `prisma.booking.create` with no transaction or lock; `Booking` has no exclusion constraint.
- Impact: two guests booking the same room for overlapping dates at the same moment both pass the check, and both bookings are confirmed.
- Recommendation: after resolving existing overlaps, add a hand-written step: `CREATE EXTENSION IF NOT EXISTS btree_gist;` and `ALTER TABLE "Booking" ADD CONSTRAINT "Booking_no_overlap" EXCLUDE USING gist ("roomId" WITH =, daterange("checkIn", "checkOut") WITH &&);`; turn SQLSTATE 23P01 into a conflict response.
- Verify the fix: a test running two concurrent `createBooking` calls for the same room and dates gets one booking and one conflict error.
- References: PostgreSQL docs, Exclusion Constraints
- Related: SYS-1

### [INDEX-001] Booking.roomId has a foreign key but no index, and every booking attempt filters by it
- Severity: Medium | Confidence: Likely | Effort: S | Dimension: INDEX
- Location: `prisma/migrations/20240201090000_init/migration.sql:27` (also `prisma/schema.prisma:19`, `src/bookings.ts:7`)
- Evidence: the migration adds `FOREIGN KEY ("roomId") REFERENCES "Room"("id")` but no index on it (PostgreSQL and Prisma add none), while the overlap check filters by `roomId`.
- Impact: every booking attempt scans the whole `Booking` table; cheap today, it grows by about 300 rows a day (assumes the README's volume).
- Recommendation: add `@@index([roomId, checkIn])` to `Booking`; once the table is large, build it with `CREATE INDEX CONCURRENTLY` as the only statement in its migration file, outside a transaction.
- Verify the fix: EXPLAIN of the overlap query on production-size data shows an index scan on the new index.
- References: PostgreSQL docs, Foreign Keys; Use The Index, Luke
- Related: SYS-1

### [SEARCH-001] Front-desk guest search runs a leading-wildcard ILIKE over all bookings with no trigram index
- Severity: Medium | Confidence: Suspected | Effort: S | Dimension: SEARCH
- Location: `src/bookings.ts:19`
- Evidence: `findBookingsByGuest` filters `guestName: { contains: name, mode: 'insensitive' }` (an `ILIKE '%name%'`), and no `pg_trgm` index exists on `"guestName"`.
- Impact: each search scans every booking; whether staff notice depends on table size and search rate, which the code does not show.
- Recommendation: `CREATE EXTENSION IF NOT EXISTS pg_trgm;` and `CREATE INDEX "Booking_guestName_trgm_idx" ON "Booking" USING gin ("guestName" gin_trgm_ops);` in a hand-written migration (concurrently once the table is large).
- Verify the fix: first confirm with a row count and EXPLAIN ANALYZE of the search on production data; after the fix the plan uses the trigram index.
- References: PostgreSQL docs, pg_trgm; SQL Antipatterns "Poor Man's Search Engine"
- Related: none

## Dimension notes

### INTEGRITY: Referential Integrity and Relationships
- Checked: INTEGRITY-R1, INTEGRITY-R2, INTEGRITY-R3, INTEGRITY-R4, INTEGRITY-R5, INTEGRITY-R6, INTEGRITY-R7, INTEGRITY-R8
- Note: clean: the one relationship has a real foreign key with ON DELETE RESTRICT and matching types.

### INDEX: Indexing Strategy
- Checked: INDEX-R1, INDEX-R2, INDEX-R3, INDEX-R4, INDEX-R5, INDEX-R6
- Note: INDEX-001; `Room_code_key` backs the unique code and is not a duplicate.

### QUERY: Query Performance and Access Patterns
- Checked: QUERY-R1, QUERY-R2, QUERY-R3, QUERY-R4, QUERY-R5, QUERY-R6, QUERY-R7
- Note: clean: no queries in loops, the search is capped at 50 rows, no OFFSET; the timeout would live in DATABASE_URL (Scope).

### DBSEC: Security and Data Protection at the Database Layer
- Checked: DBSEC-R1, DBSEC-R2, DBSEC-R3, DBSEC-R4, DBSEC-R5, DBSEC-R6, DBSEC-R7
- Note: clean: all queries use Prisma's parameterized API, no credential is committed, one tenant, ordinary contact data.

### SCHEMA: Schema Design and Data Modeling
- Checked: SCHEMA-R1, SCHEMA-R2, SCHEMA-R3, SCHEMA-R4, SCHEMA-R5, SCHEMA-R6, SCHEMA-R7
- Note: clean: both tables have primary keys; `totalPrice` is a deliberate snapshot of the price at booking time.

### CONSTRAINTS: Constraints and Data Validation
- Checked: CONSTRAINTS-R1, CONSTRAINTS-R2, CONSTRAINTS-R3, CONSTRAINTS-R4, CONSTRAINTS-R5, CONSTRAINTS-R6
- Note: CONSTRAINTS-001; room codes are unique in the DDL and every column is NOT NULL.

### TXN: Transactions, Concurrency and Consistency
- Checked: TXN-R1, TXN-R2, TXN-R3, TXN-R4, TXN-R5, TXN-R6, TXN-R7
- Note: no read-modify-write or multi-statement write; the overlap race is filed once, under CONSTRAINTS-001.

### TYPES: Data Types and Storage Efficiency
- Checked: TYPES-R1, TYPES-R2, TYPES-R3, TYPES-R4, TYPES-R5, TYPES-R6
- Note: TYPES-001, a floor-dimension Critical, holds the overall at 69; dates and timestamps use the right types.

### MIGRATION: Migrations and Schema Evolution
- Checked: MIGRATION-R1, MIGRATION-R2, MIGRATION-R3, MIGRATION-R4, MIGRATION-R5, MIGRATION-R6
- Note: clean: the single migration builds its index and constraints on new, empty tables.

### SEARCH: Search and Text Retrieval
- Checked: SEARCH-R1, SEARCH-R2, SEARCH-R3, SEARCH-R4, SEARCH-R5
- Note: SEARCH-001 (Suspected); no external search engine or vector store exists.

### SCALE: Scalability, Growth and Operations
- Checked: SCALE-R1, SCALE-R2, SCALE-R3, SCALE-R4, SCALE-R5, SCALE-R6
- Note: clean: SERIAL keys are ample at about 110,000 bookings a year; no counters, replicas, or serverless deployment.

## Remediation plan

<!-- BEGIN GENERATED: plan (score.sh --write) -->
- Quick wins (Critical or High, not Suspected, effort S): none
- Plan now (Critical or High, not Suspected, effort M or L), in this order: TYPES-001, CONSTRAINTS-001
- Verify first (Suspected; confirm against the code before acting): SEARCH-001
- Schedule (Medium): INDEX-001
- Backlog (Low): none
<!-- END GENERATED: plan -->

## Scope and limitations

Read all six files. The DATABASE_URL (connection role, TLS mode, statement timeout), backups, and real row counts are outside the repository and were not assessed. INDEX-001 assumes the README's volume; SEARCH-001 needs a row count and an EXPLAIN ANALYZE to confirm. No database was connected.

## How to use this report (for the acting agent)

1. Triage by severity and confidence. Confirmed Critical and High findings are safe to act on now, in the order under "What to fix first". Re-verify every Suspected finding against the cited code before changing anything.
2. Confirm the stated assumption on Likely findings before acting.
3. Fix root causes first: prefer a systemic pattern's root fix over its individual members.
4. Preserve the strengths; do not refactor them away while fixing something else.
5. Apply every schema change with the lock-safe path: CREATE INDEX CONCURRENTLY, ADD CONSTRAINT ... NOT VALID then VALIDATE, expand-contract for renames and type changes, and batched backfills, so the fix does not cause the outage; never drop a working constraint, index, or generated column to make another fix easier.
6. One finding, one change, verified: after each fix, run its "Verify the fix" step and keep the change traceable to the finding ID.
7. Do not widen scope silently; note adjacent issues instead of sprawling into a rewrite.
8. Re-run the audit to measure progress: confirm findings are resolved, not relocated, and that the strengths did not regress.
