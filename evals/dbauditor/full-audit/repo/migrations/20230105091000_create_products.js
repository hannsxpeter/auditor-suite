exports.up = function (knex) {
  return knex.schema.createTable('products', (table) => {
    table.bigIncrements('id')
    table.string('sku', 32).notNullable()
    table.string('name', 200).notNullable()
    table.decimal('price', 12, 2).notNullable()
    table.integer('stock').notNullable().defaultTo(0)
    table.timestamp('deleted_at', { useTz: true })
    table.timestamps(true, true)
    table.unique(['sku'])
    table.check('?? >= 0', ['stock'], 'products_stock_nonnegative')
  })
}

exports.down = function (knex) {
  return knex.schema.dropTable('products')
}
