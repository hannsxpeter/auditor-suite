from datetime import date

from app.services import billing


def test_charge_renewal(app, subscription, monkeypatch):
    monkeypatch.setattr(billing, "charge", lambda customer, amount, description: "ch_test_1")
    billing.charge_renewal(subscription)


def test_charge_renewal_declined(app, subscription, monkeypatch):
    def declined(customer, amount, description):
        raise billing.PaymentDeclined("card declined")

    monkeypatch.setattr(billing, "charge", declined)
    billing.charge_renewal(subscription)


def test_run_renewals(app, subscription, monkeypatch):
    monkeypatch.setattr(billing, "charge", lambda customer, amount, description: "ch_test_2")
    billing.run_renewals(today=date(2026, 1, 1))
    assert True
