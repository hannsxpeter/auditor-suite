const express = require('express')
const db = require('../db')
const { addItem } = require('../services/stock')

const router = express.Router()
const PAGE_SIZE = 100

router.get('/', async (req, res) => {
  const page = Math.max(1, parseInt(req.query.page, 10) || 1)
  const orders = await db('orders')
    .select('id', 'customer_id', 'status', 'total', 'created_at')
    .orderBy('created_at', 'desc')
    .offset((page - 1) * PAGE_SIZE)
    .limit(PAGE_SIZE)
  res.json({ page, orders })
})

router.get('/:id', async (req, res) => {
  const order = await db('orders').where({ id: req.params.id }).first()
  if (!order) return res.status(404).json({ error: 'not found' })
  const items = await db('order_items').where({ order_id: order.id })
  res.json({ ...order, items })
})

router.post('/:id/items', async (req, res) => {
  const item = await addItem(Number(req.params.id), req.body.productId, req.body.quantity)
  res.status(201).json(item)
})

module.exports = router
