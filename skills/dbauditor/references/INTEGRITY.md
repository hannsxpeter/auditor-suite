# INTEGRITY: Referential Integrity and Relationships

Weight 14. Always active.
Owns: whether relationships between rows are enforced by the database: foreign keys, their validation state, ON DELETE and ON UPDATE rules, junction tables, soft-deleted parents with live children, and references that cross a database or service boundary.
Not here: the index on a foreign key column (INDEX-R1); uniqueness (CONSTRAINTS); packed lists of IDs in one column and polymorphic pairs (SCHEMA-R1, SCHEMA-R3); the unique index on a soft-delete table (CONSTRAINTS-R2); how to add a constraint without locking (MIGRATION-R2).
Standards: SQL Antipatterns (Karwin), PostgreSQL, MySQL, SQL Server, and SQLite foreign key docs.
Read first: every migration or schema dump that creates or alters a table, the ORM association declarations, and every code path that deletes rows.

## Cards

### INTEGRITY-R1 Reference column with no foreign key in the shipped DDL (quick)
- Leads: `scan.sh INTEGRITY-R1` lists `*_id` column declarations and ORM settings that emit no foreign key; search the migrations for a foreign key on each column.
- Confirm: a column that holds another table's key (`customer_id`, `parent_id`, `orderId`) has no `REFERENCES`, `FOREIGN KEY`, `.references()`, `foreign_key: true`, `ForeignKey(...)`, or `->constrained()` in any migration or schema dump, so only an ORM association (`belongs_to`, `relationship()`, `@ManyToOne`) links the rows. Laravel `foreignId()` without `->constrained()` and Rails `t.references` without `foreign_key: true` create the column only; Prisma with `relationMode = "prisma"` emits no foreign keys at all.
- Not a finding if: a later migration adds the key (search every migration for the column); the parent lives in another database or service (INTEGRITY-R8); the platform cannot enforce foreign keys and a scheduled orphan check exists (cite it).
- Severity: Critical when the child holds financial or audit rows (payments, ledger lines, invoices, audit events) and a delete path or a second writer can orphan them; High for other core tables; Medium for disposable tables.
- Fix: delete or repair orphans, then add the key with an explicit ON DELETE rule. PostgreSQL on a large table: `ADD CONSTRAINT payments_order_fk FOREIGN KEY (order_id) REFERENCES orders (id) NOT VALID`, then `VALIDATE CONSTRAINT` in a separate migration. MySQL rules are in references/facts.md.
- Verify the fix: `SELECT count(*) FROM child c LEFT JOIN parent p ON p.id = c.parent_id WHERE c.parent_id IS NOT NULL AND p.id IS NULL` returns 0, and `pg_constraint.convalidated` is true.
- Refs: SQL Antipatterns "Keyless Entry"; PostgreSQL docs, Foreign Keys

### INTEGRITY-R2 ON DELETE CASCADE reaches financial, audit, or other rows that must survive (quick)
- Leads: `scan.sh INTEGRITY-R2` lists cascade rules in the DDL and the ORM.
- Confirm: a cascade (`ON DELETE CASCADE`, `onDelete: Cascade`, `on_delete=models.CASCADE`, `dependent: :destroy`, `CascadeType.REMOVE`) runs from a parent that code or users can delete to rows that must outlive it (orders, invoices, payments, ledger lines, audit rows), directly or through a chain. Follow the chain two or three levels.
- Not a finding if: the children are disposable (sessions, tokens, join rows, cart lines, drafts); the parent is never hard-deleted (cite the absence of a delete path); the cascade is the documented erasure path and the rows are archived first.
- Severity: Critical when a user-reachable or routine delete can remove financial or audit rows; High when only an admin or maintenance path can; Medium for other valuable data.
- Fix: `ON DELETE RESTRICT` (or `SET NULL` for optional links) and an app-managed delete that archives first; keep CASCADE for disposable children. Changing the rule means dropping and re-adding the key: use `NOT VALID` then `VALIDATE` on a large table.
- Verify the fix: a test that deletes a parent with financial children fails with a foreign key violation.
- Refs: PostgreSQL docs, Foreign Keys (referential actions)

### INTEGRITY-R3 Foreign key declared but not enforced or not trusted (quick)
- Leads: `scan.sh INTEGRITY-R3` lists NOT VALID, NOT ENFORCED, WITH NOCHECK, MyISAM, FOREIGN_KEY_CHECKS, and SQLite connections.
- Confirm: the key exists but does not hold: PostgreSQL `NOT VALID` with no later `VALIDATE CONSTRAINT` (new writes are checked, existing orphans never are) or `NOT ENFORCED` (PostgreSQL 18); SQL Server `WITH NOCHECK` (untrusted, `is_not_trusted = 1`); a MySQL table on `ENGINE=MyISAM` (foreign keys are parsed and ignored); `SET FOREIGN_KEY_CHECKS=0` left in a load or seed script that runs against production; SQLite without `PRAGMA foreign_keys = ON` on every connection (off by default, per connection).
- Not a finding if: a later migration validates or re-enables it; the unchecked load runs only against an empty or test database (cite where it runs).
- Severity: as INTEGRITY-R1, because the relationship is not enforced.
- Fix: repair orphans, then `VALIDATE CONSTRAINT` (SQL Server `WITH CHECK CHECK CONSTRAINT`); move MyISAM tables to InnoDB; remove the global `FOREIGN_KEY_CHECKS=0`; set the SQLite pragma in the connection setup.
- Verify the fix: the orphan count is 0 and the catalog shows the key validated or trusted.
- Refs: PostgreSQL docs, ALTER TABLE; SQL Server docs, WITH CHECK; SQLite docs, Foreign Key Support

### INTEGRITY-R4 Delete behavior defined only in the ORM, or undefined for a parent the code deletes
- Leads: `scan.sh INTEGRITY-R4` lists ORM cascade options and SQL deletes.
- Confirm: the ORM declares the delete rule (`dependent: :destroy`, `cascade="all, delete-orphan"`, JPA `CascadeType.REMOVE`, Prisma `onDelete` under `relationMode = "prisma"`) while the DDL has a plain key with no ON DELETE, so bulk SQL, jobs, and other services get errors or leave children; or code hard-deletes a parent whose key has no ON DELETE rule and the path never removes the children first, so the delete fails at runtime.
- Not a finding if: the DDL carries the same rule; one ORM path is the only writer (then Low).
- Severity: High when a user-facing delete (account or project deletion) fails or leaves children; Medium otherwise.
- Fix: declare `ON DELETE CASCADE`, `SET NULL`, or `RESTRICT` per child in the migration, matching the model's intent.
- Verify the fix: a test deletes a parent with raw SQL and the child outcome (removed, nulled, or blocked) matches the model.
- Refs: PostgreSQL docs, Foreign Keys; Rails guides, Active Record Associations

### INTEGRITY-R5 Foreign key column type, size, or collation differs from the referenced key
- Leads: `scan.sh INTEGRITY-R5` lists foreign key declarations; read the referenced key's type for each.
- Confirm: the child column differs from the parent key in type, width, signedness, or collation: `user_id INT` referencing a `BIGINT` key, `uuid` against `varchar(36)`, `INT` against `INT UNSIGNED`, `utf8mb4_general_ci` against `utf8mb4_0900_ai_ci`, or a parent key migrated to `BIGINT` while the referencing column stayed `INT`. MySQL refuses such keys (errno 150), so also check that the key exists (INTEGRITY-R1).
- Not a finding if: a later migration aligned both sides.
- Severity: High when the parent key can pass 2,147,483,647 while the child is `INT` (inserts will fail) or the mismatch forces a cast on a hot join; Medium otherwise.
- Fix: convert the child to the parent's exact type and collation through expand-contract (new column, dual-write, batched backfill, swap; see MIGRATION-R2).
- Verify the fix: the catalog shows identical types and collation; the join plan uses the index without a cast.
- Refs: MySQL docs, FOREIGN KEY Constraints; PostgreSQL docs, Foreign Keys

### INTEGRITY-R6 Junction table without a composite key or without a foreign key on each side
- Leads: `scan.sh INTEGRITY-R6` lists many-to-many declarations and join tables.
- Confirm: a join table lacks `PRIMARY KEY (a_id, b_id)` or a unique constraint on the pair, or lacks a foreign key on either side, so duplicate and orphan links are possible.
- Not a finding if: the pair is unique through another constraint; duplicates carry meaning by design and are documented.
- Severity: High when the links grant access (user_roles, team_members, permissions); Medium otherwise.
- Fix: deduplicate, add the composite key (build the unique index concurrently, then attach it) and a foreign key on each side.
- Verify the fix: `SELECT a_id, b_id FROM link GROUP BY 1, 2 HAVING count(*) > 1` returns no rows and a duplicate insert fails.
- Refs: SQL Antipatterns "Jaywalking" (the junction-table fix)

### INTEGRITY-R7 Soft-deleted parent still satisfies the foreign key of live children
- Leads: `scan.sh INTEGRITY-R7` lists soft-delete columns and scopes.
- Confirm: a parent is soft-deleted (`deleted_at`, `is_deleted`, `paranoid`, `acts_as_paranoid`, `SoftDeletes`), app queries hide it, and its live children still point at it because nothing cascades the soft delete, so children of a gone parent appear in lists, totals, or permission checks.
- Not a finding if: the soft delete cascades in the same transaction or by trigger (cite it); the children are history that must keep pointing at a retired parent (order lines of a discontinued product); every child query joins the parent's filter.
- Severity: High when the children grant access or money (members of a deleted organization, subscriptions of a deleted account); Medium otherwise.
- Fix: cascade the soft delete in one transaction, or stop soft-deleting rows that other rows reference and archive them instead. This is the dangling-children part of soft delete; the unique-index part is CONSTRAINTS-R2 and the design choice is SCHEMA.
- Verify the fix: after a parent is soft-deleted, a count of live children of soft-deleted parents is 0.
- Refs: none (design practice)

### INTEGRITY-R8 Cross-database or cross-service reference with no reconciliation
- Leads: no search pattern; read the Map's cross-service links and each `*_id` column whose parent lives in another database or service.
- Confirm: a column stores a key owned by another database or service (`account_id` from an identity service, `other_db.table`), a foreign key cannot span the boundary, and nothing reconciles it: no consumer of the owner's delete events, no outbox or CDC, no scheduled orphan check.
- Not a finding if: a delete-event consumer or an orphan-check job exists (cite it).
- Severity: High when a dangling reference affects money or access; Medium otherwise.
- Fix: consume the owner's delete events through a durable outbox or CDC, and add a scheduled orphan check that alerts.
- Verify the fix: the orphan check runs in the scheduler, and deleting a row in the owning service updates the local rows.
- Refs: Designing Data-Intensive Applications (Kleppmann), ch. 11

## Also check
- A mandatory relationship modeled with a nullable foreign key, allowing parentless rows: `NOT NULL`, and nullable only for optional links with `ON DELETE SET NULL`.
- A MySQL foreign key that points at a non-unique column while the code treats the link as one-to-one.
- Right-to-erasure (GDPR, CCPA) that soft-deletes the primary row but leaves copies in denormalized columns, caches, search indexes, and logs (the plaintext storage itself is DBSEC-R5).

## Paper controls (look protective, protect nothing)
- A PostgreSQL foreign key `NOT VALID` never validated, or `NOT ENFORCED`: it looks like a constraint and checks nothing already stored.
- A SQL Server foreign key enabled but untrusted after `WITH NOCHECK`.
- A MySQL foreign key on a MyISAM table, or `FOREIGN_KEY_CHECKS=0` left in a load script.
- SQLite foreign keys declared while `PRAGMA foreign_keys = ON` is never issued per connection.
- A cascade declared in the ORM (`dependent: :destroy`, `cascade="all, delete-orphan"`, Prisma `onDelete` under `relationMode = "prisma"`) that no other writer sees.
