import { CDN } from '../data/products.js'

export default function Hero() {
  return (
    <section className="relative mt-6 overflow-hidden rounded-2xl">
      <img
        src={`${CDN}/campaigns/autumn-hero-1600.webp`}
        alt="Two hikers in wool coats on a ridge at sunrise"
        loading="lazy"
        className="w-full object-cover"
      />
      <div className="absolute inset-0 flex flex-col justify-end bg-gradient-to-t from-black/70 to-transparent p-8">
        <h1 className="text-4xl font-bold text-white">Built for the cold months</h1>
        <p className="mt-2 max-w-md text-lg text-white">Wool coats, fleece, and waterproof shells, tested on the ridge.</p>
        <a href="/new" className="mt-4 inline-block w-fit rounded-lg bg-white px-5 py-3 font-semibold text-ink">
          Shop the collection
        </a>
      </div>
    </section>
  )
}
