import type { MetadataRoute } from 'next'
import { allDocs } from '@/lib/docs'
import { SITE_URL } from '@/lib/seo'

export default function sitemap(): MetadataRoute.Sitemap {
  const now = new Date()
  const pages = ['', '/pricing', '/customers'].map((path) => ({
    url: `${SITE_URL}${path}`,
    lastModified: now,
  }))
  const docs = allDocs.map((doc) => ({
    url: `${SITE_URL}/docs/${doc.slug}`,
    lastModified: now,
  }))
  return [...pages, ...docs]
}
