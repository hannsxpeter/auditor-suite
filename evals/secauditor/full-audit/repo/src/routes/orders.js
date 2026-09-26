const express = require('express')
const db = require('../db')

const router = express.Router()

router.get('/', async (req, res) => {
  const rows = await db.query('SELECT id, total, status FROM orders WHERE customer_id = ?', [req.user.id])
  res.json(rows)
})

router.get('/:id', async (req, res) => {
  const rows = await db.query('SELECT * FROM orders WHERE id = ?', [req.params.id])
  if (!rows[0]) return res.status(404).json({ error: 'not found' })
  res.json(rows[0])
})

module.exports = router
