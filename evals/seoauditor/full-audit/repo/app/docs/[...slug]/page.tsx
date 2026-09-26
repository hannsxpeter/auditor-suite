import type { Metadata } from 'next'
import { findDoc } from '@/lib/docs'
import { pageMetadata } from '@/lib/seo'

type Props = { params: Promise<{ slug: string[] }> }

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { slug } = await params
  const doc = findDoc(slug.join('/'))
  return pageMetadata({
    title: doc ? doc.title : 'Help center',
    description: doc ? doc.summary : 'Guides for setting up and using Brightdesk.',
    path: `/docs/${slug.join('/')}`,
  })
}

export default async function DocPage({ params }: Props) {
  const { slug } = await params
  const doc = findDoc(slug.join('/'))

  if (!doc) {
    return (
      <main>
        <h1>Article not found</h1>
        <p>This help article may have moved. Try the search box above.</p>
      </main>
    )
  }

  return (
    <main>
      <article>
        <h1>{doc.title}</h1>
        <p>
          Last updated <time dateTime={doc.updatedAt}>{doc.updatedAt}</time>
        </p>
        {doc.sections.map((section) => (
          <section key={section.heading}>
            <h2>{section.heading}</h2>
            <p>{section.text}</p>
          </section>
        ))}
      </article>
    </main>
  )
}
