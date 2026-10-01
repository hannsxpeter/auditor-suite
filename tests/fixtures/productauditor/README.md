# Duebook

Invoicing for solo freelancers: create a clean invoice and email it to your client in a minute.

## Plans

- Free: up to 2 clients and 5 invoices a month, in US dollars.
- Pro: $9 a month for unlimited clients, unlimited invoices, and invoices in any currency. Every new account starts with a 14-day Pro trial, no card needed.

Payments, sales tax, and receipts are handled by Lemon Squeezy, our merchant of record. Cancel anytime from the customer portal.

## Deploy

Set these in production: SECRET_KEY, DATABASE_URL, MAIL_SERVER, LEMONSQUEEZY_API_KEY, LEMONSQUEEZY_STORE_ID, LEMONSQUEEZY_WEBHOOK_SECRET, LS_PRO_VARIANT_ID, and POSTHOG_KEY.

Point the Lemon Squeezy webhook at `/billing/webhook`.
