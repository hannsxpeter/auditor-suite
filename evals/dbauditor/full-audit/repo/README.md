# Pantry Wholesale API

The ordering backend for Pantry's wholesale customers: restaurants, cafes, and
hotel kitchens. The storefront backend and the back-office tools call it, and
the ERP sync reads every order from it each night by walking `GET /orders`
page by page. An API gateway in front of the service authenticates every
request.

Production runs on managed PostgreSQL 15. Rough volumes: orders about 40
million rows (about 60,000 new rows a day), order_items about 180 million,
payments about 45 million, customers about 90,000, products about 3,000 SKUs.

Customers sign in to the storefront with their email address; during sign-in
the storefront backend calls `GET /customers/lookup?email=`.

The checkout worker, a separate service that shares this database, computes
each order's total when the customer checks out and writes payment attempts
into the `payments` table. An order stays in `draft` until one of its payments
succeeds. Draft orders older than 30 days are purged every night by
`npm run purge-drafts`.

## Run

    npm install
    DATABASE_URL=postgres://... npm run migrate
    DATABASE_URL=postgres://... npm start
