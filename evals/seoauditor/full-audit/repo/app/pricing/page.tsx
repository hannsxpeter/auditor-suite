'use client'

import { useEffect, useState } from 'react'

type Plan = {
  name: string
  monthlyPrice: number
  features: string[]
}

export default function PricingPage() {
  const [plans, setPlans] = useState<Plan[]>([])

  useEffect(() => {
    fetch('/api/plans')
      .then((res) => res.json())
      .then((data) => setPlans(data.plans))
  }, [])

  return (
    <main>
      <h1>Plans and pricing</h1>
      {plans.length === 0 ? (
        <p>Loading plans...</p>
      ) : (
        <div>
          {plans.map((plan) => (
            <section key={plan.name}>
              <h2>{plan.name}</h2>
              <p>${plan.monthlyPrice} per agent per month</p>
              <ul>
                {plan.features.map((feature) => (
                  <li key={feature}>{feature}</li>
                ))}
              </ul>
            </section>
          ))}
        </div>
      )}
    </main>
  )
}
