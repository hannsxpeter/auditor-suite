import React from 'react'
import { createRoot } from 'react-dom/client'
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import NavBar from './components/NavBar.jsx'
import InviteForm from './components/InviteForm.jsx'
import SignIn from './pages/SignIn.jsx'
import Signup from './pages/Signup.jsx'
import NewExpense from './pages/NewExpense.jsx'
import Reports from './pages/Reports.jsx'
import DangerZone from './pages/settings/DangerZone.jsx'
import CancelPlan from './pages/settings/CancelPlan.jsx'
import Notifications from './pages/settings/Notifications.jsx'

function App() {
  return (
    <BrowserRouter>
      <NavBar />
      <main>
        <Routes>
          <Route path="/" element={<Navigate to="/expenses/new" replace />} />
          <Route path="/signin" element={<SignIn />} />
          <Route path="/signup" element={<Signup />} />
          <Route path="/expenses/new" element={<NewExpense />} />
          <Route path="/reports" element={<Reports />} />
          <Route path="/settings/team" element={<InviteForm />} />
          <Route path="/settings/notifications" element={<Notifications />} />
          <Route path="/settings/account" element={<DangerZone />} />
          <Route path="/settings/plan/cancel" element={<CancelPlan />} />
        </Routes>
      </main>
    </BrowserRouter>
  )
}

createRoot(document.getElementById('root')).render(<App />)
