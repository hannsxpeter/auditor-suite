import { useState } from "react";
import { Link } from "react-router-dom";
import { PLANS, PAID_PLAN_KEYS } from "../../lib/plans.js";
import { getVariant } from "../lib/experiments.js";
import CheckoutButton from "./CheckoutButton.jsx";

const HEADLINES = {
  control: "Simple pricing for client work",
  outcome: "Every client project on one board",
};

export default function PricingTable() {
  const headline = HEADLINES[getVariant("pricing_headline")];
  const [interval, setBillingInterval] = useState("month");

  return (
    <section className="pricing">
      <h1>{headline}</h1>
      <p>Every new workspace starts with a 14-day free trial of Pro. No credit card required.</p>
      <div role="group" aria-label="Billing period">
        <button type="button" aria-pressed={interval === "month"} onClick={() => setBillingInterval("month")}>
          Monthly
        </button>
        <button type="button" aria-pressed={interval === "year"} onClick={() => setBillingInterval("year")}>
          Yearly, two months free
        </button>
      </div>
      <div className="plans">
        <article>
          <h2>{PLANS.free.name}</h2>
          <p className="price">$0</p>
          <ul>{PLANS.free.highlights.map((item) => <li key={item}>{item}</li>)}</ul>
          <Link to="/signup">Get started</Link>
        </article>
        {PAID_PLAN_KEYS.map((key) => {
          const plan = PLANS[key];
          const price = plan.prices[interval];
          return (
            <article key={key}>
              <h2>{plan.name}</h2>
              <p className="price">${price.amount / 100} / {interval}</p>
              <ul>{plan.highlights.map((item) => <li key={item}>{item}</li>)}</ul>
              <CheckoutButton planKey={key} priceId={plan.prices.year.id} label={`Choose ${plan.name}`} />
            </article>
          );
        })}
      </div>
    </section>
  );
}
