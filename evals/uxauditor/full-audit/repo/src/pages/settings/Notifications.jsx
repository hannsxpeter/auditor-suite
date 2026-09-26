import React, { useEffect, useState } from 'react'

const LABELS = {
  approvalAlerts: 'Email me when an expense I submitted is approved or returned',
  approvalRequests: 'Email me when an expense is waiting for my approval',
  productNews: 'Send me product news and tips',
}

export default function Notifications() {
  const [prefs, setPrefs] = useState(null)
  const [status, setStatus] = useState('')

  useEffect(() => {
    fetch('/api/me/notifications')
      .then((res) => (res.ok ? res.json() : Promise.reject(new Error('preferences request failed'))))
      .then(setPrefs)
      .catch(() => setStatus('We could not load your email settings. Refresh the page to try again.'))
  }, [])

  async function save(key, event) {
    const checked = event.target.checked
    const res = await fetch('/api/me/notifications', {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ ...prefs, [key]: checked }),
    })
    if (!res.ok) {
      event.target.checked = !checked
      setStatus('Your change was not saved. Try again.')
      return
    }
    setPrefs(await res.json())
    setStatus('Saved.')
  }

  if (!prefs) return <p role="status">{status || 'Loading your email settings...'}</p>

  return (
    <section>
      <h1>Email notifications</h1>
      {Object.keys(LABELS).map((key) => (
        <label key={key}>
          <input type="checkbox" defaultChecked={prefs[key]} onChange={(event) => save(key, event)} />
          {LABELS[key]}
        </label>
      ))}
      <p role="status">{status}</p>
    </section>
  )
}
