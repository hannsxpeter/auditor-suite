# RAG: Retrieval, RAG, Indexing and Vector Search

Weight 7. Active when embeddings or a vector store exist.
Owns: the embeddings lifecycle and vector-space consistency, the distance metric, index freshness and re-embedding, chunking, provenance from ingestion into the prompt, retrieval quality, and query-document asymmetry.
Not here: per-user and per-tenant retrieval filters (LLMSEC-R7); injection through retrieved content (LLMSEC-R1); retrieval evals (EVAL-R5); embeddings requested one text at a time (SPEED-R2); the general model-pinning rule (MODEL-R1).
Standards: OWASP LLM08:2025, LLM04:2025, embedding and vector-store documentation (references/facts.md).
Read first: the ingestion path (chunk, embed, upsert, delete), the query path (embed, search, rerank, prompt assembly), and the index or table definition.

## Cards

### RAG-R1 Queries and documents embedded in different vector spaces (quick)
- Leads: `scan.sh RAG-R1` lists embedding calls and embedding model settings.
- Confirm: ingestion and query call different embedding models, output dimensions, or providers; or an `EMBEDDING_MODEL` constant is read only by ingestion while the query path hardcodes another; or the model changed with no re-embed, so the index mixes two models' vectors.
- Not a finding if: both paths call one shared embedding function with one model and dimension (read both); the index records its model and queries refuse a mismatch.
- Severity: Critical when the mismatch is live: similarity is meaningless, retrieval silently returns near-random chunks, and answers still look plausible. If only the next model change would cause it, file RAG-R3.
- Fix: one embedding function with one pinned model and dimension for both paths; store the model id with the index and check it at query time.
- Verify the fix: one embedding call site serves ingestion and query, and a startup check compares the index's stored model with the query model.
- Refs: OWASP LLM08:2025

### RAG-R2 Distance metric or normalization does not match the embedding model
- Leads: `scan.sh RAG-R2` lists distance operators, operator classes, and metric settings.
- Confirm: the index metric (L2, inner product, cosine) differs from the model's documented one; inner product runs on unnormalized vectors; only one side is normalized; or, in pgvector, the query operator does not match the index operator class, so the index is skipped and every query scans the table.
- Not a finding if: vectors are unit-normalized on both sides (the three metrics then rank alike) and the operator matches the index.
- Severity: High when it changes rankings or forces full scans on the live path. Medium otherwise.
- Fix: use the model's documented metric, normalize both sides for inner product, and match the query operator to the index operator class.
- Verify the fix: `EXPLAIN` shows the vector index in use, and a labeled query returns its expected chunk first.
- Refs: references/facts.md (pgvector operators)

### RAG-R3 Index can go stale: no update or delete path, no stored model version
- Leads: `scan.sh RAG-R3` lists reindex, upsert, and delete code and model-version fields.
- Confirm: edits and deletions in the source of truth never update or remove their vectors; the embedding model and dimension are not stored with the index, so a model change has no migration; a reindex script exists but nothing runs it; or the embedding model is deprecated (facts.md).
- Not a finding if: upserts and deletes keyed by document ID run on every change, and the model version is stored and checked.
- Severity: High when deleted or permission-changed documents stay retrievable, or the embedding model is being retired. Medium otherwise.
- Fix: upsert and delete vectors on every source change, keyed by document ID; store the model and version with each vector; write a re-embed migration for model changes.
- Verify the fix: a test deletes a document and retrieval no longer returns its chunks.
- Refs: OWASP LLM08:2025

### RAG-R4 Chunking ignores structure or exceeds the embedding input limit
- Leads: `scan.sh RAG-R4` lists chunk sizes, overlaps, and splitters.
- Confirm: fixed-size slicing that ignores headings, paragraphs, code, and tables, with no overlap; or chunks longer than the embedding model's input limit, which some providers truncate silently, so each chunk's tail is never searchable.
- Not a finding if: a structure-aware splitter with modest overlap keeps chunks under the model limit.
- Severity: Medium. High when chunks exceed the limit.
- Fix: a structure-aware splitter with modest overlap, and a chunk size under the limit with headroom.
- Verify the fix: a test over a long fixture document shows every chunk under the token limit and split at structure boundaries.
- Refs: embedding model documentation

### RAG-R5 Retrieved chunks carry no source or provenance
- Leads: no reliable pattern; read where retrieved chunks are joined into the prompt (the `scan.sh LLMSEC-R1` leads) and the ingestion code.
- Confirm: chunks enter the prompt with no document ID, title, page, or chunk ID, so answers cannot be cited or checked; or untrusted content (scraped pages, uploads, forum posts) is stored with no record of who added it, from where, and when.
- Not a finding if: source metadata travels from ingestion through retrieval into the prompt and the answer, and ingestion records provenance.
- Severity: Medium. High when answers must be cited (policy, legal, medical) or the corpus accepts untrusted uploads.
- Fix: carry source IDs through retrieval into the prompt and the answer, and record provenance at ingestion.
- Verify the fix: the rendered prompt shows a source ID beside each chunk, and answers cite IDs that exist.
- Refs: OWASP LLM04:2025

### RAG-R6 Retrieval returns junk without noticing
- Leads: `scan.sh RAG-R6` lists top-k settings, thresholds, rerankers, and hybrid search.
- Confirm: pure dense retrieval over a corpus full of exact identifiers (SKUs, error codes, names) with no lexical or BM25 channel; a reranker whose order is never used; top-k at an extreme (flooding the window, or 1 or 2 with no recall headroom); or no relevance threshold and no empty-result branch, so the model answers from irrelevant chunks.
- Not a finding if: hybrid retrieval, an applied reranker, and a threshold with an explicit "no relevant documents" answer exist, or an eval justifies the settings.
- Severity: Medium. High when wrong retrieval drives user-facing answers that must be accurate.
- Fix: hybrid retrieval with rank fusion for identifier-heavy corpora, the reranker's order applied, k tuned against the eval, and a threshold with an explicit empty-result answer.
- Verify the fix: a query with no relevant documents gets the empty-result answer, and an identifier query returns the exact match first.
- Refs: none

### RAG-R7 Query and document embeddings ignore the model's required asymmetry
- Leads: `scan.sh RAG-R7` lists input-type, task-type, and prefix settings.
- Confirm: the embedding model needs different input types or prefixes for queries and documents (facts.md lists common ones), and the code sets none, the same one on both sides, or swaps them.
- Not a finding if: the model is symmetric by design (check its documentation).
- Severity: Medium. High when recall drops on the main retrieval path.
- Fix: set the documented query and document options per side inside the one embedding function.
- Verify the fix: the query and ingestion calls carry different settings in a request log or unit test.
- Refs: references/facts.md (embeddings)

## Also check
- Approximate-index parameters (IVF lists and probes, HNSW m and ef_search) left at low-recall defaults whatever the corpus size.
- Near-duplicate chunks retrieved together, crowding out the rest of the context.

## Paper controls (look protective, protect nothing)
- An `EMBEDDING_MODEL` constant read only by ingestion while the query path hardcodes another model.
- A hybrid or BM25 path built while the retriever still calls only the vector search.
- Rerank scores computed and then discarded.
- A `score_threshold` of 0.0 that never filters anything.
- A reindex script that no deploy step or schedule runs.
