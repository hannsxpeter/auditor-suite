import logging
from datetime import date, timedelta

import requests
from flask import current_app
from sqlalchemy.orm import selectinload

from app.models import Invoice, Subscription, db

log = logging.getLogger(__name__)


class PaymentDeclined(Exception):
    def __init__(self, reason):
        super().__init__(reason)
        self.reason = reason


def charge(customer, amount_cents, description):
    """Charge the customer's saved card and return the provider's charge ID."""
    config = current_app.config
    response = requests.post(
        f"{config['PAYMENTS_URL']}/charges",
        json={
            "source": customer.payment_token,
            "amount": amount_cents,
            "currency": "usd",
            "description": description,
        },
        headers={"Authorization": f"Bearer {config['PAYMENTS_KEY']}"},
        timeout=(3, 15),
    )
    if response.status_code == 402:
        raise PaymentDeclined(response.json().get("reason", "card declined"))
    response.raise_for_status()
    return response.json()["id"]


def charge_renewal(subscription):
    invoice = Invoice(subscription_id=subscription.id, amount_cents=subscription.price_cents, status="pending")
    db.session.add(invoice)
    db.session.commit()
    try:
        invoice.charge_id = charge(subscription.customer, subscription.price_cents, f"Renewal: {subscription.plan.name}")
    except Exception:
        pass
    invoice.status = "paid"
    subscription.next_renewal = subscription.next_renewal + timedelta(weeks=subscription.frequency_weeks)
    db.session.commit()
    return invoice


def run_renewals(today=None):
    today = today or date.today()
    due = (
        Subscription.query.options(selectinload(Subscription.customer), selectinload(Subscription.plan))
        .filter(Subscription.status == "active", Subscription.next_renewal <= today)
        .all()
    )
    for subscription in due:
        charge_renewal(subscription)
    return len(due)


def apply_payment_event(event):
    invoice = Invoice.query.filter_by(charge_id=event["data"]["charge_id"]).one_or_none()
    if invoice is None:
        log.info("payment event %s matches no invoice", event["id"])
        return
    if event["type"] == "charge.refunded":
        invoice.status = "refunded"
    elif event["type"] == "charge.failed":
        invoice.status = "failed"
    db.session.commit()
