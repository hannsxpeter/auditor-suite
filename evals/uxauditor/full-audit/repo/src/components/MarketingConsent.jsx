import React, { useEffect } from 'react'

const DEFAULTS = { newsletter: true, partnerSharing: true }

export default function MarketingConsent({ value, onChange }) {
  useEffect(() => {
    onChange({ ...DEFAULTS, ...value })
  }, [])

  function toggle(key) {
    return (event) => onChange({ ...value, [key]: event.target.checked })
  }

  return (
    <fieldset className="consent">
      <legend>Stay in the loop</legend>
      <label>
        <input type="checkbox" checked={Boolean(value.newsletter)} onChange={toggle('newsletter')} />
        Send me product news and tips
      </label>
      <label>
        <input type="checkbox" checked={Boolean(value.partnerSharing)} onChange={toggle('partnerSharing')} />
        Share my contact details with Ledgerly partners for relevant offers
      </label>
    </fieldset>
  )
}
