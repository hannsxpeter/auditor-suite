import React, { useState } from 'react'

export default function UploadReceipt({ onUploaded }) {
  const [status, setStatus] = useState('idle')
  const [message, setMessage] = useState('')

  async function onFile(event) {
    const file = event.target.files[0]
    if (!file) return
    setStatus('uploading')
    setMessage('')
    const body = new FormData()
    body.append('receipt', file)
    const res = await fetch('/api/receipts', { method: 'POST', body })
    const data = await res.json()
    if (!res.ok) {
      setStatus('failed')
      setMessage(`Upload failed: ${data.code} (${res.status})`)
      return
    }
    setStatus('done')
    setMessage(`Attached ${file.name}`)
    onUploaded(data.id)
  }

  return (
    <div className="receipt">
      <label htmlFor="receipt">Receipt (photo or PDF, up to 10 MB)</label>
      <input id="receipt" type="file" accept="image/*,application/pdf" onChange={onFile} />
      {status === 'uploading' && <p role="status">Uploading...</p>}
      {message && <p role={status === 'failed' ? 'alert' : 'status'}>{message}</p>}
    </div>
  )
}
