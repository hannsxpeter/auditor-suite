/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,jsx}'],
  theme: {
    extend: {
      colors: {
        brand: {
          50: 'var(--color-brand-50)',
          600: 'var(--color-brand-600)',
          700: 'var(--color-brand-700)',
        },
        sale: 'var(--color-sale)',
        ink: 'var(--color-ink)',
        muted: 'var(--color-muted)',
        surface: 'var(--color-surface)',
      },
    },
  },
  plugins: [],
}
