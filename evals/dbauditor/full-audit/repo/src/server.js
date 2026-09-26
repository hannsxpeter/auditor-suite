const express = require('express')

const app = express()
app.use(express.json({ limit: '100kb' }))

app.use('/customers', require('./routes/customers'))
app.use('/catalog', require('./routes/catalog'))
app.use('/orders', require('./routes/orders'))

app.use((err, req, res, next) => {
  res.status(err.status || 500).json({ error: err.status ? err.message : 'internal error' })
})

app.listen(process.env.PORT || 3000)
