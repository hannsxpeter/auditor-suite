# Helpdesk Copilot

Multi-tenant helpdesk assistant. Each tenant (an online store) embeds our chat
widget on its storefront, so anyone visiting a tenant's site can talk to it
without signing in. Signed-in shoppers also send their customer session token.

What it does:

- Widget chat: answers from the tenant's knowledge base (help-center articles
  written by the tenant's staff plus answers that shoppers post in the tenant's
  community forum), looks up the shopper's orders, and emails the shopper a
  written summary on request.
- Parcel tracking: answers "where is my parcel" through the carrier's API.
- Admin tools for tenant staff: ticket triage and tagging, summaries of closed
  tickets (a few thousand a day across all tenants), saved reports, and an
  "ask your data" box.

All tenants share one Postgres database with pgvector (see `db/schema.sql`).
Models are called through the OpenAI API.

## Run

    pip install -e .
    export DATABASE_URL=postgresql://localhost/helpdesk
    export OPENAI_API_KEY=... CARRIER_API_KEY=... SMTP_HOST=localhost
    uvicorn app.main:app
