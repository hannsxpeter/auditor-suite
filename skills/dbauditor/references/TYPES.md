# TYPES: Data Types and Storage Efficiency

Weight 7. Always active. Floor dimension: one Critical finding here holds the overall score at 69.
Owns: physical type correctness: money types (the owner for float money), date and time types, UUID and key storage, booleans, JSON and binary storage, character sets and string sizing, and sentinel values.
Not here: a 32-bit key that will run out on a high-churn table (SCALE-R1); a foreign key whose type differs from its parent (INTEGRITY-R5); how a state column is modeled (SCHEMA-R5); how to change a type without locking (MIGRATION-R2).
Standards: SQL Antipatterns (Karwin), PostgreSQL wiki "Don't Do This", PostgreSQL and MySQL data type docs, RFC 9562.
Read first: the column types in the final DDL (the migrations or schema dump, never the model alone), then the code that computes and writes money and time values.

## Cards

### TYPES-R1 Money stored in a binary floating-point type (quick)
- Leads: `scan.sh TYPES-R1` lists money-named columns declared as float, double, or real, and DECIMAL columns with no scale.
- Confirm: a column holding money (`price`, `amount`, `total`, `balance`, `cost`, `fee`, `tax`, `discount`) is `FLOAT`, `REAL`, `DOUBLE PRECISION`, ORM `Float`, `:float`, `FloatField`, or `DataTypes.FLOAT` or `DOUBLE` in the shipped DDL (Knex `float()` creates `real` in PostgreSQL); or a `DECIMAL` with no scale on an engine that defaults the scale to 0 (MySQL `DECIMAL(10,0)`, SQL Server `DECIMAL(18,0)`), which drops the cents. A model that declares `Decimal` over a `FLOAT` column is still float. SQLite stores fractional DECIMAL values as floats (facts.md).
- Not a finding if: the value is not money (ratios, scores, coordinates, measurements); it is an approximate analytics metric documented as such; PostgreSQL `NUMERIC` with no precision (it keeps any scale).
- Severity: Critical for balances, prices, payments, invoices, ledgers, and order totals; High for money in reports; Medium for money copied into logs or analytics.
- Fix: `NUMERIC(p, s)` sized for the largest amount and the currency's minor units (for example `NUMERIC(19, 4)`), or integer minor units (`amount_cents BIGINT`), plus a currency column when more than one currency exists; compute in a decimal type in the app too. The type change rewrites the table: on a large table add a new column, dual-write, backfill in batches, then swap (MIGRATION-R2).
- Verify the fix: the catalog shows `numeric` for every money column, and a test that adds 0.10 and 0.20 stores exactly 0.30.
- Refs: CWE-1339; SQL Antipatterns "Rounding Errors"

### TYPES-R2 Dates and times stored in the wrong type
- Leads: `scan.sh TYPES-R2` lists time-named columns declared as text or integers and PostgreSQL `timestamp` columns without a time zone.
- Confirm: an instant (`created_at`, `occurred_at`, `expires_at`, `paid_at`) is stored as `VARCHAR` or `TEXT`; as a 32-bit epoch integer (it overflows on 2038-01-19); as MySQL `TIMESTAMP` when stored dates can pass 2038-01-19 (its range ends there); or as PostgreSQL `timestamp` without time zone while more than one time zone, raw SQL `now()` in a non-UTC session, or another service writes it. Or a wall-clock concept (a birthdate, a shop's opening hour) is stored as `timestamptz`.
- Not a finding if: one framework writes every value in UTC and nothing else writes the column (then Low: note it); a `date` column holds a calendar date.
- Severity: High when the value drives billing periods, expirations, legal records, or scheduling across time zones, or stored dates can already pass 2038; Medium otherwise; Low for framework-managed UTC `timestamp` columns.
- Fix: `timestamptz` for instants with a UTC write path, `date` for calendar dates, `time` plus a zone name for wall-clock schedules, 64-bit epochs or `DATETIME` beyond 2038. The type change rewrites the table (MIGRATION-R2).
- Verify the fix: the catalog shows `timestamp with time zone` for instants, and a test writing from two time zones reads back one instant.
- Refs: PostgreSQL wiki, Don't Do This; MySQL docs, The DATE, DATETIME, and TIMESTAMP Types

### TYPES-R3 UUID stored as text, or random UUIDs as a clustered primary key
- Leads: `scan.sh TYPES-R3` lists 36-character string keys and random UUID generators.
- Confirm: UUIDs are stored as `VARCHAR(36)` or `CHAR(36)` (or Prisma `String @default(uuid())` without `@db.Uuid`) instead of native `uuid` or `BINARY(16)`, costing about 20 extra bytes per row and per index entry; or a random UUIDv4 is the primary key of a high-insert table, spreading inserts across the whole index (page splits, cache misses, index bloat), worst on MySQL InnoDB where the primary key orders the rows.
- Not a finding if: the table is low-insert; the key is UUIDv7, ULID, or a `BIGINT` identity, with v4 only in a non-key public column.
- Severity: High for random UUIDv4 primary keys on the hottest insert tables in InnoDB; Medium otherwise; Low for text UUIDs on small tables.
- Fix: native `uuid` (PostgreSQL) or `BINARY(16)` (MySQL); time-ordered keys (UUIDv7, `uuidv7()` in PostgreSQL 18, ULID) or `BIGINT GENERATED ALWAYS AS IDENTITY`. Key changes are large migrations: plan expand-contract (MIGRATION-R3).
- Verify the fix: the catalog shows `uuid` columns, and index size grows in step with row count.
- Refs: RFC 9562; MySQL docs, Clustered and Secondary Indexes

### TYPES-R4 Flags, JSON, and binary data in the wrong type
- Leads: `scan.sh TYPES-R4` lists string flags, plain `json` columns, and binary columns.
- Confirm: a boolean is a `VARCHAR` (`'Y'` and `'N'`) or an unconstrained integer; JSON that queries filter inside is stored as `TEXT` or PostgreSQL `json` (no GIN index, reparsed on every read); large files sit inline in `BLOB` or `bytea` columns of a hot table instead of object storage with a key; or rows are so wide that values move out of line (PostgreSQL TOAST) and even narrow scans pay extra reads.
- Not a finding if: the JSON is stored and returned whole, never filtered; the binary values are small (hashes, tiny thumbnails).
- Severity: High when inline blobs sit in a hot table; Medium otherwise.
- Fix: `boolean`; `jsonb` with a GIN index where queried; object storage with a key column for files.
- Verify the fix: the catalog shows the new types, and the hot table's size and scan time drop.
- Refs: PostgreSQL docs, JSON Types and TOAST

### TYPES-R5 Character set or string sizing that corrupts or wastes text
- Leads: `scan.sh TYPES-R5` lists `utf8` and `latin1` character sets and fixed-width `CHAR` columns.
- Confirm: MySQL tables, columns, the server, or the connection use `utf8` (the 3-byte `utf8mb3` alias) or `latin1` for user text, so 4-byte characters (emoji, some CJK) are rejected or truncated; a `CHAR(n)` holds variable-length data and its space padding breaks equality and LIKE; or `VARCHAR(255)` applied to every string pushes composite index keys past the key size limit under `utf8mb4` (255 characters is up to 1,020 bytes).
- Not a finding if: `utf8mb4` is set for the server, tables, columns, and connection; `CHAR(n)` holds fixed-length codes (ISO country or currency codes).
- Severity: High when user text is truncated or rejected; Medium otherwise.
- Fix: convert to `utf8mb4` (a table rebuild: plan it as MIGRATION-R2) and set `charset=utf8mb4` on the connection; size `VARCHAR` to the domain.
- Verify the fix: a test stores and reads back a 4-byte emoji unchanged.
- Refs: MySQL docs, The utf8mb4 Character Set

### TYPES-R6 Sentinel values used instead of NULL
- Leads: `scan.sh TYPES-R6` lists sentinel defaults such as '1970-01-01', '9999-12-31', '0000-00-00', empty strings, and -1.
- Confirm: "no value" is stored as a magic value (`''`, `'1970-01-01'`, `'0000-00-00'`, `'9999-12-31'`, `-1`) that aggregates and comparisons treat as data (an average age dragged down by -1, an expiry filter that never matches).
- Not a finding if: every query excludes the sentinel and it is documented; it is a deliberate open range bound used consistently (PostgreSQL `'infinity'`). Oracle stores `''` as NULL.
- Severity: Medium when aggregates or filters read the column; Low otherwise.
- Fix: make the column nullable (or model the state explicitly) and convert sentinels to NULL in batches.
- Verify the fix: a count of rows holding the sentinel returns 0 after the migration.
- Refs: SQL Antipatterns "Fear of the Unknown"

## Also check
- Integer keys sized wrong: `BIGINT` where a small lookup table fits `SMALLINT` (an `INT` key that will pass 2.1 billion is SCALE-R1).

## Paper controls (look protective, protect nothing)
- A model declaring `Decimal`, `Boolean`, or `UUID` while the migration created `VARCHAR` or `FLOAT`: verify the DDL, not the model.
- `utf8mb4` on the tables while the driver connection still negotiates `utf8` or `latin1`.
- A `DECIMAL` scale too small for intermediate results (tax rates, currency conversion, interest) even though the stored amount fits.
- A `BINARY(16)` UUID converted to and from a 36-character string on every query, or compared through a conversion on the column side (`BIN_TO_UUID(id) = ?`), which defeats the index.
- `DEFAULT now()` on a PostgreSQL `timestamp` without time zone marketed as auditing: it stores the session's local time.
