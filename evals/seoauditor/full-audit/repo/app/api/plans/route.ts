import { NextResponse } from 'next/server'

const plans = [
  { name: 'Starter', monthlyPrice: 19, features: ['Shared inbox', 'Email and chat', 'Two automations'] },
  { name: 'Team', monthlyPrice: 39, features: ['Everything in Starter', 'Unlimited automations', 'Reports'] },
  { name: 'Business', monthlyPrice: 69, features: ['Everything in Team', 'Single sign-on', 'Priority support'] },
]

export function GET() {
  return NextResponse.json({ plans })
}
