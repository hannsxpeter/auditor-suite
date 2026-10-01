"""Lemon Squeezy checkout, customer portal, and subscription webhook."""
import hashlib
import hmac
import os

import requests
from flask import Blueprint, abort, redirect, request, url_for
from flask_login import current_user, login_required

from app.main import Account, db
from app.plans import PLANS

bp = Blueprint("billing", __name__, url_prefix="/billing")
API = "https://api.lemonsqueezy.com/v1"


def _headers():
    return {
        "Accept": "application/vnd.api+json",
        "Content-Type": "application/vnd.api+json",
        "Authorization": "Bearer " + os.environ["LEMONSQUEEZY_API_KEY"],
    }


@bp.post("/checkout")
@login_required
def checkout():
    if current_user.plan == "pro":
        return redirect(url_for("billing.portal"))
    body = {"data": {
        "type": "checkouts",
        "attributes": {"checkout_data": {
            "email": current_user.email,
            "custom": {"account_id": str(current_user.id)},
        }},
        "relationships": {
            "store": {"data": {"type": "stores", "id": os.environ["LEMONSQUEEZY_STORE_ID"]}},
            "variant": {"data": {"type": "variants", "id": PLANS["pro"]["variant_id"]}},
        },
    }}
    resp = requests.post(f"{API}/checkouts", json=body, headers=_headers(), timeout=10)
    resp.raise_for_status()
    return redirect(resp.json()["data"]["attributes"]["url"])


@bp.get("/portal")
@login_required
def portal():
    if not current_user.ls_subscription_id:
        return redirect(url_for("pricing"))
    resp = requests.get(f"{API}/subscriptions/{current_user.ls_subscription_id}", headers=_headers(), timeout=10)
    resp.raise_for_status()
    return redirect(resp.json()["data"]["attributes"]["urls"]["customer_portal"])


@bp.post("/webhook")
def webhook():
    secret = os.environ["LEMONSQUEEZY_WEBHOOK_SECRET"].encode()
    digest = hmac.new(secret, request.get_data(), hashlib.sha256).hexdigest()
    if not hmac.compare_digest(digest, request.headers.get("X-Signature", "")):
        abort(401)
    event = request.get_json()
    if event["meta"]["event_name"] == "subscription_created":
        account = db.session.get(Account, int(event["meta"]["custom_data"]["account_id"]))
        account.plan = "pro"
        account.ls_subscription_id = str(event["data"]["id"])
        db.session.commit()
    return "", 200
