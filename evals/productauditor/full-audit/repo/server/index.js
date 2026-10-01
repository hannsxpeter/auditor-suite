import express from "express";
import session from "express-session";
import { randomUUID } from "node:crypto";
import * as db from "./db.js";
import { router as authRouter, loadUser, requireUser } from "./routes/auth.js";
import { router as checkoutRouter } from "./routes/checkout.js";
import { router as subscriptionRouter } from "./routes/subscription.js";
import { router as webhookRouter } from "./routes/webhooks.js";
import { router as feedbackRouter } from "./routes/feedback.js";
import { featuresFor, projectLimit, requireFeature } from "./entitlements.js";

const app = express();
app.set("trust proxy", 1);

// The webhook reads the raw body to check Paddle's signature, so it is
// mounted before the JSON parser.
app.use("/api/webhooks", webhookRouter);
app.use(express.json());
app.use(
  session({
    secret: process.env.SESSION_SECRET || "dev-secret-change-me",
    resave: false,
    saveUninitialized: false,
    cookie: { httpOnly: true, sameSite: "lax", secure: process.env.NODE_ENV === "production" },
  }),
);
app.use(loadUser);

app.use("/api/auth", authRouter);
app.use("/api/checkout", checkoutRouter);
app.use("/api/subscription", subscriptionRouter);
app.use("/api/feedback", feedbackRouter);

app.get("/api/me", requireUser, (req, res) => {
  const ws = req.workspace;
  res.json({
    user: { id: req.user.id, email: req.user.email },
    workspace: {
      id: ws.id,
      name: ws.name,
      plan: ws.plan,
      status: ws.subscription_status,
      renewsOn: ws.current_period_end,
      hasSubscription: Boolean(ws.paddle_subscription_id) && ws.subscription_status !== "canceled",
    },
    features: featuresFor(ws),
    projectLimit: projectLimit(ws),
  });
});

function ownProject(req, res, next) {
  const project = db.getProject(req.params.id);
  if (!project || project.workspace_id !== req.workspace.id) return res.status(404).json({ error: "Project not found." });
  req.project = project;
  next();
}

app.get("/api/projects", requireUser, (req, res) => {
  res.json(db.listProjects(req.workspace.id));
});

app.post("/api/projects", requireUser, (req, res) => {
  const name = String(req.body.name || "").trim();
  if (!name) return res.status(400).json({ error: "Give the project a name." });
  const limit = projectLimit(req.workspace);
  if (db.countProjects(req.workspace.id) >= limit) {
    return res.status(402).json({ error: "project_limit", limit });
  }
  const project = db.createProject({ id: randomUUID(), workspace_id: req.workspace.id, name, created_by: req.user.id });
  res.status(201).json(project);
});

app.get("/api/projects/:id", requireUser, ownProject, (req, res) => {
  res.json({ ...req.project, cards: db.projectCards(req.project.id) });
});

app.post("/api/projects/:id/cards", requireUser, ownProject, (req, res) => {
  const title = String(req.body.title || "").trim();
  if (!title) return res.status(400).json({ error: "Give the card a title." });
  const card = db.createCard({
    id: randomUUID(),
    project_id: req.project.id,
    title,
    due_on: req.body.dueOn || null,
    notes: req.body.notes || null,
    created_by: req.user.id,
  });
  res.status(201).json(card);
});

app.patch("/api/cards/:id", requireUser, (req, res) => {
  const card = db.getCard(req.params.id);
  const project = card && db.getProject(card.project_id);
  if (!project || project.workspace_id !== req.workspace.id) return res.status(404).json({ error: "Card not found." });
  if (!["todo", "doing", "done"].includes(req.body.status)) return res.status(400).json({ error: "Unknown status." });
  res.json(db.setCardStatus(card.id, req.body.status));
});

app.get("/api/projects/:id/export.csv", requireUser, requireFeature("csv_export"), ownProject, (req, res) => {
  const quote = (value) => `"${String(value ?? "").replaceAll('"', '""')}"`;
  const header = ["title", "status", "due_on", "notes", "created_at"];
  const rows = db.projectCards(req.project.id).map((card) => header.map((field) => quote(card[field])).join(","));
  res.type("text/csv").attachment(`${req.project.name}.csv`);
  res.send([header.join(","), ...rows].join("\n"));
});

app.listen(process.env.PORT || 3000);
