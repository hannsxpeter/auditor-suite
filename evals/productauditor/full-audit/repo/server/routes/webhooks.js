import express from "express";
import crypto from "node:crypto";
import * as db from "../db.js";
import { applySubscription } from "../billing.js";
import { planKeyForPrice } from "../../lib/plans.js";
import { applyPlanLimits } from "../jobs/plan-limits.js";

export const router = express.Router();

// Paddle-Signature: ts=<unix seconds>;h1=<hex HMAC-SHA256 of "ts:body">
function verifySignature(header, rawBody) {
  const parts = Object.fromEntries(String(header || "").split(";").map((pair) => pair.split("=")));
  if (!parts.ts || !parts.h1) return false;
  if (Math.abs(Date.now() / 1000 - Number(parts.ts)) > 300) return false;
  const expected = crypto
    .createHmac("sha256", process.env.PADDLE_WEBHOOK_SECRET)
    .update(`${parts.ts}:${rawBody}`)
    .digest("hex");
  return expected.length === parts.h1.length && crypto.timingSafeEqual(Buffer.from(expected), Buffer.from(parts.h1));
}

router.post("/paddle", express.raw({ type: "application/json" }), async (req, res) => {
  const rawBody = req.body.toString("utf8");
  if (!verifySignature(req.get("Paddle-Signature"), rawBody)) return res.status(401).end();
  const event = JSON.parse(rawBody);
  const workspaceId = event.data.custom_data?.workspace_id;
  if (!workspaceId) return res.status(200).end();

  switch (event.event_type) {
    case "subscription.created":
    case "subscription.updated":
      applySubscription(workspaceId, event.data);
      await applyPlanLimits(workspaceId, planKeyForPrice(event.data.items[0].price.id));
      break;
    case "subscription.past_due":
      db.updateWorkspace(workspaceId, { subscription_status: "past_due" });
      break;
    case "subscription.canceled":
      db.updateWorkspace(workspaceId, { plan: "free", subscription_status: "canceled" });
      await applyPlanLimits(workspaceId, "free");
      break;
    default:
      break;
  }
  res.status(200).end();
});
