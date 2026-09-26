export function SoftwareSchema() {
  const data = {
    '@context': 'https://schema.org',
    '@type': 'SoftwareApplication',
    name: 'Brightdesk',
    applicationCategory: 'BusinessApplication',
    operatingSystem: 'Web',
    offers: { '@type': 'Offer', price: '19.00', priceCurrency: 'USD' },
    aggregateRating: { '@type': 'AggregateRating', ratingValue: '4.9', ratingCount: '1287' },
  }

  return (
    <script
      type="application/ld+json"
      dangerouslySetInnerHTML={{ __html: JSON.stringify(data) }}
    />
  )
}
