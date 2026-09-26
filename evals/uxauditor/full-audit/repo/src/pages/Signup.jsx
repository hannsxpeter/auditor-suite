import React, { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import MarketingConsent from '../components/MarketingConsent.jsx'

export default function Signup() {
  const navigate = useNavigate()
  const [account, setAccount] = useState({ name: '', email: '', password: '', company: '' })
  const [card, setCard] = useState({ number: '', expiry: '', cvc: '' })
  const [consent, setConsent] = useState({})
  const [error, setError] = useState('')
  const [pending, setPending] = useState(false)

  function update(field) {
    return (event) => setAccount({ ...account, [field]: event.target.value })
  }

  function updateCard(field) {
    return (event) => setCard({ ...card, [field]: event.target.value })
  }

  async function onSubmit(event) {
    event.preventDefault()
    setPending(true)
    const res = await fetch('/api/signup', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ ...account, card, consent }),
    })
    setPending(false)
    if (!res.ok) {
      setError('We could not create your account. Check the details below and try again.')
      return
    }
    navigate('/expenses/new')
  }

  return (
    <form onSubmit={onSubmit}>
      <h1>Start your 14-day free trial</h1>
      <p>Free for 14 days, then $8 per member each month. Cancel anytime from Settings.</p>
      {error && <p role="alert">{error}</p>}
      <label htmlFor="name">Your name</label>
      <input id="name" autoComplete="name" value={account.name} onChange={update('name')} required />
      <label htmlFor="email">Work email</label>
      <input id="email" type="email" autoComplete="email" value={account.email} onChange={update('email')} required />
      <label htmlFor="password">Password (at least 10 characters)</label>
      <input id="password" type="password" autoComplete="new-password" value={account.password} onChange={update('password')} required />
      <label htmlFor="company">Company name</label>
      <input id="company" autoComplete="organization" value={account.company} onChange={update('company')} required />
      <fieldset>
        <legend>Card details (required to start your trial)</legend>
        <label htmlFor="card-number">Card number</label>
        <input id="card-number" inputMode="numeric" autoComplete="cc-number" value={card.number} onChange={updateCard('number')} required />
        <label htmlFor="card-expiry">Expiry (MM/YY)</label>
        <input id="card-expiry" autoComplete="cc-exp" value={card.expiry} onChange={updateCard('expiry')} required />
        <label htmlFor="card-cvc">Security code</label>
        <input id="card-cvc" inputMode="numeric" autoComplete="cc-csc" value={card.cvc} onChange={updateCard('cvc')} required />
      </fieldset>
      <MarketingConsent value={consent} onChange={setConsent} />
      <button type="submit" disabled={pending}>{pending ? 'Creating your team...' : 'Start free trial'}</button>
    </form>
  )
}
