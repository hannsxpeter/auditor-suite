const express = require('express')
const path = require('path')
const config = require('../config')

const router = express.Router()

router.get('/:name', (req, res) => {
  const filePath = path.join(config.uploadDir, req.params.name)
  res.sendFile(filePath)
})

module.exports = router
