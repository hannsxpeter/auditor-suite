function CartIcon() {
  return (
    <svg aria-hidden="true" focusable="false" viewBox="0 0 24 24" className="h-6 w-6">
      <path d="M3 4h2l2.4 10.2a2 2 0 0 0 2 1.6h7.7a2 2 0 0 0 2-1.5L21 8H6.2" fill="none" stroke="currentColor" strokeWidth="2" />
      <circle cx="10" cy="20" r="1.5" fill="currentColor" />
      <circle cx="17" cy="20" r="1.5" fill="currentColor" />
    </svg>
  )
}

export default function Header({ cartCount, onOpenCart }) {
  return (
    <header className="border-b border-gray-200">
      <nav aria-label="Main" className="mx-auto flex max-w-6xl flex-wrap items-center justify-between gap-4 px-4 py-3">
        <a href="/" className="text-xl font-bold text-brand-700">Lumen Store</a>
        <ul role="list" className="flex gap-6 text-ink">
          <li><a href="/women">Women</a></li>
          <li><a href="/men">Men</a></li>
          <li><a href="/sale">Sale</a></li>
        </ul>
        <button type="button" onClick={onOpenCart} className="relative rounded-full p-3 text-ink hover:bg-brand-50">
          <CartIcon />
          <span aria-hidden="true" className="absolute -right-1 -top-1 rounded-full bg-sale px-1.5 text-xs text-white">
            {cartCount}
          </span>
        </button>
      </nav>
    </header>
  )
}
