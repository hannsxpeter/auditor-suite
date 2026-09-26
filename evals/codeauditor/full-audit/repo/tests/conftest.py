from datetime import date

import pytest

from app import create_app
from app.models import Customer, Plan, Subscription, db


@pytest.fixture
def app():
    app = create_app(
        {
            "TESTING": True,
            "SQLALCHEMY_DATABASE_URI": "sqlite://",
            "SECRET_KEY": "test",
            "PAYMENTS_URL": "https://payments.test",
            "PAYMENTS_KEY": "test-payments-key",
            "PAYMENTS_WEBHOOK_SECRET": "test-webhook-secret",
            "CARRIER_URL": "https://carrier.test",
            "CARRIER_TOKEN": "test-carrier-token",
        }
    )
    with app.app_context():
        db.create_all()
        yield app
        db.session.remove()
        db.drop_all()


@pytest.fixture
def subscription(app):
    customer = Customer(email="ada@example.com", name="Ada", api_key_hash="0" * 64, payment_token="card_test_ada")
    plan = Plan(name="Single origin", price_cents=1800, weight_grams=340)
    sub = Subscription(
        customer=customer,
        plan=plan,
        grind="filter",
        frequency_weeks=2,
        price_cents=1800,
        status="active",
        next_renewal=date(2026, 1, 1),
    )
    db.session.add_all([customer, plan, sub])
    db.session.commit()
    return sub
