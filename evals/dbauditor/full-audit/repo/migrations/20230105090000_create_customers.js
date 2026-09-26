exports.up = function (knex) {
  return knex.schema.createTable('customers', (table) => {
    table.bigIncrements('id')
    table.string('email', 320).notNullable()
    table.string('name', 200).notNullable()
    table.decimal('credit_balance', 12, 2).notNullable().defaultTo(0)
    table.timestamps(true, true)
    table.check('?? >= 0', ['credit_balance'], 'customers_credit_balance_nonnegative')
  })
}

exports.down = function (knex) {
  return knex.schema.dropTable('customers')
}
