const test = require('node:test')
const assert = require('node:assert')
const ledger = require('../src/ledger')

function setup() {
  const db = ledger.openDb(':memory:')
  const add = db.prepare('INSERT INTO accounts (name, cents) VALUES (?, ?)')
  const alice = add.run('alice', 5000).lastInsertRowid
  const bob = add.run('bob', 0).lastInsertRowid
  return { db, alice, bob }
}

function centsOf(db, id) {
  return db.prepare('SELECT cents FROM accounts WHERE id = ?').get(id).cents
}

test('transfer moves cents between accounts', () => {
  const { db, alice, bob } = setup()
  ledger.transfer(db, alice, bob, 1500)
  assert.strictEqual(centsOf(db, alice), 3500)
  assert.strictEqual(centsOf(db, bob), 1500)
})

test('transfer refuses an overdraft and changes nothing', () => {
  const { db, alice, bob } = setup()
  assert.throws(() => ledger.transfer(db, alice, bob, 9000), /CHECK constraint failed/)
  assert.strictEqual(centsOf(db, alice), 5000)
  assert.strictEqual(centsOf(db, bob), 0)
})

test('importing the same export twice stores each line once', () => {
  const { db, alice } = setup()
  const lines = [{ ref: 'bank-1', accountId: alice, cents: -1200, memo: 'groceries' }]
  assert.strictEqual(ledger.importEntries(db, lines), 1)
  assert.strictEqual(ledger.importEntries(db, lines), 0)
})
