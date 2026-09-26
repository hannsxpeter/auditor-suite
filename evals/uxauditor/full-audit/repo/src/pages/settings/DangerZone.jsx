import React, { useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'

export default function DangerZone() {
  const navigate = useNavigate()
  const [error, setError] = useState('')

  async function deleteAccount() {
    const res = await fetch('/api/account', { method: 'DELETE' })
    if (!res.ok) {
      setError('Your account was not deleted. Try again, or contact support.')
      return
    }
    navigate('/signup')
  }

  return (
    <section className="account-settings">
      <h1>Account</h1>
      <p>
        Manage your plan on the <Link to="/settings/plan/cancel">plan page</Link> and email preferences under{' '}
        <Link to="/settings/notifications">notifications</Link>.
      </p>
      <h2>Delete your team account</h2>
      <p>This removes every member, expense, receipt, and report for your team.</p>
      {error && <p role="alert">{error}</p>}
      <button type="button" className="danger" onClick={deleteAccount}>
        Delete account
      </button>
    </section>
  )
}
