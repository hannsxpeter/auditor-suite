# Shopfront API

The REST API behind the Shopfront web store. It is deployed to the public
internet at `api.shopfront.example` and serves the storefront, the customer
account pages, and the internal admin console.

## Run

```
npm install
DATABASE_URL=mysql://... JWT_SECRET=... npm start
```
