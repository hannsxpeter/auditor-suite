import express from 'express'
import { randomBytes, scryptSync, timingSafeEqual } from 'node:crypto'
import { db, queueEmail, NOTIFICATION_DEFAULTS } from './db.js'
import { submitExpense, decide } from './approvals.js'

const app = express()
app.use(express.json({ limit: '100kb' }))

const TRIAL_DAYS = 14
const MAX_RECEIPT_BYTES = 10 * 1024 * 1024

function hashPassword(password, salt) {
  return scryptSync(password, salt, 32).toString('hex')
}

function sessionToken(req) {
  const pair = (req.get('cookie') || '').split('; ').find((c) => c.startsWith('session='))
  return pair ? pair.slice('session='.length) : null
}

function requireMember(req, res, next) {
  const token = sessionToken(req)
  const member = token && db.members.find((m) => m.sessionToken === token)
  if (!member) return res.status(401).json({ code: 'AUTH_REQUIRED' })
  req.member = member
  next()
}

function startSession(res, member) {
  member.sessionToken = randomBytes(24).toString('hex')
  res.cookie('session', member.sessionToken, { httpOnly: true, sameSite: 'lax', secure: true })
}

app.post('/api/signup', (req, res) => {
  const { name, email, password, company, card, consent } = req.body
  if (!name || !email || !company || !password || password.length < 10 || !card || !card.number) {
    return res.status(400).json({ code: 'SIGNUP_INVALID' })
  }
  const team = {
    id: db.nextId(),
    name: company,
    plan: 'team',
    trialEndsAt: new Date(Date.now() + TRIAL_DAYS * 86400000).toISOString(),
    cardLast4: String(card.number).replace(/[^0-9]/g, '').slice(-4),
  }
  db.teams.push(team)
  const salt = randomBytes(16).toString('hex')
  const member = { id: db.nextId(), teamId: team.id, name, email, role: 'owner', salt, passwordHash: hashPassword(password, salt), consent }
  db.members.push(member)
  startSession(res, member)
  res.status(201).json({ id: member.id })
})

app.post('/api/session', (req, res) => {
  const member = db.members.find((m) => m.email === req.body.email)
  const given = member ? Buffer.from(hashPassword(String(req.body.password || ''), member.salt), 'hex') : null
  if (!member || !timingSafeEqual(given, Buffer.from(member.passwordHash, 'hex'))) {
    return res.status(401).json({ code: 'SIGNIN_FAILED' })
  }
  startSession(res, member)
  res.json({ id: member.id })
})

app.get('/api/me', requireMember, (req, res) => {
  res.json({ id: req.member.id, name: req.member.name, role: req.member.role })
})

app.get('/api/me/notifications', requireMember, (req, res) => {
  res.json(db.notificationPrefs.get(req.member.id) || NOTIFICATION_DEFAULTS)
})

app.put('/api/me/notifications', requireMember, (req, res) => {
  const prefs = {}
  for (const key of Object.keys(NOTIFICATION_DEFAULTS)) prefs[key] = Boolean(req.body[key])
  db.notificationPrefs.set(req.member.id, prefs)
  res.json(prefs)
})

app.post('/api/receipts', requireMember, (req, res) => {
  if (Number(req.get('content-length') || 0) > MAX_RECEIPT_BYTES) return res.status(413).json({ code: 'RCPT_E413' })
  if (!(req.get('content-type') || '').startsWith('multipart/form-data')) return res.status(415).json({ code: 'RCPT_E415' })
  const receipt = { id: db.nextId(), teamId: req.member.teamId, uploadedBy: req.member.id }
  db.receipts.push(receipt)
  res.status(201).json({ id: receipt.id })
})

app.post('/api/expenses', requireMember, (req, res) => {
  const { date, merchant, amount, category, notes, receiptId } = req.body
  if (!date || !merchant || !(amount > 0) || !receiptId) return res.status(400).json({ code: 'EXPENSE_INVALID' })
  const record = submitExpense({ date, merchant, amount, category, notes, receiptId }, req.member)
  res.status(201).json({ ...record, amountFormatted: `$${amount.toFixed(2)}` })
})

app.post('/api/expenses/:id/decision', requireMember, (req, res) => {
  const result = decide(Number(req.params.id), req.member, req.body.decision, req.body.version)
  if (result.error === 'not_found') return res.status(404).json({ code: 'EXPENSE_NOT_FOUND' })
  if (result.error === 'forbidden') return res.status(403).json({ code: 'DECISION_FORBIDDEN' })
  if (result.error) return res.status(409).json({ code: 'DECISION_CONFLICT' })
  res.json(result.expense)
})

app.get('/api/reports', requireMember, (req, res) => {
  res.json(db.reports.filter((r) => r.teamId === req.member.teamId))
})

app.delete('/api/reports', requireMember, (req, res) => {
  const ids = Array.isArray(req.body.ids) ? req.body.ids : []
  db.reports = db.reports.filter((r) => !(r.teamId === req.member.teamId && r.status === 'archived' && ids.includes(r.id)))
  res.status(204).end()
})

app.post('/api/invites', requireMember, (req, res) => {
  const { email, role } = req.body
  if (!email || !['member', 'approver'].includes(role)) return res.status(400).json({ code: 'INVITE_INVALID' })
  const invite = { id: db.nextId(), teamId: req.member.teamId, email, role, invitedBy: req.member.id }
  db.invites.push(invite)
  queueEmail(email, 'team-invite', { inviteId: invite.id })
  res.status(201).json(invite)
})

app.delete('/api/account', requireMember, (req, res) => {
  if (req.member.role !== 'owner') return res.status(403).json({ code: 'OWNER_ONLY' })
  const teamId = req.member.teamId
  for (const table of ['members', 'expenses', 'receipts', 'reports', 'invites']) {
    db[table] = db[table].filter((row) => row.teamId !== teamId)
  }
  db.teams = db.teams.filter((team) => team.id !== teamId)
  res.status(204).end()
})

app.listen(process.env.PORT || 3000)
