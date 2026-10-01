import { PLANS } from "../lib/plans.js";

// The plan a workspace is entitled to. Billing keeps workspace.plan current.
export function planFor(workspace) {
  if (workspace.plan === "studio") return PLANS.studio;
  if (workspace.plan === "pro") return PLANS.pro;
  return PLANS.free;
}

export function hasFeature(workspace, feature) {
  return planFor(workspace).features.includes(feature);
}

export function featuresFor(workspace) {
  return planFor(workspace).features;
}

export function projectLimit(workspace) {
  return planFor(workspace).limits.projects;
}

// Route guard: refuses the request unless the workspace's plan includes the feature.
export function requireFeature(feature) {
  return (req, res, next) => {
    if (!hasFeature(req.workspace, feature)) {
      return res.status(402).json({ error: "upgrade_required", feature });
    }
    next();
  };
}
