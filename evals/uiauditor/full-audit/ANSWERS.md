# Answer key: uiauditor full-audit

Never copied into the eval workspace. Lines refer to files under repo/.

## Planted defects

| Grader | Location | Card | Expected severity | Defect |
|---|---|---|---|---|
| finds-add-to-cart-div | src/components/ProductCard.jsx:12 | A11Y-R1 | Critical | "Add to cart", the primary action, is a `div` with `onClick` and no role, `tabIndex`, or key handler, so keyboard users cannot add anything to the cart |
| finds-cart-button-name | src/components/Header.jsx:21 | A11Y-R2 | Critical | the cart button holds only an `aria-hidden` icon (line 22) and an `aria-hidden` count, so it has no accessible name |
| finds-checkout-labels | src/components/CheckoutForm.jsx:26 | A11Y-R3 | High | the checkout email, name, and card fields (lines 26 to 28) are labeled only by placeholders |
| finds-viewport-zoom | index.html:5 | A11Y-R4 | Critical | `maximum-scale=1, user-scalable=no` blocks pinch zoom |
| finds-quickview-focus | src/components/QuickViewModal.jsx:3 | A11Y-R5 | High | the quick-view overlay has no dialog role or `aria-modal`, never moves focus in, does not contain Tab, ignores Escape, and does not return focus to the trigger; its visible Close button keeps it from being a trap |
| finds-focus-reset | src/index.css:10 | A11Y-R6 | Critical (High acceptable) | global `*:focus { outline: none; }` with no `:focus-visible` replacement removes the focus indicator from every control of the cart and checkout flow; only the view toggle restores one |
| finds-size-chart-alt | src/components/SizeGuide.jsx:8 | A11Y-R10 | High | the size chart, the only source of the sizing data, has no `alt` attribute |
| finds-cart-index-key | src/components/CartList.jsx:42 | COMP-R3 | High | cart rows are keyed by index while each row keeps a local quantity draft (line 4); after a removal, the next item shows the removed item's quantity |
| finds-hero-lazy | src/components/Hero.jsx:9 | PERF-R1 | High | the hero image, the likely LCP element, has `loading="lazy"` and no `fetchpriority`; it also lacks `width` and `height` (RESP-R4 at lines 6 to 11 is an acceptable second finding) |
| finds-sale-badge-hex | src/components/SaleBadge.jsx:3 | DS-R1 | Medium | `bg-[#dc2626]` and `text-[#ffffff]` hardcode the values of the `--color-sale` and `--color-surface` tokens that Tailwind already exposes as `bg-sale` and `text-surface` |

## Decoys (safe; flagging them is a false positive)

| Grader | Location | Why it is safe |
|---|---|---|
| ignores-view-toggle | src/components/ViewToggle.jsx:15 | `focus:outline-none` is paired with `focus-visible:ring-2 focus-visible:ring-offset-2` on the same buttons, and in Tailwind v3 (`^3.4.4`) `outline-none` is a transparent outline that stays visible in forced-colors mode; the buttons also have text labels and `aria-pressed` |
| ignores-testimonial | src/components/Testimonial.jsx:6 | the quote-mark image is decorative, the quote is in text next to it, and it correctly has `alt=""` and fixed dimensions |

## Strengths worth naming

- A skip link that is the first focusable element and targets `main#main` (`src/App.jsx:51`, `src/App.jsx:55`).
- Stable ids as keys on the product list (`src/App.jsx:64`), unlike the cart.
- Product images reserve their space and lazy-load below the fold (`src/components/ProductCard.jsx:6`).
- One token source: Tailwind colors read the CSS variables in `src/styles/tokens.css` (`tailwind.config.js:8`).
- A persistent `role="status"` region announces the order result (`src/components/CheckoutForm.jsx:33`).
- The cart quantity input is wrapped in its label (`src/components/CartList.jsx:15`).

## Acceptable extra findings (not graded)

- The hero headline sits on a photo under a gradient; its contrast cannot be confirmed statically (A11Y-R11, Suspected).
- The quick-view overlay renders outside `main` (SEM-R2, Low), which the A11Y-R5 fix (a real dialog) resolves.
