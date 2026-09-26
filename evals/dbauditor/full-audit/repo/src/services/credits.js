const db = require('../db')

async function addCredit(customerId, amount) {
  const customer = await db('customers').where({ id: customerId }).first()
  if (!customer) {
    throw Object.assign(new Error('customer not found'), { status: 404 })
  }
  const balance = Number(customer.credit_balance) + Number(amount)
  await db('customers').where({ id: customerId }).update({ credit_balance: balance })
  return balance
}

module.exports = { addCredit }
