import Image from 'next/image'
import Link from 'next/link'
import { pageMetadata } from '@/lib/seo'
import { SoftwareSchema } from '@/components/SoftwareSchema'

export const metadata = pageMetadata({
  title: 'Shared inbox and help desk for small support teams',
  description: 'Brightdesk puts email, chat, and social messages in one shared inbox so a small team can answer every customer on time.',
  path: '/',
})

export default function HomePage() {
  return (
    <main>
      <section>
        <h1>One shared inbox for your whole support team</h1>
        <p>Assign conversations, see who is replying, and never answer the same customer twice.</p>
        <Link href="/pricing">See plans and pricing</Link>
        <Image
          src="/images/hero-inbox.png"
          alt="The Brightdesk inbox with three open customer conversations"
          width={1200}
          height={720}
          loading="lazy"
        />
      </section>
      <section>
        <h2>Built for teams of two to twenty</h2>
        <ul>
          <li>One inbox for email, chat, and social messages</li>
          <li>Collision detection, so two people never reply at once</li>
          <li>Automations that tag and route new conversations</li>
        </ul>
      </section>
      <SoftwareSchema />
    </main>
  )
}
