import React, { useEffect, useState } from 'react'
import { NavLink, Link } from 'react-router-dom'

export default function NavBar() {
  const [member, setMember] = useState(null)

  useEffect(() => {
    fetch('/api/me')
      .then((res) => (res.ok ? res.json() : null))
      .then(setMember)
      .catch(() => setMember(null))
  }, [])

  return (
    <header className="navbar">
      <Link to="/" className="brand">Ledgerly</Link>
      <nav aria-label="Main">
        <NavLink to="/expenses/new">New expense</NavLink>
        <NavLink to="/reports">Reports</NavLink>
        <NavLink to="/settings/team">Team</NavLink>
        <NavLink to="/settings/account">Account</NavLink>
      </nav>
      {member ? (
        <span className="navbar-member">{member.name}</span>
      ) : (
        <Link to="/signin" className="navbar-cta">Log in</Link>
      )}
    </header>
  )
}
