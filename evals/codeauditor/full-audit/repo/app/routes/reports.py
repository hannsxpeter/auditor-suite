from flask import Blueprint, jsonify

from app.auth import require_admin
from app.models import Customer, Invoice, Subscription, db

bp = Blueprint("reports", __name__, url_prefix="/reports")


@bp.get("/renewals")
@require_admin
def renewals_report():
    rows = []
    for sub in Subscription.query.filter_by(status="active").order_by(Subscription.id).all():
        customer = db.session.get(Customer, sub.customer_id)
        last_invoice = (
            Invoice.query.filter_by(subscription_id=sub.id)
            .order_by(Invoice.created_at.desc())
            .first()
        )
        rows.append(
            {
                "subscription": sub.id,
                "customer": customer.email,
                "plan": sub.plan_id,
                "next_renewal": sub.next_renewal.isoformat(),
                "last_invoice_status": last_invoice.status if last_invoice else None,
            }
        )
    return jsonify(rows)
