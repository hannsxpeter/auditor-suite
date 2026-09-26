const express = require('express')
const db = require('../db')

const router = express.Router()

const SORT_COLUMNS = new Map([
  ['name', 'name'],
  ['price', 'price'],
  ['newest', 'created_at'],
])

router.get('/', async (req, res) => {
  const column = SORT_COLUMNS.get(String(req.query.sort)) || 'name'
  const result = await db.raw(
    'SELECT id, sku, name, price FROM products WHERE deleted_at IS NULL ORDER BY ' + column + ' LIMIT 100'
  )
  res.json(result.rows)
})

module.exports = router
