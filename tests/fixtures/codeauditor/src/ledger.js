const Database = require('better-sqlite3')

const MIGRATIONS = [
  `CREATE TABLE accounts (
     id INTEGER PRIMARY KEY,
     name TEXT NOT NULL UNIQUE,
     cents INTEGER NOT NULL DEFAULT 0 CHECK (cents >= 0)
   )`,
  `CREATE TABLE entries (
     bank_ref TEXT PRIMARY KEY,
     account_id INTEGER NOT NULL REFERENCES accounts(id),
     cents INTEGER NOT NULL,
     memo TEXT
   )`,
]

function openDb(file) {
  const db = new Database(file)
  db.pragma('foreign_keys = ON')
  const migrate = db.transaction(() => {
    const version = db.pragma('user_version', { simple: true })
    for (let v = version; v < MIGRATIONS.length; v++) db.exec(MIGRATIONS[v])
    db.pragma(`user_version = ${MIGRATIONS.length}`)
  })
  migrate()
  return db
}

function listAccounts(db) {
  return db.prepare('SELECT id, name, cents FROM accounts ORDER BY name').all()
}

function transfer(db, fromId, toId, cents) {
  db.prepare('UPDATE accounts SET cents = cents - ? WHERE id = ?').run(cents, fromId)
  db.prepare('UPDATE accounts SET cents = cents + ? WHERE id = ?').run(cents, toId)
}

function importEntries(db, entries) {
  const insert = db.prepare('INSERT OR IGNORE INTO entries (bank_ref, account_id, cents, memo) VALUES (?, ?, ?, ?)')
  let count = 0
  for (const e of entries) {
    count += insert.run(e.ref, e.accountId, e.cents, e.memo).changes
  }
  return count
}

module.exports = { openDb, listAccounts, transfer, importEntries }
