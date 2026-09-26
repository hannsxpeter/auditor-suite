'use client'

import { useEffect, useState } from 'react'
import Script from 'next/script'

// Skip analytics for crawlers and uptime checks so they do not count as visits.
const NON_HUMAN = /bot|crawler|spider|lighthouse|pingdom/i

export function Analytics() {
  const [enabled, setEnabled] = useState(false)

  useEffect(() => {
    setEnabled(!NON_HUMAN.test(navigator.userAgent))
  }, [])

  if (!enabled) {
    return null
  }
  return (
    <Script
      src="https://plausible.io/js/script.js"
      data-domain="brightdesk.example"
      strategy="afterInteractive"
    />
  )
}
