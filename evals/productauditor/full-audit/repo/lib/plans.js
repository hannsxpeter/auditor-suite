// The plan catalog. The pricing page, checkout, the billing webhook, and
// entitlements all read it. Amounts are in cents. Price ids are Paddle's.
export const PLANS = {
  free: {
    key: "free",
    name: "Free",
    prices: null,
    limits: { projects: 3 },
    features: [],
    highlights: ["Up to 3 projects"],
  },
  pro: {
    key: "pro",
    name: "Pro",
    prices: {
      month: { id: "pri_01j8fnpro0month00000000000", amount: 2400, currency: "USD" },
      year: { id: "pri_01j8fnpro0year000000000000", amount: 24000, currency: "USD" },
    },
    limits: { projects: 25 },
    features: ["csv_export"],
    highlights: ["Up to 25 projects", "CSV export of any project"],
  },
  studio: {
    key: "studio",
    name: "Studio",
    prices: {
      month: { id: "pri_01j8fnstudio0month00000000", amount: 5900, currency: "USD" },
      year: { id: "pri_01j8fnstudio0year000000000", amount: 59000, currency: "USD" },
    },
    limits: { projects: Infinity },
    features: ["csv_export"],
    highlights: ["Unlimited projects", "CSV export of any project"],
  },
};

export const PAID_PLAN_KEYS = ["pro", "studio"];

// Returns the plan key ("pro" or "studio") for a Paddle price id, or null.
export function planKeyForPrice(priceId) {
  const key = PAID_PLAN_KEYS.find((planKey) => {
    const { month, year } = PLANS[planKey].prices;
    return month.id === priceId || year.id === priceId;
  });
  return key || null;
}
