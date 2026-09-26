const express = require('express')
const fetch = require('node-fetch')

const router = express.Router()

router.get('/', async (req, res) => {
  const response = await fetch(req.query.url, { timeout: 5000 })
  const html = await response.text()
  const title = (html.match(/<title>([^<]*)<\/title>/i) || [])[1] || ''
  res.json({ url: req.query.url, title })
})

module.exports = router
