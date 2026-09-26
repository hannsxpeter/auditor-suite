import React, { useEffect, useRef, useState } from 'react'

export default function BulkDeleteDialog({ reportIds, onDeleted, onCancel }) {
  const ref = useRef(null)
  const [typed, setTyped] = useState('')
  const [pending, setPending] = useState(false)
  const [error, setError] = useState('')
  const phrase = `delete ${reportIds.length} reports`

  useEffect(() => {
    ref.current.showModal()
  }, [])

  async function confirmDelete() {
    setPending(true)
    setError('')
    const res = await fetch('/api/reports', {
      method: 'DELETE',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ ids: reportIds }),
    })
    setPending(false)
    if (!res.ok) {
      setError('The reports were not deleted. Try again, or contact support if it keeps failing.')
      return
    }
    ref.current.close()
    onDeleted(reportIds)
  }

  return (
    <dialog ref={ref} aria-labelledby="bulk-delete-title" onCancel={onCancel}>
      <h2 id="bulk-delete-title">Permanently delete {reportIds.length} archived reports?</h2>
      <p>Deleted reports and their receipts cannot be recovered. PDFs you already exported are not affected.</p>
      <label htmlFor="bulk-delete-confirm">Type "{phrase}" to confirm</label>
      <input id="bulk-delete-confirm" value={typed} onChange={(e) => setTyped(e.target.value)} autoComplete="off" />
      {error && <p role="alert">{error}</p>}
      <button type="button" onClick={() => { ref.current.close(); onCancel() }}>Keep the reports</button>
      <button type="button" className="danger" disabled={typed !== phrase || pending} onClick={confirmDelete}>
        {pending ? 'Deleting...' : `Delete ${reportIds.length} reports`}
      </button>
    </dialog>
  )
}
