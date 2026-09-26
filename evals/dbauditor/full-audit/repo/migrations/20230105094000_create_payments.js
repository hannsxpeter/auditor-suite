exports.up = function (knex) {
  return knex.schema.createTable('payments', (table) => {
    table.bigIncrements('id')
    table.bigInteger('order_id').notNullable()
    table.decimal('amount', 12, 2).notNullable()
    table.enu('status', ['pending', 'succeeded', 'failed']).notNullable()
    table.string('provider_ref', 64).notNullable()
    table.timestamps(true, true)
    table.index(['order_id'])
    table.unique(['provider_ref'])
  })
}

exports.down = function (knex) {
  return knex.schema.dropTable('payments')
}
