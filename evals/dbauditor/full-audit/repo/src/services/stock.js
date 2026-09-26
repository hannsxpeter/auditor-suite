const db = require('../db')

async function addItem(orderId, productId, quantity) {
  return db.transaction(async (trx) => {
    const product = await trx('products')
      .where({ id: productId })
      .whereNull('deleted_at')
      .forUpdate()
      .first()
    if (!product) {
      throw Object.assign(new Error('product not found'), { status: 404 })
    }
    if (product.stock < quantity) {
      throw Object.assign(new Error('not enough stock'), { status: 409 })
    }
    await trx('products').where({ id: productId }).update({ stock: product.stock - quantity })
    const [item] = await trx('order_items')
      .insert({ order_id: orderId, product_id: productId, quantity, unit_price: product.price })
      .returning(['id', 'order_id', 'product_id', 'quantity', 'unit_price'])
    return item
  })
}

module.exports = { addItem }
