module.exports = {
  jwtSecret: process.env.JWT_SECRET || 'dev-secret-change-me',
  tokenTtl: '12h',
  uploadDir: '/var/shopfront/uploads',
}
