# Brewbox API

The backend for Brewbox, a coffee subscription service. Customers pick a
plan, a grind, and a delivery frequency; the API charges the first box,
renews subscriptions nightly, and records payment events from our payment
provider. The web app and the ops console are the only clients. About 4,000
active subscriptions.

## Run locally

    pip install -r requirements.txt
    export DATABASE_URL=postgresql+psycopg2://localhost/brewbox
    flask --app app init-db
    flask --app app run

Production runs `gunicorn "app:create_app()"`. Deployment manifests live in
the brewbox-infra repository. Kubernetes probes: liveness `GET /healthz`,
readiness `GET /readyz`.

## Configuration

| Variable | Purpose |
|---|---|
| `SECRET_KEY` | Flask secret key |
| `DATABASE_URL` | PostgreSQL connection string |
| `PAYMENTS_URL` | payment provider base URL (defaults to the sandbox) |
| `PAYMENTS_KEY` | payment provider API key |
| `PAYMENTS_WEBHOOK_SECRET` | secret that signs payment webhooks |
| `CARRIER_URL` | shipping carrier base URL (defaults to the sandbox) |
| `CARRIER_TOKEN` | shipping carrier API token |
| `RENEWAL_RETRY_LIMIT` | how many times the nightly renewal retries a declined card before pausing the subscription (default 3) |

## Jobs

Run `flask --app app renew` once a night. It charges every subscription whose
renewal date has arrived.

## Webhooks

`POST /webhooks/payments` receives payment events. Each request is signed with
`PAYMENTS_WEBHOOK_SECRET` (HMAC-SHA256 in the `X-Signature` header).

## Tests

    pytest
