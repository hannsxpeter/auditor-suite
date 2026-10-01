import Database from "better-sqlite3";

export const db = new Database(process.env.DATABASE_PATH || "fieldnote.db");
db.pragma("foreign_keys = ON");

db.exec(`
  CREATE TABLE IF NOT EXISTS users (
    id TEXT PRIMARY KEY,
    email TEXT NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    created_at TEXT NOT NULL DEFAULT (datetime('now'))
  );
  CREATE TABLE IF NOT EXISTS workspaces (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    owner_id TEXT NOT NULL UNIQUE REFERENCES users(id),
    plan TEXT NOT NULL DEFAULT 'free',
    subscription_status TEXT,
    trial_ends_at TEXT,
    paddle_customer_id TEXT,
    paddle_subscription_id TEXT,
    current_period_end TEXT,
    canceled_at TEXT,
    created_at TEXT NOT NULL DEFAULT (datetime('now'))
  );
  CREATE TABLE IF NOT EXISTS projects (
    id TEXT PRIMARY KEY,
    workspace_id TEXT NOT NULL REFERENCES workspaces(id),
    name TEXT NOT NULL,
    created_by TEXT NOT NULL REFERENCES users(id),
    created_at TEXT NOT NULL DEFAULT (datetime('now'))
  );
  CREATE TABLE IF NOT EXISTS cards (
    id TEXT PRIMARY KEY,
    project_id TEXT NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'todo' CHECK (status IN ('todo', 'doing', 'done')),
    due_on TEXT,
    notes TEXT,
    created_by TEXT NOT NULL REFERENCES users(id),
    created_at TEXT NOT NULL DEFAULT (datetime('now'))
  );
`);

export function getUser(id) {
  return db.prepare("SELECT * FROM users WHERE id = ?").get(id);
}

export function getUserByEmail(email) {
  return db.prepare("SELECT * FROM users WHERE email = ?").get(email);
}

export function createUser(user) {
  db.prepare("INSERT INTO users (id, email, password_hash) VALUES (@id, @email, @password_hash)").run(user);
  return getUser(user.id);
}

export function getWorkspace(id) {
  return db.prepare("SELECT * FROM workspaces WHERE id = ?").get(id);
}

export function workspaceForUser(userId) {
  return db.prepare("SELECT * FROM workspaces WHERE owner_id = ?").get(userId);
}

export function createWorkspace(workspace) {
  db.prepare(
    `INSERT INTO workspaces (id, name, owner_id, plan, subscription_status, trial_ends_at)
     VALUES (@id, @name, @owner_id, @plan, @subscription_status, @trial_ends_at)`,
  ).run(workspace);
  return getWorkspace(workspace.id);
}

const WORKSPACE_FIELDS = new Set([
  "name",
  "plan",
  "subscription_status",
  "paddle_customer_id",
  "paddle_subscription_id",
  "current_period_end",
  "canceled_at",
]);

export function updateWorkspace(id, fields) {
  const keys = Object.keys(fields).filter((key) => WORKSPACE_FIELDS.has(key));
  if (keys.length === 0) return;
  const sets = keys.map((key) => `${key} = @${key}`).join(", ");
  db.prepare(`UPDATE workspaces SET ${sets} WHERE id = @id`).run({ ...fields, id });
}

// Oldest first.
export function listProjects(workspaceId) {
  return db.prepare("SELECT * FROM projects WHERE workspace_id = ? ORDER BY created_at, id").all(workspaceId);
}

export function countProjects(workspaceId) {
  return db.prepare("SELECT COUNT(*) AS n FROM projects WHERE workspace_id = ?").get(workspaceId).n;
}

export function getProject(id) {
  return db.prepare("SELECT * FROM projects WHERE id = ?").get(id);
}

export function createProject(project) {
  db.prepare(
    "INSERT INTO projects (id, workspace_id, name, created_by) VALUES (@id, @workspace_id, @name, @created_by)",
  ).run(project);
  return getProject(project.id);
}

export function deleteProjects(ids) {
  const remove = db.prepare("DELETE FROM projects WHERE id = ?");
  db.transaction((list) => list.forEach((id) => remove.run(id)))(ids);
}

export function projectCards(projectId) {
  return db.prepare("SELECT * FROM cards WHERE project_id = ? ORDER BY created_at, id").all(projectId);
}

export function getCard(id) {
  return db.prepare("SELECT * FROM cards WHERE id = ?").get(id);
}

export function createCard(card) {
  db.prepare(
    `INSERT INTO cards (id, project_id, title, due_on, notes, created_by)
     VALUES (@id, @project_id, @title, @due_on, @notes, @created_by)`,
  ).run(card);
  return getCard(card.id);
}

export function setCardStatus(id, status) {
  db.prepare("UPDATE cards SET status = ? WHERE id = ?").run(status, id);
  return getCard(id);
}
