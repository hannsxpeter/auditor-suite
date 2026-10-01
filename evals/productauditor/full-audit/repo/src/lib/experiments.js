import posthog from "posthog-js";

// Experiments that run in the app. Each one names its page, its primary
// metric, the sample it needs, its end date, and the rule that decides it.
export const EXPERIMENTS = {
  pricing_headline: {
    page: "/pricing",
    variants: ["control", "outcome"],
    split: 0.5,
    metric: "purchase_completed",
    samplePerVariant: 4000,
    ends: "2027-03-31",
    decision: "Ship the outcome headline if purchase_completed per pricing visitor rises by 10% or more.",
    owner: "growth",
  },
};

// Returns the variant to render and records the exposure.
export function getVariant(key) {
  const experiment = EXPERIMENTS[key];
  const variant = Math.random() < experiment.split ? experiment.variants[0] : experiment.variants[1];
  posthog.capture("experiment_viewed", { experiment: key, variant });
  return variant;
}
