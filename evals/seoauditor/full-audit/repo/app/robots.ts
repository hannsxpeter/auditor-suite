import type { MetadataRoute } from 'next'

export default function robots(): MetadataRoute.Robots {
  return {
    rules: [
      { userAgent: '*', allow: '/', disallow: '/api/' },
      // Opt out of AI training.
      { userAgent: ['GPTBot', 'CCBot', 'OAI-SearchBot', 'PerplexityBot'], disallow: '/' },
    ],
    sitemap: 'https://www.brightdesk.example/sitemap.xml',
  }
}
