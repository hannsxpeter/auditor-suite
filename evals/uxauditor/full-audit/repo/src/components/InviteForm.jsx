import React, { useState } from 'react'

export default function InviteForm() {
  const [email, setEmail] = useState('')
  const [role, setRole] = useState('member')
  const [notice, setNotice] = useState('')

  async function onSubmit(event) {
    event.preventDefault()
    setNotice('')
    const res = await fetch('/api/invites', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, role }),
    })
    if (!res.ok) {
      setNotice('The invite was not sent. Check the email address and try again.')
      return
    }
    setNotice(`Invite sent to ${email}. It stays valid for 7 days.`)
    setEmail('')
  }

  return (
    <section>
      <h1>Team members</h1>
      <p>Invite the people who submit or approve expenses. Each member is billed from the day they join.</p>
      <form onSubmit={onSubmit}>
        <label htmlFor="invite-email">Email address</label>
        <input id="invite-email" type="email" value={email} onChange={(e) => setEmail(e.target.value)} required />
        <label htmlFor="invite-role">Role</label>
        <select id="invite-role" value={role} onChange={(e) => setRole(e.target.value)}>
          <option value="member">Member: submits expenses</option>
          <option value="approver">Approver: approves the team's expenses</option>
        </select>
        <button type="submit">Send invite</button>
      </form>
      {notice && <p role="status">{notice}</p>}
    </section>
  )
}
