import type { Metadata } from 'next'
import type { ReactNode } from 'react'
import Link from 'next/link'
import { Analytics } from '@/components/Analytics'

export const metadata: Metadata = {
  metadataBase: new URL('https://www.brightdesk.example'),
  title: { default: 'Brightdesk', template: '%s | Brightdesk' },
  description: 'Shared inbox and help desk software for small support teams.',
  // Keep preview deployments out of search results.
  robots: process.env.VERCEL_ENV !== 'preview' ? { index: false, follow: false } : { index: true, follow: true },
}

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="en">
      <body>
        <header>
          <nav>
            <Link href="/">Brightdesk</Link>
            <Link href="/pricing">Pricing</Link>
            <Link href="/customers">Customers</Link>
            <Link href="/docs/getting-started">Help center</Link>
          </nav>
        </header>
        {children}
        <footer>
          <p>Brightdesk Inc., Portland, Oregon</p>
        </footer>
        <Analytics />
      </body>
    </html>
  )
}
