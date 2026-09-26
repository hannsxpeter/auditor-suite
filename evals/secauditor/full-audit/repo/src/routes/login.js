const express = require('express')
const db = require('../db')
const { verifyPassword } = require('../auth/passwords')
const { issueToken } = require('../auth/tokens')

const router = express.Router()

router.post('/', async (req, res) => {
  const users = await db.query('SELECT id, role, password_hash FROM users WHERE email = ?', [req.body.email])
  const user = users[0]
  if (!user || !verifyPassword(req.body.password, user.password_hash)) {
    return res.status(401).json({ error: 'invalid email or password' })
  }
  res.json({ token: issueToken(user) })
})

module.exports = router
