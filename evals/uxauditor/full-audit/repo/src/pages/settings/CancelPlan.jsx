import React, { useState } from 'react'
import { Link } from 'react-router-dom'

const REASONS = ['Too expensive', 'Missing a feature', 'Switching to another tool', 'Other']

export default function CancelPlan() {
  const [step, setStep] = useState(1)
  const [reason, setReason] = useState('')
  const [details, setDetails] = useState('')

  if (step === 1) {
    return (
      <section>
        <h1>Before you go</h1>
        <p>Tell us why you want to cancel. An answer is required.</p>
        {REASONS.map((r) => (
          <label key={r}>
            <input type="radio" name="reason" value={r} checked={reason === r} onChange={() => setReason(r)} /> {r}
          </label>
        ))}
        <label htmlFor="details">What could we have done better? (at least 40 characters)</label>
        <textarea id="details" value={details} onChange={(e) => setDetails(e.target.value)} />
        <button type="button" disabled={!reason || details.length < 40} onClick={() => setStep(2)}>
          Continue
        </button>
      </section>
    )
  }

  if (step === 2) {
    return (
      <section>
        <h1>Stay for half price</h1>
        <p>Keep Ledgerly Team for $4 per member each month for the next 3 months.</p>
        <Link to="/reports" className="button button-primary">Keep my plan at 50% off</Link>
        <button type="button" onClick={() => setStep(3)}>No thanks, continue</button>
      </section>
    )
  }

  if (step === 3) {
    return (
      <section>
        <h1>Your approval history will be locked</h1>
        <p>Reports, receipts, and the approval trail become read-only 30 days after your plan ends.</p>
        <Link to="/reports" className="button button-primary">Keep my plan</Link>
        <button type="button" onClick={() => setStep(4)}>I understand, continue</button>
      </section>
    )
  }

  return (
    <section>
      <h1>One last step</h1>
      <p>
        To cancel, call our billing team at 1-800-555-0199, Monday to Friday, 9am to 5pm Eastern. Your plan keeps
        renewing until the call is complete.
      </p>
    </section>
  )
}
