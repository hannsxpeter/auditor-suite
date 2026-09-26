export const CDN = 'https://cdn.lumen-store.example'

export const products = [
  {
    id: 'p-101',
    name: 'Ridge wool coat',
    price: 219,
    onSale: false,
    image: `${CDN}/products/ridge-coat-800.webp`,
    alt: 'Ridge wool coat in forest green, front view',
  },
  {
    id: 'p-102',
    name: 'Summit fleece',
    price: 89,
    onSale: true,
    discount: 20,
    image: `${CDN}/products/summit-fleece-800.webp`,
    alt: 'Summit fleece in rust orange with a half zip',
  },
  {
    id: 'p-103',
    name: 'Tarn rain shell',
    price: 159,
    onSale: false,
    image: `${CDN}/products/tarn-shell-800.webp`,
    alt: 'Tarn rain shell in navy with the hood up',
  },
  {
    id: 'p-104',
    name: 'Cairn merino beanie',
    price: 29,
    onSale: true,
    discount: 15,
    image: `${CDN}/products/cairn-beanie-800.webp`,
    alt: 'Cairn merino beanie in heather gray',
  },
]
