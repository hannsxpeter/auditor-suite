import type { Metadata } from 'next'
import type { ReactNode } from 'react'
import { cookies } from 'next/headers'
import { redirect } from 'next/navigation'

// Signed-in customer area: account settings and inbox configuration.
export const metadata: Metadata = {
  title: 'Dashboard',
  robots: { index: false, follow: false },
}

export default async function DashboardLayout({ children }: { children: ReactNode }) {
  const session = (await cookies()).get('bd_session')
  if (!session) {
    redirect('https://app.brightdesk.example/login')
  }
  return <div className="dashboard">{children}</div>
}
