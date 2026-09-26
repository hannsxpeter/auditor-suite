import React, { useState } from 'react'
import UploadReceipt from '../components/UploadReceipt.jsx'

const EMPTY = { date: '', merchant: '', amount: '', category: 'travel', notes: '', receiptId: null }
const CATEGORIES = ['travel', 'meals', 'lodging', 'software', 'other']

function validate(values) {
  const found = {}
  if (!values.date) found.date = 'Enter the date on the receipt.'
  if (!values.merchant.trim()) found.merchant = 'Enter who you paid, for example Delta or Blue Bottle.'
  if (!(Number(values.amount) > 0)) found.amount = 'Enter an amount greater than zero, for example 42.50.'
  if (!values.receiptId) found.receiptId = 'Attach a photo or PDF of the receipt.'
  return found
}

export default function NewExpense() {
  const [form, setForm] = useState(EMPTY)
  const [errors, setErrors] = useState({})
  const [pending, setPending] = useState(false)
  const [submitted, setSubmitted] = useState(null)

  function update(field) {
    return (event) => setForm({ ...form, [field]: event.target.value })
  }

  async function onSubmit(event) {
    event.preventDefault()
    const found = validate(form)
    if (Object.keys(found).length > 0) {
      setErrors(found)
      setForm(EMPTY)
      return
    }
    setErrors({})
    setPending(true)
    const res = await fetch('/api/expenses', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ ...form, amount: Number(form.amount) }),
    })
    setPending(false)
    if (!res.ok) {
      setErrors({ form: 'We could not save this expense. Your details are still here; try again in a moment.' })
      return
    }
    setSubmitted(await res.json())
  }

  if (submitted) {
    return (
      <section>
        <h1>Expense sent for approval</h1>
        <p role="status">
          {submitted.merchant} for {submitted.amountFormatted} is waiting for your approver. We will email you when it is approved or returned.
        </p>
        <button type="button" onClick={() => { setSubmitted(null); setForm(EMPTY) }}>Add another expense</button>
      </section>
    )
  }

  return (
    <form onSubmit={onSubmit} noValidate>
      <h1>New expense</h1>
      {errors.form && <p role="alert">{errors.form}</p>}
      <label htmlFor="date">Date on the receipt</label>
      <input id="date" type="date" value={form.date} onChange={update('date')} aria-describedby={errors.date ? "date-error" : undefined} aria-invalid={Boolean(errors.date)} />
      {errors.date && <p id="date-error" className="field-error">{errors.date}</p>}
      <label htmlFor="merchant">Merchant</label>
      <input id="merchant" value={form.merchant} onChange={update('merchant')} aria-describedby={errors.merchant ? "merchant-error" : undefined} aria-invalid={Boolean(errors.merchant)} />
      {errors.merchant && <p id="merchant-error" className="field-error">{errors.merchant}</p>}
      <label htmlFor="amount">Amount (USD)</label>
      <input id="amount" inputMode="decimal" value={form.amount} onChange={update('amount')} aria-describedby={errors.amount ? "amount-error" : undefined} aria-invalid={Boolean(errors.amount)} />
      {errors.amount && <p id="amount-error" className="field-error">{errors.amount}</p>}
      <label htmlFor="category">Category</label>
      <select id="category" value={form.category} onChange={update('category')}>
        {CATEGORIES.map((c) => <option key={c} value={c}>{c}</option>)}
      </select>
      <label htmlFor="notes">Notes (optional)</label>
      <textarea id="notes" value={form.notes} onChange={update('notes')} />
      <UploadReceipt onUploaded={(receiptId) => setForm({ ...form, receiptId })} />
      {errors.receiptId && <p className="field-error">{errors.receiptId}</p>}
      <button type="submit" disabled={pending}>{pending ? 'Sending...' : 'Send for approval'}</button>
    </form>
  )
}
