import express from "express";
import { requireUser } from "./auth.js";

export const router = express.Router();

// The in-app "Send feedback" dialog posts here.
router.post("/", requireUser, function submitFeedback(req, res) {
  const message = String(req.body.message || "").trim();
  if (message.length < 3 || message.length > 5000) return res.status(400).json({ error: "Write 3 to 5,000 characters." });
  console.info("feedback", { workspaceId: req.workspace.id, userId: req.user.id, page: req.body.page, message });
  res.json({ ok: true });
});
