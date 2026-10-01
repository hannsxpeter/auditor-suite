import { Link } from "react-router-dom";

// Shown on the project board. `features` comes from GET /api/me.
export default function ExportButton({ project, features }) {
  if (!features.includes("csv_export")) {
    return (
      <div className="paywall">
        <p>CSV export is included in Pro and Studio.</p>
        <Link to="/pricing">Upgrade to Pro</Link>
      </div>
    );
  }
  return (
    <a href={`/api/projects/${project.id}/export.csv`} download>
      Export CSV
    </a>
  );
}
