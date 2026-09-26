import SaleBadge from './SaleBadge.jsx'

export default function ProductCard({ product, onAdd, onPreview }) {
  return (
    <article className="flex h-full flex-col rounded-[var(--radius-card)] border border-gray-200 p-4">
      <img src={product.image} alt={product.alt} width="400" height="500" loading="lazy" className="w-full rounded-lg object-cover" />
      <h3 className="mt-3 font-semibold text-ink">{product.name}</h3>
      <p className="text-muted">
        ${product.price} {product.onSale ? <SaleBadge percent={product.discount} /> : null}
      </p>
      <div className="mt-auto flex gap-2 pt-4">
        <div className="flex-1 cursor-pointer rounded-lg bg-brand-600 px-4 py-2 text-center font-semibold text-white" onClick={() => onAdd(product)}>
          Add to cart
        </div>
        <button type="button" onClick={() => onPreview(product)} className="rounded-lg border border-gray-300 px-3 py-2 text-ink">
          Quick view
        </button>
      </div>
    </article>
  )
}
