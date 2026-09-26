import { CDN } from '../data/products.js'

export default function SizeGuide() {
  return (
    <section aria-labelledby="size-heading" className="py-10">
      <h2 id="size-heading" className="text-2xl font-semibold text-ink">Find your size</h2>
      <p className="mt-2 text-muted">Measure your chest and waist, then match them to the chart below.</p>
      <img src={`${CDN}/guides/size-chart-coats.png`} width="960" height="540" className="mt-6 w-full max-w-3xl rounded-lg border border-gray-200" />
    </section>
  )
}
