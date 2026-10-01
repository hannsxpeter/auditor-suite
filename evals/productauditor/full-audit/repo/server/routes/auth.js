import express from "express";
import bcrypt from "bcryptjs";
import { randomUUID } from "node:crypto";
import * as db from "../db.js";

export const TRIAL_DAYS = 14;
const DAY_MS = 24 * 60 * 60 * 1000;

export const router = express.Router();

// Puts the signed-in user and their workspace on the request.
export function loadUser(req, res, next) {
  if (req.session.userId) {
    req.user = db.getUser(req.session.userId);
    req.workspace = req.user ? db.workspaceForUser(req.user.id) : null;
  }
  next();
}

export function requireUser(req, res, next) {
  if (!req.user || !req.workspace) return res.status(401).json({ error: "Please sign in." });
  next();
}

// New workspaces start on Pro with a 14-day trial, and no card is needed.
router.post("/signup", async (req, res) => {
  const email = String(req.body.email || "").trim().toLowerCase();
  const password = String(req.body.password || "");
  const name = String(req.body.workspaceName || "").trim() || "My workspace";
  if (!email.includes("@") || password.length < 10) {
    return res.status(400).json({ error: "Enter your email and a password of at least 10 characters." });
  }
  if (db.getUserByEmail(email)) {
    return res.status(409).json({ error: "An account with this email already exists. Sign in instead." });
  }
  const user = db.createUser({ id: randomUUID(), email, password_hash: await bcrypt.hash(password, 12) });
  const trialEndsAt = new Date(Date.now() + TRIAL_DAYS * DAY_MS).toISOString();
  db.createWorkspace({ id: randomUUID(), name, owner_id: user.id, plan: "pro", subscription_status: "trialing", trial_ends_at: trialEndsAt });
  req.session.regenerate(() => {
    req.session.userId = user.id;
    res.status(201).json({ ok: true });
  });
});

router.post("/signin", async (req, res) => {
  const email = String(req.body.email || "").trim().toLowerCase();
  const user = db.getUserByEmail(email);
  const ok = user && (await bcrypt.compare(String(req.body.password || ""), user.password_hash));
  if (!ok) return res.status(401).json({ error: "That email and password do not match." });
  req.session.regenerate(() => {
    req.session.userId = user.id;
    res.json({ ok: true });
  });
});

router.post("/signout", (req, res) => {
  req.session.destroy(() => res.json({ ok: true }));
});
