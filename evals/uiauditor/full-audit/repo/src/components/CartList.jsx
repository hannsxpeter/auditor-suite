import { useState } from 'react'

function CartRow({ item, onQuantity, onRemove }) {
  const [draft, setDraft] = useState(String(item.quantity))

  const commit = () => {
    const next = Math.max(1, Number(draft) || 1)
    setDraft(String(next))
    onQuantity(item.lineId, next)
  }

  return (
    <li className="flex flex-wrap items-center justify-between gap-4 py-3">
      <span className="text-ink">{item.name}</span>
      <label className="flex items-center gap-2 text-sm text-muted">
        Quantity
        <input
          type="number"
          min="1"
          inputMode="numeric"
          value={draft}
          onChange={(event) => setDraft(event.target.value)}
          onBlur={commit}
          className="w-16 rounded border border-gray-300 px-2 py-1"
        />
      </label>
      <span className="text-ink">${item.price * item.quantity}</span>
      <button type="button" onClick={() => onRemove(item.lineId)} className="px-2 py-1 text-sm text-brand-700 underline">
        Remove {item.name}
      </button>
    </li>
  )
}

export default function CartList({ items, onQuantity, onRemove }) {
  if (items.length === 0) {
    return <p className="py-4 text-muted">Your cart is empty.</p>
  }
  return (
    <ul role="list" className="divide-y divide-gray-200">
      {items.map((item, index) => (
        <CartRow key={index} item={item} onQuantity={onQuantity} onRemove={onRemove} />
      ))}
    </ul>
  )
}
