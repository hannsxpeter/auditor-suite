# SEARCH: Search and Text Retrieval

Weight 4. Active when a search or text-retrieval surface exists.
Owns: how the product finds rows by text or similarity: substring, full-text, fuzzy, prefix, faceted, JSON-path, and vector retrieval; ranking; the sync of external search indexes; and whether search results respect tenant and permission boundaries.
Not here: a leading-wildcard LIKE that backs no search feature (QUERY-R4); index type for jsonb or arrays outside a search feature (INDEX-R4); a case-insensitive equality lookup such as sign-in by email (INDEX-R5); injection through the search term (DBSEC-R1).
Standards: PostgreSQL full-text search and pg_trgm docs, MySQL full-text docs, pgvector docs, SQL Antipatterns "Poor Man's Search Engine", Designing Data-Intensive Applications (Kleppmann), ch. 11.
Read first: every search endpoint and the query it builds, the indexes on the searched columns, and the code that writes to any external search engine or vector store.

## Cards

### SEARCH-R1 Substring search with a leading wildcard and no trigram or full-text index
- Leads: `scan.sh SEARCH-R1` lists LIKE and ILIKE with a leading `%`, `contains` filters, and insensitive modes.
- Confirm: a search feature filters with `LIKE '%term%'`, `ILIKE`, Django `icontains`, Prisma `contains` (with or without `mode: 'insensitive'`), or Sequelize `Op.substring` or `Op.iLike` over a large or growing table, and no `pg_trgm` GIN or GiST index (or full-text index) covers that column, so every search scans the table.
- Not a finding if: a trigram index exists on the same column with `gin_trgm_ops`; the table is small by nature; an admin tool runs the search a few times a day (then Low).
- Severity: High on a public or hot search path over a growing table; Medium otherwise. Use Suspected when the code does not show the table size, and name the row count or EXPLAIN that would confirm it.
- Fix: `CREATE EXTENSION pg_trgm;` then `CREATE INDEX CONCURRENTLY products_name_trgm_idx ON products USING gin (name gin_trgm_ops);`, or move to full-text search (SEARCH-R2).
- Verify the fix: EXPLAIN of the search shows a bitmap index scan on the trigram index.
- Refs: SQL Antipatterns "Poor Man's Search Engine"; PostgreSQL docs, pg_trgm

### SEARCH-R2 Full-text search emulated, unindexed, or unranked
- Leads: `scan.sh SEARCH-R2` lists tsvector, full-text, MATCH AGAINST, similarity, and ranking calls.
- Confirm: the product's search chains `LIKE` or `OR` conditions per word (no stemming, stop words, or ranking) instead of full-text search (`tsvector @@ tsquery` with GIN, MySQL `MATCH ... AGAINST` on a FULLTEXT index, SQL Server `CONTAINS` or `FREETEXT`); or a `tsvector @@` query has no GIN index on the identical expression and text-search configuration; or results come back in arbitrary or `created_at` order with no relevance ranking (`ts_rank`, the MATCH score); or typo tolerance is promised with no similarity primitive (`pg_trgm` `similarity()` or `%`, Levenshtein).
- Not a finding if: the index expression and configuration match the query exactly (`to_tsvector('english', body)` on both sides) and results are ranked.
- Severity: High when it is the product's main search over a large table; Medium otherwise.
- Fix: a stored generated `tsvector` column with a GIN index, `websearch_to_tsquery` for user input, `ts_rank` ordering, and `pg_trgm` for fuzzy matching.
- Verify the fix: EXPLAIN uses the GIN index, and a test query returns the most relevant row first.
- Refs: PostgreSQL docs, Full Text Search; MySQL docs, Full-Text Search Functions

### SEARCH-R3 External search index kept in sync by dual writes
- Leads: `scan.sh SEARCH-R3` lists search-engine clients and indexing calls.
- Confirm: a handler writes the database and then the search engine (Elasticsearch, OpenSearch, Meilisearch, Typesense, Algolia) in the same request, so a failure between the two leaves the index stale and deletes may never reach it; or a nightly full rebuild is the only sync, with no delete propagation and a day-long stale window.
- Not a finding if: an outbox row written in the same transaction, or change data capture from the database log, drives indexing with retries, and a documented reindex exists (cite them).
- Severity: High when stale or deleted rows in results expose data that should be gone or drive money; Medium otherwise.
- Fix: a transactional outbox or CDC (Debezium, logical replication) feeding the indexer, idempotent upserts and deletes keyed by primary key, and a documented backfill and reindex.
- Verify the fix: a test that fails the index call after commit still converges, and deleting a row removes it from search.
- Refs: Designing Data-Intensive Applications, ch. 11 (dual writes, change data capture)

### SEARCH-R4 Vector search with no ANN index, or an index that does not match the distance operator
- Leads: `scan.sh SEARCH-R4` lists vector columns, distance operators, and ANN index builds.
- Confirm: an embedding column (`vector(n)` in pgvector) is queried by similarity with no `hnsw` or `ivfflat` index, so every query is a brute-force scan; or the index operator class does not match the query's operator (`vector_l2_ops` with a cosine `<=>` query cannot use it); or an IVFFlat index was built before the data was loaded (poor lists, poor recall).
- Not a finding if: the table is small enough for exact search and that is a stated choice.
- Severity: High when it is the main retrieval path at scale; Medium otherwise.
- Fix: `CREATE INDEX CONCURRENTLY ... USING hnsw (embedding vector_cosine_ops)` matching the query operator; build IVFFlat after loading, with lists sized to the row count.
- Verify the fix: EXPLAIN shows an index scan on the ANN index.
- Refs: pgvector README (indexing and operators)

### SEARCH-R5 Search returns rows the caller may not see (quick)
- Leads: `scan.sh SEARCH-R5` lists queries sent to search engines and vector stores.
- Confirm: tenant or permission filtering happens in the database (row-level security or scoped queries) while search results come from an external index or vector store that is queried without the tenant or permission filter, or whose documents do not carry the tenant field at all, so results include other tenants' or private records.
- Not a finding if: every search query adds the tenant or permission filter from the session in one wrapper (read it); each tenant has its own index, chosen from the session.
- Severity: Critical when another tenant's or another user's private data can appear in results; High when only internal or low-sensitivity data can leak.
- Fix: index the tenant and visibility fields, add a mandatory filter from the session in one search wrapper, or use per-tenant indexes.
- Verify the fix: a test as tenant A searching for a term that exists only in tenant B's data returns nothing.
- Refs: CWE-639, OWASP A01:2025

## Also check
- A case-insensitive search via `LOWER(col) = ...` with no expression index behind a search feature (outside search it is INDEX-R5).
- Accent-insensitive search attempted with `citext` alone: `citext` folds case, not accents; use `unaccent` wrapped in an IMMUTABLE function to index it, or a nondeterministic ICU collation.
- Faceted or multi-filter search served only by single-column indexes, or by a composite whose order ignores selectivity and the range filter.
- JSON path search (`data->>'k' = ?`, `@>`) behind a search feature over a large table with no expression or GIN index.

## Paper controls (look protective, protect nothing)
- A `tsvector` GIN index whose text-search configuration differs from the query's (`to_tsvector('english', body)` indexed, `to_tsvector(body)` queried): never used.
- A B-tree on the searched column cited as "search is indexed" while the search uses `LIKE '%x%'` or `ILIKE`.
- A nightly full reindex cited as the sync guarantee, with no delete propagation (SEARCH-R3).
- A vector index whose operator class does not match the query's operator (SEARCH-R4).
- Tenant filtering enforced in the database but not in the search engine (SEARCH-R5).
