from datetime import date, datetime, timezone

from flask_sqlalchemy import SQLAlchemy

db = SQLAlchemy()


def utcnow():
    return datetime.now(timezone.utc)


class Customer(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    email = db.Column(db.String(255), unique=True, nullable=False)
    name = db.Column(db.String(120), nullable=False)
    address = db.Column(db.JSON)
    api_key_hash = db.Column(db.String(64), unique=True, nullable=False)
    payment_token = db.Column(db.String(64))
    email_opt_in = db.Column(db.Boolean, default=True, nullable=False)
    is_admin = db.Column(db.Boolean, default=False, nullable=False)
    created_at = db.Column(db.DateTime(timezone=True), default=utcnow, nullable=False)

    subscriptions = db.relationship("Subscription", back_populates="customer")

    def months_subscribed(self):
        return (date.today() - self.created_at.date()).days // 30

    def to_dict(self):
        return {"id": self.id, "email": self.email, "name": self.name, "address": self.address}


class Plan(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(80), nullable=False)
    price_cents = db.Column(db.Integer, nullable=False)
    weight_grams = db.Column(db.Integer, nullable=False)
    active = db.Column(db.Boolean, default=True, nullable=False)


class Subscription(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    customer_id = db.Column(db.Integer, db.ForeignKey("customer.id"), nullable=False)
    plan_id = db.Column(db.Integer, db.ForeignKey("plan.id"), nullable=False)
    grind = db.Column(db.String(20), nullable=False)
    frequency_weeks = db.Column(db.Integer, nullable=False)
    price_cents = db.Column(db.Integer, nullable=False)
    status = db.Column(db.String(20), nullable=False)
    next_renewal = db.Column(db.Date, nullable=False)
    shipping_address = db.Column(db.JSON)
    tracking_number = db.Column(db.String(40))
    first_charge_id = db.Column(db.String(40))

    customer = db.relationship("Customer", back_populates="subscriptions")
    plan = db.relationship("Plan")
    invoices = db.relationship("Invoice", back_populates="subscription")

    def to_dict(self):
        return {
            "id": self.id,
            "plan_id": self.plan_id,
            "grind": self.grind,
            "frequency_weeks": self.frequency_weeks,
            "price_cents": self.price_cents,
            "status": self.status,
            "next_renewal": self.next_renewal.isoformat(),
            "tracking_number": self.tracking_number,
        }


class Invoice(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    subscription_id = db.Column(db.Integer, db.ForeignKey("subscription.id"), nullable=False)
    amount_cents = db.Column(db.Integer, nullable=False)
    status = db.Column(db.String(20), nullable=False)
    charge_id = db.Column(db.String(40), unique=True)
    created_at = db.Column(db.DateTime(timezone=True), default=utcnow, nullable=False)

    subscription = db.relationship("Subscription", back_populates="invoices")

    def to_dict(self):
        return {
            "id": self.id,
            "amount_cents": self.amount_cents,
            "status": self.status,
            "created_at": self.created_at.isoformat(),
        }
