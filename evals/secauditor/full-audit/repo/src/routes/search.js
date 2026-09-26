const express = require('express')
const db = require('../db')

const router = express.Router()

router.get('/', async (req, res) => {
  const term = req.query.q || ''
  const rows = await db.query("SELECT id, name, price FROM products WHERE name LIKE '%" + term + "%' LIMIT 50")
  res.json(rows)
})

module.exports = router
