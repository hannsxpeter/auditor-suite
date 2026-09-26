/** @type {import('next').NextConfig} */
const nextConfig = {
  images: {
    formats: ['image/avif', 'image/webp'],
  },
  async redirects() {
    return [
      // URLs renamed in the 2025 site restructure.
      { source: '/plans', destination: '/pricing', permanent: true },
      { source: '/help/:path*', destination: '/docs/:path*', permanent: true },
    ]
  },
}

export default nextConfig
