const express = require('express')
const db = require('../db')

const router = express.Router()
const SORTABLE = ['created_at', 'total', 'status']

router.get('/orders', async (req, res) => {
  const sort = SORTABLE.includes(req.query.sort) ? req.query.sort : 'created_at'
  const rows = await db.query(
    `SELECT id, total, status, created_at FROM orders WHERE customer_id = ? ORDER BY ${sort} DESC`,
    [req.user.id]
  )
  res.json(rows)
})

module.exports = router
