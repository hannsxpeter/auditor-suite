import { useState } from "react";
import posthog from "posthog-js";

// Sends the buyer to Paddle checkout for one price.
export default function CheckoutButton({ planKey, priceId, label }) {
  const [pending, setPending] = useState(false);
  const [error, setError] = useState("");

  async function handleClick() {
    setPending(true);
    setError("");
    posthog.capture("purchase_completed", { plan: planKey, price_id: priceId });
    try {
      const res = await fetch("/api/checkout", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ priceId }),
      });
      const body = await res.json();
      if (!res.ok) throw new Error(body.error || "Checkout could not start. Try again.");
      window.location.assign(body.checkoutUrl);
    } catch (err) {
      setError(err.message);
      setPending(false);
    }
  }

  return (
    <div className="checkout">
      <button type="button" onClick={handleClick} disabled={pending}>
        {pending ? "Opening checkout..." : label}
      </button>
      {error && <p role="alert">{error}</p>}
    </div>
  );
}
