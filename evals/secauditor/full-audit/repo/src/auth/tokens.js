const jwt = require('jsonwebtoken')
const config = require('../config')

function issueToken(user) {
  return jwt.sign({ sub: user.id, role: user.role }, config.jwtSecret, { expiresIn: config.tokenTtl })
}

function readToken(token) {
  return jwt.verify(token, config.jwtSecret, { algorithms: ['HS256', 'none'] })
}

module.exports = { issueToken, readToken }
