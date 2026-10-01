import express from "express";
import { paddle, settings, applySubscription } from "../billing.js";
import { planKeyForPrice } from "../../lib/plans.js";
import { requireUser } from "./auth.js";

export const router = express.Router();

// Starts a Paddle checkout for a workspace that has no live subscription at Paddle.
router.post("/", requireUser, async (req, res) => {
  const priceId = String(req.body.priceId || "");
  if (!planKeyForPrice(priceId)) return res.status(400).json({ error: "Choose a plan on the pricing page." });
  const ws = req.workspace;
  if (ws.paddle_subscription_id) {
    const current = await paddle("GET", `/subscriptions/${ws.paddle_subscription_id}`);
    if (current.status !== "canceled") {
      return res.status(409).json({ error: "This workspace already has a subscription. Change plans in Settings, Billing." });
    }
  }
  const transaction = await paddle("POST", "/transactions", {
    items: [{ price_id: priceId, quantity: 1 }],
    customer_id: ws.paddle_customer_id || undefined,
    custom_data: { workspace_id: ws.id },
    checkout: { url: `${settings.appUrl}/pay` },
  });
  res.json({ checkoutUrl: transaction.checkout.url });
});

// Paddle checkout returns the buyer here (successUrl in src/App.jsx) with
// ?_ptxn=<transaction id>.
router.get("/success", requireUser, async (req, res) => {
  const transactionId = String(req.query._ptxn || "");
  if (!/^txn_[a-z0-9]+$/.test(transactionId)) return res.redirect("/settings/billing");
  const transaction = await paddle("GET", `/transactions/${transactionId}`);
  const paid = transaction.status === "paid" || transaction.status === "completed";
  const sameWorkspace = transaction.custom_data?.workspace_id === req.workspace.id;
  const sameCustomer = !req.workspace.paddle_customer_id || transaction.customer_id === req.workspace.paddle_customer_id;
  if (!paid || !sameWorkspace || !sameCustomer || !transaction.subscription_id) {
    return res.redirect("/settings/billing?checkout=pending");
  }
  const subscription = await paddle("GET", `/subscriptions/${transaction.subscription_id}`);
  applySubscription(req.workspace.id, subscription);
  res.redirect("/settings/billing?checkout=done");
});
