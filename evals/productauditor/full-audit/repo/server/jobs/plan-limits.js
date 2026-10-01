import * as db from "../db.js";
import { PLANS } from "../../lib/plans.js";

// Brings a workspace within the project limit of its new plan. The billing
// webhook runs it after every subscription change and after a cancellation.
export async function applyPlanLimits(workspaceId, planKey) {
  const limit = (PLANS[planKey] || PLANS.free).limits.projects;
  const overLimit = db.listProjects(workspaceId).slice(limit);
  if (overLimit.length > 0) db.deleteProjects(overLimit.map((project) => project.id));
  return { removed: overLimit.length };
}
