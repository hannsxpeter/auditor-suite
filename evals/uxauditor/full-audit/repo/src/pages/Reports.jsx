import React, { useEffect, useState } from 'react'
import BulkDeleteDialog from '../components/BulkDeleteDialog.jsx'

export default function Reports() {
  const [reports, setReports] = useState(null)
  const [loadError, setLoadError] = useState(false)
  const [selected, setSelected] = useState([])
  const [confirming, setConfirming] = useState(false)

  useEffect(() => {
    fetch('/api/reports')
      .then((res) => (res.ok ? res.json() : Promise.reject(new Error('reports request failed'))))
      .then(setReports)
      .catch(() => setLoadError(true))
  }, [])

  if (loadError) return <p role="alert">We could not load your reports. Refresh the page to try again.</p>
  if (reports === null) return <p role="status">Loading reports...</p>
  if (reports.length === 0) {
    return (
      <section>
        <h1>Monthly reports</h1>
        <p className="empty">No data</p>
      </section>
    )
  }

  function toggle(id) {
    setSelected(selected.includes(id) ? selected.filter((x) => x !== id) : [...selected, id])
  }

  function removeDeleted(ids) {
    setReports(reports.filter((report) => !ids.includes(report.id)))
    setSelected([])
    setConfirming(false)
  }

  return (
    <section>
      <h1>Monthly reports</h1>
      <table>
        <thead>
          <tr>
            <th scope="col">Select</th>
            <th scope="col">Month</th>
            <th scope="col">Total</th>
            <th scope="col">Status</th>
          </tr>
        </thead>
        <tbody>
          {reports.map((report) => (
            <tr key={report.id}>
              <td>
                {report.status === 'archived' && (
                  <input
                    type="checkbox"
                    aria-label={`Select the ${report.month} report`}
                    checked={selected.includes(report.id)}
                    onChange={() => toggle(report.id)}
                  />
                )}
              </td>
              <td>{report.month}</td>
              <td>{report.totalFormatted}</td>
              <td>{report.statusLabel}</td>
            </tr>
          ))}
        </tbody>
      </table>
      <button type="button" disabled={selected.length === 0} onClick={() => setConfirming(true)}>
        Delete selected archived reports
      </button>
      {confirming && (
        <BulkDeleteDialog reportIds={selected} onDeleted={removeDeleted} onCancel={() => setConfirming(false)} />
      )}
    </section>
  )
}
