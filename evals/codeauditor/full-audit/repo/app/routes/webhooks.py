import hashlib
import hmac
import json
import logging

from flask import Blueprint, current_app, jsonify, request

from app.models import db
from app.services import billing

bp = Blueprint("webhooks", __name__, url_prefix="/webhooks")
log = logging.getLogger(__name__)


def _verified_event(body, signature):
    secret = current_app.config["PAYMENTS_WEBHOOK_SECRET"].encode()
    expected = hmac.new(secret, body, hashlib.sha256).hexdigest()
    if not hmac.compare_digest(expected, signature):
        return None
    return json.loads(body)


@bp.post("/payments")
def payment_event():
    # Authenticated by the HMAC signature, not a customer key. Events only set
    # an invoice status, so a replayed event changes nothing.
    event = _verified_event(request.get_data(), request.headers.get("X-Signature", ""))
    if event is None:
        return jsonify(error="bad signature"), 400
    try:
        billing.apply_payment_event(event)
    except Exception:
        log.exception("payment event %s failed; the provider will retry", event.get("id"))
        db.session.rollback()
        return jsonify(error="retry later"), 500
    return jsonify(ok=True)
