const express = require('express')
const db = require('../db')
const { createCustomer } = require('../services/accounts')
const { addCredit } = require('../services/credits')

const router = express.Router()

router.get('/lookup', async (req, res) => {
  const email = String(req.query.email || '').trim().toLowerCase()
  const result = await db.raw("SELECT id, name, email, credit_balance FROM customers WHERE email = '" + email + "'")
  if (!result.rows[0]) return res.status(404).json({ error: 'not found' })
  res.json(result.rows[0])
})

router.post('/', async (req, res) => {
  const customer = await createCustomer(req.body)
  res.status(201).json(customer)
})

router.post('/:id/credits', async (req, res) => {
  const balance = await addCredit(Number(req.params.id), req.body.amount)
  res.json({ balance })
})

module.exports = router
