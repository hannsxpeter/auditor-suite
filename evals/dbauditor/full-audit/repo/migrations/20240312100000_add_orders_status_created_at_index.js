exports.up = function (knex) {
  return knex.schema.alterTable('orders', (table) => {
    table.index(['status', 'created_at'], 'orders_status_created_at_idx')
  })
}

exports.down = function (knex) {
  return knex.schema.alterTable('orders', (table) => {
    table.dropIndex(['status', 'created_at'], 'orders_status_created_at_idx')
  })
}
