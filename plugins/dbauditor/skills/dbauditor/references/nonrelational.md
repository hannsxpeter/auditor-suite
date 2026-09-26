# Non-relational and analytics stores

Read this when inventory.sh or the code shows a document, key-value, wide-column, search-engine, vector, warehouse, or time-series store. It is a lens, not a scored dimension: file every finding under the scored dimension named after each check, with the card ID when one fits (for example `SCALE-003` for a MongoDB array that grows without bound), and name the store in the title.

## Calibrate first

- Denormalization and duplication are correct in document stores, wide-column stores, and warehouses. Do not file SCHEMA-R1, SCHEMA-R6, or INTEGRITY-R1 against a design that embeds or copies on purpose.
- In document and key-value stores the real risks are documents that grow without bound, hot partitions, and access patterns that the keys and indexes do not model.
- In warehouses, wide denormalized marts are the intended design; the risks are grain, pruning, and untested assumptions about uniqueness and relationships.
- Write the paradigm (OLTP, document or key-value, warehouse, time-series, or mixed) on the Calibration line.

## MongoDB (also apply the matching checks to Firestore, Couchbase, and Cosmos DB for NoSQL)

- An embedded array that grows without bound (`$push` with no `$slice`, no bucketing) toward the 16 MB document limit: SCALE.
- An independently queried or shared entity embedded instead of referenced, so updates must touch many documents: SCHEMA.
- A filter or sort on a field with no index (a collection scan): INDEX. A compound index must follow Equality, Sort, Range order: INDEX-R3.
- A collection with no `$jsonSchema` validator, or one at `validationLevel: "moderate"` or `validationAction: "warn"` (advisory only), letting field types drift: CONSTRAINTS.
- Mongoose `unique: true` is not a validator: it only builds a unique index, and only when index builds run (they are often disabled in production). Check that the index exists: CONSTRAINTS-R1.
- Operator injection from request JSON (`{"$gt": ""}`, `$where`, `$function`): DBSEC-R1.
- Several documents changed together without a transaction (multi-document transactions need a replica set): TXN-R2.
- Authorization disabled or the server bound to a public interface: DBSEC-R3.

## DynamoDB (also apply the partition-key checks to Cosmos DB)

- A relational multi-table model with joins done in application code, instead of designing keys from the access patterns: SCHEMA.
- A low-cardinality or monotonic partition key (a status, a date, a constant) that creates a hot partition: SCALE.
- A `Scan` with a `FilterExpression` on a routine read path: QUERY.
- A GSI whose key schema does not serve the query (it falls back to Scan), or a `KEYS_ONLY` projection that forces a second `GetItem` per result: INDEX.
- A read that must be strongly consistent served from a GSI (GSIs are eventually consistent only): TXN.
- Writes that must not repeat done without a condition expression (`attribute_not_exists`) or a transaction: TXN-R3.
- An item that grows toward the 400 KB item limit, or an item collection that grows without bound on a table with a local secondary index (10 GB per partition key value): SCALE.

## Cassandra and ScyllaDB

- A partition that grows forever (`PRIMARY KEY (user_id, ts)` holding every event of a user): SCALE.
- `ALLOW FILTERING`, or a secondary index on a high-cardinality column, which fans out to the whole cluster: QUERY.
- A queue-like or delete-heavy table accumulating tombstones past the failure threshold (reads start failing): SCALE.

## Redis

- Keys written with no TTL while `maxmemory-policy` is `noeviction`: writes fail when memory fills: SCALE.
- An ever-growing collection key (a big key) that blocks the single-threaded event loop on read or delete: SCALE.
- Redis used as the only system of record for durable data, with no AOF persistence and no upstream source of truth: SCALE (backup and durability posture).
- No `requirepass` or ACLs, or `protected-mode no` on a reachable interface: DBSEC-R3.

## Search engines and vector stores (Elasticsearch, OpenSearch, Meilisearch, Typesense, Algolia, pgvector, Pinecone, Weaviate, Qdrant, Milvus)

- Sync from the database by dual writes or a nightly rebuild: SEARCH-R3.
- Queries without the tenant or permission filter: SEARCH-R5.
- Missing ANN index or a distance metric that does not match the index: SEARCH-R4.

## Warehouses and dbt (Snowflake, BigQuery, Redshift, ClickHouse, DuckDB, Databricks)

- Clustering keys, sort and distribution keys, and partition pruning are the warehouse form of indexing: a large table filtered on a column that is neither partitioned nor clustered: INDEX.
- Fact and dimension grain undefined or mixed, and slowly changing dimensions handled with no strategy: SCHEMA. Wide denormalized marts are correct: never a finding by themselves.
- Declared keys that the warehouse does not enforce (Snowflake enforces only NOT NULL; BigQuery and Redshift keys are informational), with no dbt `unique`, `not_null`, `relationships`, or `accepted_values` tests on the columns the models rely on: CONSTRAINTS.
- An incremental dbt model with no `unique_key`, or with no handling of late-arriving data (no lookback in the `is_incremental()` filter), so reruns duplicate or miss rows: CONSTRAINTS.
- Materialization chosen without regard to cost (a view recomputing a huge join on every read, a full table rebuild where incremental fits) and no source freshness checks: SCALE.
- SQL built in Jinja from an untrusted variable: DBSEC-R1.

## Time-series (TimescaleDB, InfluxDB, Prometheus)

- Hypertable chunk intervals, continuous aggregates, and compression and retention policies missing on a growing series: SCALE.
- High-cardinality tags or labels (a user ID, request ID, or URL as a label), the classic cause of time-series outages: SCALE.
