const express = require('express')
const rateLimit = require('express-rate-limit')
const { requireAuth } = require('./middleware/auth')
const { errorHandler } = require('./errors')

const app = express()
app.use(express.json({ limit: '100kb' }))

app.use((req, res, next) => {
  res.setHeader('Access-Control-Allow-Origin', req.headers.origin || '*')
  res.setHeader('Access-Control-Allow-Credentials', 'true')
  next()
})

const loginLimiter = rateLimit({ windowMs: 15 * 60 * 1000, max: 10 })
app.use('/login', loginLimiter, require('./routes/login'))

app.use('/orders', requireAuth, require('./routes/orders'))
app.use('/invoices', requireAuth, require('./routes/invoices'))
app.use('/reports', requireAuth, require('./routes/reports'))
app.use('/search', require('./routes/search'))
app.use('/preview', requireAuth, require('./routes/preview'))
app.use('/files', requireAuth, require('./routes/files'))
app.use('/admin', require('./routes/admin'))

app.use(errorHandler)

app.listen(process.env.PORT || 3000)
