const express = require('express')
const ledger = require('./ledger')

const db = ledger.openDb(process.env.LEDGER_DB || 'ledger.db')
const app = express()
app.use(express.json({ limit: '1mb' }))

app.get('/accounts', (req, res) => {
  res.json(ledger.listAccounts(db))
})

app.post('/transfers', async (req, res) => {
  const { from, to, cents } = req.body
  if (!Number.isInteger(cents) || cents <= 0) {
    return res.status(400).json({ error: 'cents must be a positive integer' })
  }
  ledger.transfer(db, from, to, cents)
  res.status(201).json({ ok: true })
})

app.post('/import', async (req, res) => {
  const imported = ledger.importEntries(db, req.body.entries || [])
  res.json({ imported })
})

app.use((err, req, res, next) => {
  console.error(err)
  res.status(500).json({ error: 'internal error' })
})

app.listen(3000, '127.0.0.1')
