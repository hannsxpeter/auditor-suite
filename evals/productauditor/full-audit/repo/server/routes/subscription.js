import express from "express";
import * as db from "../db.js";
import { paddle } from "../billing.js";
import { planKeyForPrice } from "../../lib/plans.js";
import { requireUser } from "./auth.js";

export const router = express.Router();

function hasLiveSubscription(ws) {
  return Boolean(ws.paddle_subscription_id) && ws.subscription_status !== "canceled";
}

// Moves the subscription to another plan or billing period. Paddle prorates
// the change, and the webhook copies the new plan onto the workspace.
router.post("/change", requireUser, async function changePlan(req, res) {
  const priceId = String(req.body.priceId || "");
  if (!planKeyForPrice(priceId)) return res.status(400).json({ error: "Choose a plan." });
  if (!hasLiveSubscription(req.workspace)) return res.status(409).json({ error: "There is no subscription to change." });
  await paddle("PATCH", `/subscriptions/${req.workspace.paddle_subscription_id}`, {
    items: [{ price_id: priceId, quantity: 1 }],
    proration_billing_mode: "prorated_immediately",
  });
  res.json({ ok: true, message: "Your plan is changing. It can take a minute to show here." });
});

// Returns Paddle's page for updating the card on file.
router.get("/payment-method", requireUser, async function paymentMethodPage(req, res) {
  if (!hasLiveSubscription(req.workspace)) return res.status(409).json({ error: "There is no subscription." });
  const subscription = await paddle("GET", `/subscriptions/${req.workspace.paddle_subscription_id}`);
  res.json({ url: subscription.management_urls.update_payment_method });
});

router.post("/cancel", requireUser, function cancelSubscription(req, res) {
  const ws = req.workspace;
  db.updateWorkspace(ws.id, { plan: "free", subscription_status: "canceled", canceled_at: new Date().toISOString() });
  res.json({ ok: true, message: "Your subscription is canceled. You will not be charged again." });
});
