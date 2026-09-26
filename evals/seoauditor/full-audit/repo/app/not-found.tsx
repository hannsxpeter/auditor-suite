import Link from 'next/link'

export default function NotFound() {
  return (
    <main>
      <h1>Page not found</h1>
      <p>The page you asked for does not exist.</p>
      <Link href="/">Back to the home page</Link>
    </main>
  )
}
