const OPTIONS = [
  { value: 'grid', label: 'Grid' },
  { value: 'list', label: 'List' },
]

export default function ViewToggle({ view, onChange }) {
  return (
    <div role="group" aria-label="Product layout" className="inline-flex rounded-lg border border-gray-300 p-1">
      {OPTIONS.map((option) => (
        <button
          key={option.value}
          type="button"
          aria-pressed={view === option.value}
          onClick={() => onChange(option.value)}
          className="rounded-md px-3 py-1.5 text-sm text-ink focus:outline-none focus-visible:ring-2 focus-visible:ring-brand-600 focus-visible:ring-offset-2 aria-pressed:bg-brand-50"
        >
          {option.label}
        </button>
      ))}
    </div>
  )
}
