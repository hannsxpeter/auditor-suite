# Answer key: dbauditor full-audit

Never copied into the eval workspace. Lines refer to files under repo/. The README states the scale that sets severity: PostgreSQL 15, orders about 40 million rows, order_items about 180 million, a public storefront that looks customers up by email, and a second writer (the checkout worker) on the payments table.

## Planted defects

| Grader | Location | Card | Expected severity | Defect |
|---|---|---|---|---|
| finds-float-total | migrations/20230105092000_create_orders.js:6 | TYPES-R1 | Critical | `orders.total` is `table.float()`, which Knex creates as `real` in PostgreSQL; every other money column is `decimal(12, 2)` |
| finds-payments-fk | migrations/20230105094000_create_payments.js:4 | INTEGRITY-R1 | Critical | `payments.order_id` has no foreign key; the nightly draft purge (`src/jobs/purge-drafts.js:18`) deletes orders and leaves their failed payment attempts orphaned, and the checkout worker writes the table too |
| finds-items-index | migrations/20230105093000_create_order_items.js:4 | INDEX-R1 | High | `order_items.order_id` references orders with no index; `GET /orders/:id` (`src/routes/orders.js:21`) and the purge's per-batch delete (`src/jobs/purge-drafts.js:17`) scan 180 million rows |
| finds-email-unique | src/services/accounts.js:5 and migrations/20230105090000_create_customers.js:4 | CONSTRAINTS-R1 | Critical | sign-in email uniqueness is a SELECT-then-INSERT in `createCustomer`; the migration has no unique constraint or index on `customers.email`, so concurrent sign-ups create duplicate identities |
| finds-credit-balance | src/services/credits.js:8 | TXN-R1 | Critical | `addCredit` reads `credit_balance`, adds in JavaScript, and writes the result back with no lock, version check, or atomic update: concurrent credits are lost |
| finds-lookup-sqli | src/routes/customers.js:10 | DBSEC-R1 | Critical | the sign-in lookup concatenates `req.query.email` into `db.raw` SQL |
| finds-index-lock | migrations/20240312100000_add_orders_status_created_at_index.js:3 | MIGRATION-R1 | Critical | `table.index()` on the existing 40-million-row orders table is a plain `CREATE INDEX` inside Knex's migration transaction: writes to orders block for the whole build |
| finds-offset-pages | src/routes/orders.js:13 | QUERY-R3 | High | `GET /orders` pages with OFFSET over all 40 million orders, and the ERP sync walks every page nightly |
| finds-sku-unique | migrations/20230105091000_create_products.js:10 | CONSTRAINTS-R2 | Medium | products are soft-deleted (`deleted_at`, line 8) but `sku` has a plain unique, so a retired SKU can never be listed again |

A finding for the email uniqueness may cite either file; the index on `customers.email` is part of the same fix (a unique index), so an extra INDEX-R2 finding at the same migration line is acceptable.

## Decoys (safe; flagging them is a false positive)

| Grader | Location | Why it is safe |
|---|---|---|
| ignores-catalog | src/routes/catalog.js:15 | the concatenated `ORDER BY` column comes only from the fixed `SORT_COLUMNS` map (line 13), with `name` as the fallback; the query is bounded by `LIMIT 100` over a 3,000-row table |
| ignores-stock | src/services/stock.js:16 | the stock read-modify-write runs in one transaction after `forUpdate()` locks the product row (line 8), and `products_stock_nonnegative` backs it; the order line snapshots `unit_price`, which is correct |

## Strengths worth naming

- Money is `decimal(12, 2)` everywhere except `orders.total` (`migrations/20230105091000_create_products.js:6`, `migrations/20230105090000_create_customers.js:6`).
- CHECK constraints guard stock, credit balance, and quantity (`migrations/20230105091000_create_products.js:11`).
- 64-bit keys and `timestamptz` timestamps on every table (`migrations/20230105092000_create_orders.js:3`).
- The draft purge deletes in batches of 500 inside short transactions (`src/jobs/purge-drafts.js:13`).
- Stock reservation locks the row before the check (`src/services/stock.js:8`).
