import { readFileSync } from "node:fs";
import * as db from "./db.js";

// Local development talks to the Paddle sandbox. Production reads its
// settings from config/production.json.
const development = {
  appUrl: "http://localhost:5173",
  paddle: { apiBase: "https://sandbox-api.paddle.com", environment: "sandbox" },
};

export const settings =
  process.env.NODE_ENV === "production"
    ? JSON.parse(readFileSync(new URL("../config/production.json", import.meta.url), "utf8"))
    : development;

// Calls the Paddle Billing API and returns the response's data.
export async function paddle(method, path, body) {
  const res = await fetch(`${settings.paddle.apiBase}${path}`, {
    method,
    headers: {
      Authorization: `Bearer ${process.env.PADDLE_API_KEY}`,
      "Content-Type": "application/json",
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  const json = await res.json();
  if (!res.ok) throw new Error(`Paddle ${method} ${path} failed with status ${res.status}`);
  return json.data;
}

// Copies a Paddle subscription onto the workspace it was bought for.
export function applySubscription(workspaceId, subscription) {
  db.updateWorkspace(workspaceId, {
    plan: subscription.items[0].price.id,
    subscription_status: subscription.status,
    paddle_customer_id: subscription.customer_id,
    paddle_subscription_id: subscription.id,
    current_period_end: subscription.current_billing_period ? subscription.current_billing_period.ends_at : null,
  });
}
