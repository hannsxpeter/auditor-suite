import type { Metadata } from 'next'

export const SITE_URL = 'https://www.brightdesk.example'

type PageSeo = {
  title: string
  description: string
  path: string
  image?: string
}

export function pageMetadata({ title, description, path, image = '/og/default.png' }: PageSeo): Metadata {
  return {
    title,
    description,
    alternates: { canonical: SITE_URL },
    openGraph: {
      title,
      description,
      url: `${SITE_URL}${path}`,
      siteName: 'Brightdesk',
      type: 'website',
      images: [{ url: image, width: 1200, height: 630 }],
    },
  }
}
