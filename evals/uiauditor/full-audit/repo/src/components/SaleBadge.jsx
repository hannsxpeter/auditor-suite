export default function SaleBadge({ percent }) {
  return (
    <span className="ml-2 inline-flex items-center rounded-full bg-[#dc2626] px-2 py-0.5 text-xs font-semibold text-[#ffffff]">
      {percent}% off
    </span>
  )
}
