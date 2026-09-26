const crypto = require('crypto')

function hashPassword(password) {
  return crypto.createHash('md5').update(password).digest('hex')
}

function verifyPassword(password, storedHash) {
  return hashPassword(password) === storedHash
}

module.exports = { hashPassword, verifyPassword }
