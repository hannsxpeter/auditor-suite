import type { Metadata } from 'next'
import { pageMetadata } from '@/lib/seo'

const stories = [
  { company: 'Harbor Coffee Roasters', quote: 'We cut our first-reply time from a day to two hours.' },
  { company: 'Northwind Bikes', quote: 'Three people now handle the inbox that used to need five.' },
]

export const metadata: Metadata = pageMetadata({
  title: 'Customer stories',
  description: 'How small support teams use Brightdesk to answer customers faster.',
  path: '/customers',
  image: 'http://localhost:3000/og/customers.png',
})

export default function CustomersPage() {
  return (
    <main>
      <h1>Customer stories</h1>
      {stories.map((story) => (
        <article key={story.company}>
          <h2>{story.company}</h2>
          <blockquote>{story.quote}</blockquote>
        </article>
      ))}
    </main>
  )
}
