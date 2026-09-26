import { CDN } from '../data/products.js'

export default function Testimonial() {
  return (
    <figure className="my-10 rounded-2xl bg-brand-50 p-8">
      <img src={`${CDN}/decor/quote-mark.svg`} alt="" width="32" height="32" className="h-8 w-8" />
      <blockquote className="mt-4 text-lg text-ink">
        <p>The Ridge coat kept me warm through a week of winter camping, and it still looks new.</p>
      </blockquote>
      <figcaption className="mt-4 text-sm text-muted">Priya N., verified buyer</figcaption>
    </figure>
  )
}
