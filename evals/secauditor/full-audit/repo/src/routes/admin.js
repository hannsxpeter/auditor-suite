const express = require('express')
const db = require('../db')
const { requireAuth, requireAdmin } = require('../middleware/auth')

const router = express.Router()

router.get('/stats', requireAdmin, async (req, res) => {
  const rows = await db.query('SELECT COUNT(*) AS orders, SUM(total) AS revenue FROM orders')
  res.json(rows[0])
})

router.post('/refunds', requireAuth, async (req, res) => {
  await db.query('UPDATE orders SET status = ? WHERE id = ?', ['refunded', req.body.orderId])
  await db.query('INSERT INTO refunds (order_id, amount, issued_by) VALUES (?, ?, ?)', [req.body.orderId, req.body.amount, req.user.id])
  res.json({ ok: true })
})

module.exports = router
