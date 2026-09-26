export default function QuickViewModal({ product, onClose, onAdd }) {
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
      <div className="max-h-full w-full max-w-lg overflow-y-auto rounded-2xl bg-white p-6 shadow-xl">
        <div className="flex items-start justify-between gap-4">
          <h2 className="text-xl font-semibold text-ink">{product.name}</h2>
          <button type="button" onClick={onClose} className="rounded-md px-3 py-2 text-sm text-ink hover:bg-brand-50">
            Close
          </button>
        </div>
        <img src={product.image} alt={product.alt} width="400" height="500" className="mt-4 w-full rounded-lg object-cover" />
        <p className="mt-4 text-muted">${product.price}</p>
        <button
          type="button"
          onClick={() => {
            onAdd(product)
            onClose()
          }}
          className="mt-4 w-full rounded-lg bg-brand-600 px-4 py-2 font-semibold text-white"
        >
          Add to cart
        </button>
      </div>
    </div>
  )
}
