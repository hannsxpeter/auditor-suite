// In-memory store for local development. Production uses the same shapes in Postgres.
let counter = 1000

export const db = {
  teams: [],
  members: [],
  expenses: [],
  receipts: [],
  reports: [],
  invites: [],
  notificationPrefs: new Map(),
  nextId: () => ++counter,
}

export const NOTIFICATION_DEFAULTS = { approvalAlerts: true, approvalRequests: true, productNews: false }

const outbox = []

export function queueEmail(to, template, data) {
  outbox.push({ to, template, data, queuedAt: new Date().toISOString() })
}

export function memberEmail(memberId) {
  const member = db.members.find((m) => m.id === memberId)
  return member ? member.email : null
}
