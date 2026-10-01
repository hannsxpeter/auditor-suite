# Fieldnote

Fieldnote gives small agencies and freelancers one board per client project, so nothing slips between the kickoff and the invoice.

## Plans

| Plan | Price | What you get |
|---|---|---|
| Free | $0 | Up to 3 projects |
| Pro | $24/month or $240/year | Up to 25 projects, CSV export of any project |
| Studio | $59/month or $590/year | Unlimited projects, CSV export of any project |

Every new workspace starts with a 14-day free trial of Pro. No credit card required.

Cancel any time from Settings > Billing. You keep your plan until the end of the period you paid for, and you are not charged again.

Questions or problems? Use Send feedback in the app. We read every message and reply by email within one business day.

## How it fits together

- `server/`: the Express API (sign-up, projects and cards, checkout, subscriptions, the Paddle webhook, feedback).
- `src/`: the React app (pricing page, boards, settings, help).
- `lib/plans.js`: the plan catalog. The pricing page, checkout, and entitlements read it.
- `content/help/`: help center articles, shown in the app under Help.
- Billing runs on Paddle Billing. Paddle is the merchant of record and collects sales tax and VAT.
- Product analytics run on PostHog.

## Develop

Set these environment variables:

- `PADDLE_API_KEY`: the Paddle API key for the environment.
- `PADDLE_WEBHOOK_SECRET`: the secret of the Paddle notification destination.
- `VITE_PADDLE_CLIENT_TOKEN` and `VITE_PADDLE_ENVIRONMENT`: the Paddle.js client token and environment for the browser.
- `SESSION_SECRET`: the session cookie secret.
- `VITE_POSTHOG_KEY` and `VITE_POSTHOG_HOST`: the PostHog project for the environment.

Then run `npm install` and `npm run dev`. The API listens on port 3000 and the app on port 5173. Local development uses the Paddle sandbox.

## Deploy

Run `npm run build`, then `npm start`, which sets `NODE_ENV=production`. Production settings live in `config/production.json`.
