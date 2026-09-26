from datetime import date, timedelta

import requests
from flask import Blueprint, abort, current_app, g, jsonify, request

from app.auth import require_admin, require_customer
from app.models import Plan, Subscription, db
from app.services import billing, carrier, discounts, mailer

bp = Blueprint("subscriptions", __name__, url_prefix="/subscriptions")

ADDON_PRICES = {"MUG": 1400, "FILTERS": 600, "SAMPLER": 900}


@bp.post("")
@require_customer
def create_subscription():
    data = request.get_json() or {}
    errors = {}
    plan = None
    if "plan_id" not in data:
        errors["plan_id"] = "required"
    else:
        plan = db.session.get(Plan, data["plan_id"])
        if plan is None or not plan.active:
            errors["plan_id"] = "unknown plan"
    grind = data.get("grind", "whole")
    if grind not in ("whole", "espresso", "filter", "french_press"):
        errors["grind"] = "unknown grind"
    frequency = data.get("frequency_weeks", 4)
    if frequency not in (1, 2, 4):
        errors["frequency_weeks"] = "must be 1, 2, or 4"
    addons = []
    for item in data.get("addons", []):
        if item.get("sku") in ADDON_PRICES:
            quantity = item.get("quantity", 1)
            if isinstance(quantity, int) and 0 < quantity <= 5:
                addons.append((item["sku"], quantity))
                if item["sku"] == "MUG":
                    if frequency != 4:
                        errors["addons"] = "mugs ship only with monthly plans"
            else:
                errors["addons"] = "quantity must be 1 to 5"
        else:
            errors["addons"] = f"unknown add-on {item.get('sku')}"
    address = data.get("address") or {}
    for field in ("name", "line1", "city", "postal_code", "country"):
        if not str(address.get(field, "")).strip():
            errors[f"address.{field}"] = "required"
    if errors:
        return jsonify(errors=errors), 400

    country = address["country"].strip().upper()
    if country not in ("US", "CA"):
        return jsonify(errors={"address.country": "we ship to the US and Canada only"}), 400
    postal_code = address["postal_code"].strip().upper().replace(" ", "")
    if country == "CA":
        if len(postal_code) == 6:
            postal_code = postal_code[:3] + " " + postal_code[3:]
        else:
            return jsonify(errors={"address.postal_code": "invalid postal code"}), 400
    else:
        if len(postal_code) not in (5, 9) or not postal_code.isdigit():
            return jsonify(errors={"address.postal_code": "invalid ZIP code"}), 400
        if len(postal_code) == 9:
            postal_code = postal_code[:5] + "-" + postal_code[5:]
    shipping_address = {
        "name": address["name"].strip(),
        "line1": address["line1"].strip(),
        "line2": (address.get("line2") or "").strip(),
        "city": address["city"].strip(),
        "postal_code": postal_code,
        "country": country,
    }

    price = discounts.price_after_discounts(plan.price_cents, g.customer.months_subscribed(), data.get("code"))
    if frequency == 1:
        price += 200
    for sku, quantity in addons:
        price += ADDON_PRICES[sku] * quantity
    if country == "CA":
        shipping = 900 if plan.weight_grams > 1000 else 600
    else:
        shipping = 0 if price >= 3000 else 500
    total = price + shipping

    subscription = Subscription(
        customer_id=g.customer.id,
        plan_id=plan.id,
        grind=grind,
        frequency_weeks=frequency,
        price_cents=total,
        status="pending",
        next_renewal=date.today() + timedelta(weeks=frequency),
        shipping_address=shipping_address,
    )
    db.session.add(subscription)
    db.session.flush()
    try:
        subscription.first_charge_id = billing.charge(g.customer, total, f"First box: {plan.name}")
    except billing.PaymentDeclined as exc:
        db.session.rollback()
        return jsonify(errors={"payment": exc.reason}), 402
    subscription.status = "active"
    db.session.commit()

    if g.customer.email_opt_in:
        template = "welcome-weekly" if frequency == 1 else "welcome"
        try:
            mailer.send(g.customer.email, template, {"plan": plan.name, "grind": grind, "total": total})
        except requests.RequestException:
            # The welcome email is best effort: the subscription is already paid and saved.
            current_app.logger.warning("welcome email for subscription %s failed", subscription.id, exc_info=True)

    return jsonify(subscription.to_dict()), 201


@bp.post("/<int:subscription_id>/ship")
@require_admin
def ship_subscription(subscription_id):
    subscription = db.session.get(Subscription, subscription_id)
    if subscription is None:
        abort(404)
    subscription.tracking_number = carrier.create_label(subscription)
    db.session.commit()
    return jsonify(subscription.to_dict())
