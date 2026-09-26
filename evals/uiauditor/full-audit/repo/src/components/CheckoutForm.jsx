import { useState } from 'react'

export default function CheckoutForm({ total }) {
  const [form, setForm] = useState({ email: '', name: '', card: '' })
  const [status, setStatus] = useState('idle')

  const update = (field) => (event) => setForm({ ...form, [field]: event.target.value })

  const submit = async (event) => {
    event.preventDefault()
    setStatus('sending')
    try {
      const response = await fetch('/api/orders', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ ...form, total }),
      })
      setStatus(response.ok ? 'done' : 'error')
    } catch {
      setStatus('error')
    }
  }

  return (
    <form onSubmit={submit} className="mt-6 grid max-w-md gap-3">
      <input type="email" autoComplete="email" placeholder="Email" value={form.email} onChange={update('email')} required className="rounded-lg border border-gray-300 px-3 py-2" />
      <input type="text" autoComplete="cc-name" placeholder="Name on card" value={form.name} onChange={update('name')} required className="rounded-lg border border-gray-300 px-3 py-2" />
      <input type="text" inputMode="numeric" autoComplete="cc-number" placeholder="Card number" value={form.card} onChange={update('card')} required className="rounded-lg border border-gray-300 px-3 py-2" />
      <p className="text-ink">Total: ${total}</p>
      <button type="submit" disabled={status === 'sending'} className="rounded-lg bg-brand-600 px-4 py-2 font-semibold text-white disabled:opacity-60">
        {status === 'sending' ? 'Placing order' : 'Place order'}
      </button>
      <p role="status" className="text-sm text-muted">
        {status === 'done' && 'Order placed. A receipt is on its way to your inbox.'}
        {status === 'error' && 'We could not place the order. Check your details and try again.'}
      </p>
    </form>
  )
}
