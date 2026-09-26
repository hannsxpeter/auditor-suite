exports.up = function (knex) {
  return knex.schema.createTable('orders', (table) => {
    table.bigIncrements('id')
    table.bigInteger('customer_id').notNullable().references('id').inTable('customers')
    table.enu('status', ['draft', 'placed', 'paid', 'shipped', 'cancelled']).notNullable().defaultTo('draft')
    table.float('total').notNullable().defaultTo(0)
    table.timestamp('placed_at', { useTz: true })
    table.timestamps(true, true)
    table.index(['customer_id'])
    table.index(['created_at'])
  })
}

exports.down = function (knex) {
  return knex.schema.dropTable('orders')
}
