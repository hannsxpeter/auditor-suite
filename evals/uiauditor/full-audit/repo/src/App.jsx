import { Component, useState } from 'react'
import Header from './components/Header.jsx'
import Hero from './components/Hero.jsx'
import ProductCard from './components/ProductCard.jsx'
import ViewToggle from './components/ViewToggle.jsx'
import QuickViewModal from './components/QuickViewModal.jsx'
import CartList from './components/CartList.jsx'
import CheckoutForm from './components/CheckoutForm.jsx'
import SizeGuide from './components/SizeGuide.jsx'
import Testimonial from './components/Testimonial.jsx'
import { products } from './data/products.js'

class ErrorBoundary extends Component {
  state = { failed: false }

  static getDerivedStateFromError() {
    return { failed: true }
  }

  render() {
    if (this.state.failed) {
      return (
        <p role="alert" className="p-6 text-ink">
          Something went wrong. <a className="underline" href="/">Reload the store</a>
        </p>
      )
    }
    return this.props.children
  }
}

export default function App() {
  const [view, setView] = useState('grid')
  const [cart, setCart] = useState([])
  const [cartOpen, setCartOpen] = useState(false)
  const [preview, setPreview] = useState(null)

  const addToCart = (product) => {
    setCart((items) => [...items, { ...product, quantity: 1, lineId: `${product.id}-${Date.now()}` }])
  }
  const updateQuantity = (lineId, quantity) => {
    setCart((items) => items.map((item) => (item.lineId === lineId ? { ...item, quantity } : item)))
  }
  const removeFromCart = (lineId) => {
    setCart((items) => items.filter((item) => item.lineId !== lineId))
  }
  const total = cart.reduce((sum, item) => sum + item.price * item.quantity, 0)

  return (
    <ErrorBoundary>
      <a href="#main" className="sr-only focus:not-sr-only focus:absolute focus:left-4 focus:top-4">
        Skip to content
      </a>
      <Header cartCount={cart.length} onOpenCart={() => setCartOpen(true)} />
      <main id="main" className="mx-auto max-w-6xl px-4">
        <Hero />
        <section aria-labelledby="catalog-heading" className="py-10">
          <div className="flex flex-wrap items-center justify-between gap-4">
            <h2 id="catalog-heading" className="text-2xl font-semibold text-ink">New this season</h2>
            <ViewToggle view={view} onChange={setView} />
          </div>
          <ul role="list" className={view === 'grid' ? 'mt-6 grid gap-6 sm:grid-cols-2 lg:grid-cols-3' : 'mt-6 space-y-4'}>
            {products.map((product) => (
              <li key={product.id}>
                <ProductCard product={product} onAdd={addToCart} onPreview={setPreview} />
              </li>
            ))}
          </ul>
        </section>
        <SizeGuide />
        <Testimonial />
        {cartOpen && (
          <section aria-labelledby="cart-heading" className="py-10">
            <h2 id="cart-heading" className="text-2xl font-semibold text-ink">Your cart</h2>
            <CartList items={cart} onQuantity={updateQuantity} onRemove={removeFromCart} />
            <CheckoutForm total={total} />
          </section>
        )}
      </main>
      {preview && <QuickViewModal product={preview} onClose={() => setPreview(null)} onAdd={addToCart} />}
    </ErrorBoundary>
  )
}
