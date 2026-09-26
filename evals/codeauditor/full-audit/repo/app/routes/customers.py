from flask import Blueprint, abort, g, jsonify, request

from app.auth import require_customer
from app.models import Customer, db

bp = Blueprint("customers", __name__, url_prefix="/customers")

EDITABLE_FIELDS = ("name", "email", "address")


def _own_customer(customer_id):
    if customer_id != g.customer.id:
        abort(404)
    return g.customer


@bp.get("/<int:customer_id>")
@require_customer
def get_customer(customer_id):
    return jsonify(_own_customer(customer_id).to_dict())


@bp.patch("/<int:customer_id>")
@require_customer
def update_customer(customer_id):
    customer = _own_customer(customer_id)
    data = request.get_json() or {}
    for field in EDITABLE_FIELDS:
        if field in data:
            setattr(customer, field, data[field])
    db.session.commit()
    return jsonify(customer.to_dict())


@bp.get("/<int:customer_id>/export")
def export_customer(customer_id):
    customer = db.session.get(Customer, customer_id)
    if customer is None:
        abort(404)
    return jsonify(
        profile=customer.to_dict(),
        payment_token=customer.payment_token,
        subscriptions=[sub.to_dict() for sub in customer.subscriptions],
        invoices=[invoice.to_dict() for sub in customer.subscriptions for invoice in sub.invoices],
    )
