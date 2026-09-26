import React, { useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'

export default function SignIn() {
  const navigate = useNavigate()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState('')
  const [pending, setPending] = useState(false)

  async function onSubmit(event) {
    event.preventDefault()
    setPending(true)
    setError('')
    const res = await fetch('/api/session', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password }),
    })
    setPending(false)
    if (!res.ok) {
      setError('That email and password do not match. Check them and try again.')
      return
    }
    navigate('/expenses/new')
  }

  return (
    <form onSubmit={onSubmit} noValidate>
      <h1>Sign in to Ledgerly</h1>
      {error && <p id="signin-error" role="alert">{error}</p>}
      <label htmlFor="email">Work email</label>
      <input
        id="email"
        type="email"
        autoComplete="email"
        value={email}
        onChange={(e) => setEmail(e.target.value)}
        aria-describedby={error ? 'signin-error' : undefined}
        required
      />
      <label htmlFor="password">Password</label>
      <input
        id="password"
        type="password"
        autoComplete="current-password"
        value={password}
        onChange={(e) => setPassword(e.target.value)}
        aria-describedby={error ? 'signin-error' : undefined}
        required
      />
      <button type="submit" disabled={pending}>{pending ? 'Signing in...' : 'Sign in'}</button>
      <p>
        New to Ledgerly? <Link to="/signup">Start a free trial</Link>
      </p>
    </form>
  )
}
