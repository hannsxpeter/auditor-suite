module.exports = {
  client: 'pg',
  connection: {
    connectionString: process.env.DATABASE_URL,
    ssl: { rejectUnauthorized: true },
  },
  pool: { min: 2, max: 10 },
  migrations: { directory: './migrations' },
}
