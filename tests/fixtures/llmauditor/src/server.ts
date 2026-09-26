import express from "express";
import pg from "pg";
import { triageTicket } from "./triage.js";

const db = new pg.Pool({ connectionString: process.env.DATABASE_URL });
const app = express();
app.use(express.json({ limit: "64kb" }));

// Public: the storefront contact form posts here.
app.post("/tickets", async (req, res) => {
  const { email, subject, body } = req.body;
  const { rows } = await db.query(
    "INSERT INTO tickets (email, subject, body, queue, priority, status) VALUES ($1, $2, $3, 'untriaged', 'normal', 'open') RETURNING id",
    [email, subject, body],
  );
  res.status(202).json({ id: rows[0].id });
  setImmediate(() => void triageInBackground(rows[0].id, subject, body));
});

async function triageInBackground(id: number, subject: string, body: string) {
  try {
    const t = await triageTicket(id, subject, body);
    await db.query("UPDATE tickets SET queue = $1, priority = $2, summary = $3 WHERE id = $4", [t.queue, t.priority, t.summary, id]);
  } catch (err) {
    console.error("triage failed", { ticketId: id, err });
    await db.query("UPDATE tickets SET triage_status = 'failed' WHERE id = $1", [id]);
  }
}

// Support agents' queue page, reachable only on the office VPN.
app.get("/dashboard/:queue", async (req, res) => {
  const { rows } = await db.query(
    "SELECT id, priority, summary FROM tickets WHERE queue = $1 AND status = 'open' ORDER BY id",
    [req.params.queue],
  );
  const items = rows.map((t) => `<li class="${t.priority}">#${t.id} ${t.summary}</li>`).join("");
  res.send(`<!doctype html><title>Queue</title><ul>${items}</ul>`);
});

app.listen(Number(process.env.PORT ?? 3000));
