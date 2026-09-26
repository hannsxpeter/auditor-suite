const db = require('../db')

async function createCustomer({ email, name }) {
  const normalized = String(email || '').trim().toLowerCase()
  const existing = await db('customers').where({ email: normalized }).first()
  if (existing) {
    throw Object.assign(new Error('email already registered'), { status: 409 })
  }
  const [customer] = await db('customers')
    .insert({ email: normalized, name })
    .returning(['id', 'email', 'name'])
  return customer
}

module.exports = { createCustomer }
