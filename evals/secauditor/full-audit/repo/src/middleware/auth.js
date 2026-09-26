const { readToken } = require('../auth/tokens')

function requireAuth(req, res, next) {
  const header = req.headers.authorization || ''
  const token = header.replace(/^Bearer /, '')
  try {
    const claims = readToken(token)
    req.user = { id: claims.sub, role: claims.role }
    next()
  } catch (err) {
    res.status(401).json({ error: 'unauthorized' })
  }
}

function requireAdmin(req, res, next) {
  requireAuth(req, res, () => {
    if (req.user.role !== 'admin') return res.status(403).json({ error: 'forbidden' })
    next()
  })
}

module.exports = { requireAuth, requireAdmin }
