# Brightdesk website

Marketing site and help center for Brightdesk, a shared inbox and help desk
for small support teams. Built with Next.js (App Router) and deployed on
Vercel. Production lives at https://www.brightdesk.example; every pull request
gets a preview deployment.

The signed-in customer dashboard lives under `/dashboard`.

## Search and AI visibility

Organic search is our largest acquisition channel. We also want Brightdesk to
show up, with a link, when people ask ChatGPT, Perplexity, or Google's AI
Overviews for help desk recommendations. `public/llms.txt` lists the pages we
want AI assistants to read.

## Develop

    npm install
    npm run dev
