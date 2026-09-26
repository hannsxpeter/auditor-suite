exports.up = function (knex) {
  return knex.schema.createTable('order_items', (table) => {
    table.bigIncrements('id')
    table.bigInteger('order_id').notNullable().references('id').inTable('orders')
    table.bigInteger('product_id').notNullable().references('id').inTable('products')
    table.integer('quantity').notNullable()
    table.decimal('unit_price', 12, 2).notNullable()
    table.index(['product_id'])
    table.check('?? > 0', ['quantity'], 'order_items_quantity_positive')
  })
}

exports.down = function (knex) {
  return knex.schema.dropTable('order_items')
}
