import hashlib
import hmac
import json

from app.models import Invoice, db


def signed(app, event):
    body = json.dumps(event).encode()
    secret = app.config["PAYMENTS_WEBHOOK_SECRET"].encode()
    return body, hmac.new(secret, body, hashlib.sha256).hexdigest()


def test_refund_event_marks_the_invoice_refunded(app, subscription):
    invoice = Invoice(subscription_id=subscription.id, amount_cents=1800, status="paid", charge_id="ch_1")
    db.session.add(invoice)
    db.session.commit()
    body, signature = signed(app, {"id": "ev_1", "type": "charge.refunded", "data": {"charge_id": "ch_1"}})

    response = app.test_client().post("/webhooks/payments", data=body, headers={"X-Signature": signature})

    assert response.status_code == 200
    assert db.session.get(Invoice, invoice.id).status == "refunded"


def test_bad_signature_is_rejected(app):
    response = app.test_client().post("/webhooks/payments", data=b"{}", headers={"X-Signature": "nope"})

    assert response.status_code == 400


def test_failure_asks_the_provider_to_retry(app, subscription, monkeypatch):
    def broken(event):
        raise RuntimeError("database down")

    monkeypatch.setattr("app.services.billing.apply_payment_event", broken)
    body, signature = signed(app, {"id": "ev_2", "type": "charge.failed", "data": {"charge_id": "ch_2"}})

    response = app.test_client().post("/webhooks/payments", data=body, headers={"X-Signature": signature})

    assert response.status_code == 500
