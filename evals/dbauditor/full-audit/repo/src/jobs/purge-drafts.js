const db = require('../db')

const BATCH_SIZE = 500

async function purgeDraftOrders(days = 30) {
  const cutoff = new Date(Date.now() - days * 24 * 60 * 60 * 1000)
  let removed = 0
  for (;;) {
    const ids = await db('orders')
      .where('status', 'draft')
      .where('created_at', '<', cutoff)
      .orderBy('id')
      .limit(BATCH_SIZE)
      .pluck('id')
    if (ids.length === 0) break
    await db.transaction(async (trx) => {
      await trx('order_items').whereIn('order_id', ids).del()
      await trx('orders').whereIn('id', ids).del()
    })
    removed += ids.length
  }
  return removed
}

module.exports = { purgeDraftOrders }

if (require.main === module) {
  purgeDraftOrders()
    .then((removed) => {
      console.log(`purged ${removed} draft orders`)
      return db.destroy()
    })
    .catch((err) => {
      console.error(err)
      process.exit(1)
    })
}
