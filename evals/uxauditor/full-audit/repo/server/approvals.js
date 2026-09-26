import { db, queueEmail, memberEmail } from './db.js'

const APPROVER_ROLES = ['owner', 'approver']

export function submitExpense(expense, submitter) {
  const approver = db.members.find(
    (m) => m.teamId === submitter.teamId && APPROVER_ROLES.includes(m.role) && m.id !== submitter.id
  )
  const record = {
    ...expense,
    id: db.nextId(),
    teamId: submitter.teamId,
    submittedBy: submitter.id,
    approverId: approver ? approver.id : null,
    status: 'pending_approval',
    submittedAt: new Date().toISOString(),
    version: 1,
  }
  db.expenses.push(record)
  if (approver) queueEmail(approver.email, 'approval-request', { expenseId: record.id })
  return record
}

export function decide(expenseId, actor, decision, expectedVersion) {
  const expense = db.expenses.find((e) => e.id === expenseId && e.teamId === actor.teamId)
  if (!expense) return { error: 'not_found' }
  if (!APPROVER_ROLES.includes(actor.role) || expense.submittedBy === actor.id) return { error: 'forbidden' }
  if (expense.status !== 'pending_approval') return { error: 'already_decided' }
  if (expense.version !== expectedVersion) return { error: 'conflict' }
  expense.status = decision === 'approve' ? 'approved' : 'returned'
  expense.decidedBy = actor.id
  expense.decidedAt = new Date().toISOString()
  expense.version += 1
  queueEmail(memberEmail(expense.submittedBy), `expense-${expense.status}`, { expenseId })
  return { expense }
}

export function resubmit(expenseId, actor, changes) {
  const expense = db.expenses.find((e) => e.id === expenseId && e.submittedBy === actor.id)
  if (!expense || expense.status !== 'returned') return { error: 'not_returned' }
  const { date, merchant, amount, category, notes, receiptId } = changes
  Object.assign(expense, { date, merchant, amount, category, notes, receiptId })
  expense.status = 'pending_approval'
  expense.version += 1
  if (expense.approverId) queueEmail(memberEmail(expense.approverId), 'approval-request', { expenseId })
  return { expense }
}

export function markPaid(expenseIds, payrollRunId) {
  for (const expense of db.expenses) {
    if (expenseIds.includes(expense.id) && expense.status === 'approved') {
      expense.status = 'paid'
      expense.payrollRunId = payrollRunId
      queueEmail(memberEmail(expense.submittedBy), 'expense-paid', { expenseId: expense.id })
    }
  }
}
