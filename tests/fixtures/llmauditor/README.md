# Ticket triage

Triage service for an online store's support inbox. The public contact form on
the storefront posts new tickets here. Claude sorts each ticket into a queue,
sets a priority, and writes a one-line summary for the support agents' queue
page, which this app serves on the office VPN.

About 300 tickets a day. The Anthropic API is used under the company's
commercial terms. Customer email addresses stay in our database and are never
sent to the model.

## Run

    npm install
    DATABASE_URL=postgres://localhost/triage ANTHROPIC_API_KEY=... npm start
