"""Duebook JSON API and pricing page: models, sign-up, clients, and invoices."""
import os
from datetime import datetime, timedelta, timezone

import posthog
from flask import Flask, render_template, request
from flask_login import LoginManager, UserMixin, current_user, login_required, login_user
from flask_mail import Mail, Message
from flask_sqlalchemy import SQLAlchemy

from app.plans import TRIAL_DAYS, plan_for

app = Flask(__name__, template_folder="../templates")
app.config["SQLALCHEMY_DATABASE_URI"] = os.environ["DATABASE_URL"]
app.config["MAIL_SERVER"] = os.environ["MAIL_SERVER"]
app.secret_key = os.environ["SECRET_KEY"]
db = SQLAlchemy(app)
mail = Mail(app)
login_manager = LoginManager(app)
posthog.project_api_key = os.environ.get("POSTHOG_KEY", "")
posthog.disabled = not posthog.project_api_key


class Account(UserMixin, db.Model):
    id = db.Column(db.Integer, primary_key=True)
    email = db.Column(db.String(255), unique=True, nullable=False)
    plan = db.Column(db.String(20), nullable=False, default="free")
    trial_ends_at = db.Column(db.DateTime(timezone=True))
    ls_subscription_id = db.Column(db.String(40))


class Client(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    account_id = db.Column(db.Integer, db.ForeignKey("account.id"), nullable=False)
    name = db.Column(db.String(200), nullable=False)
    email = db.Column(db.String(255), nullable=False)


class Invoice(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    account_id = db.Column(db.Integer, db.ForeignKey("account.id"), nullable=False)
    client_id = db.Column(db.Integer, db.ForeignKey("client.id"), nullable=False)
    amount_cents = db.Column(db.Integer, nullable=False)
    currency = db.Column(db.String(3), nullable=False, default="USD")
    sent_at = db.Column(db.DateTime(timezone=True))
    client = db.relationship("Client")


@login_manager.user_loader
def load_account(account_id):
    return db.session.get(Account, int(account_id))


def utcnow():
    return datetime.now(timezone.utc)


@app.get("/pricing")
def pricing():
    return render_template("pricing.html")


@app.post("/signup")
def signup():
    account = Account(email=request.form["email"], trial_ends_at=utcnow() + timedelta(days=TRIAL_DAYS))
    db.session.add(account)
    db.session.commit()
    login_user(account)
    posthog.capture(distinct_id=account.email, event="signed_up")
    return {"ok": True}, 201


@app.post("/account/email")
@login_required
def change_email():
    current_user.email = request.form["email"]
    db.session.commit()
    return {"ok": True}


@app.post("/clients")
@login_required
def create_client():
    limit = plan_for(current_user)["limits"]["clients"]
    count = Client.query.filter_by(account_id=current_user.id).count()
    if limit is not None and count >= limit:
        return {"error": "upgrade_required", "limit": limit}, 402
    db.session.add(Client(account_id=current_user.id, name=request.form["name"], email=request.form["email"]))
    db.session.commit()
    return {"ok": True}, 201


@app.post("/invoices")
@login_required
def create_invoice():
    client = Client.query.filter_by(id=int(request.form["client_id"]), account_id=current_user.id).first_or_404()
    currency = request.form.get("currency", "USD").upper()
    if currency != "USD" and "multi_currency" not in plan_for(current_user)["features"]:
        return {"error": "upgrade_required"}, 402
    invoice = Invoice(account_id=current_user.id, client_id=client.id,
                      amount_cents=int(request.form["amount_cents"]), currency=currency)
    db.session.add(invoice)
    db.session.commit()
    return {"id": invoice.id}, 201


@app.post("/invoices/<int:invoice_id>/send")
@login_required
def send_invoice(invoice_id):
    invoice = Invoice.query.filter_by(id=invoice_id, account_id=current_user.id).first_or_404()
    cap = plan_for(current_user)["limits"]["invoices_per_month"]
    month_start = utcnow().replace(day=1, hour=0, minute=0, second=0, microsecond=0)
    sent = Invoice.query.filter(Invoice.account_id == current_user.id, Invoice.sent_at >= month_start).count()
    if cap is not None and sent >= cap:
        return {"error": "upgrade_required", "limit": cap}, 402
    mail.send(Message(f"Invoice {invoice.id}", recipients=[invoice.client.email],
                      body=f"Amount due: {invoice.amount_cents / 100:.2f} {invoice.currency}"))
    invoice.sent_at = utcnow()
    db.session.commit()
    posthog.capture(distinct_id=current_user.email, event="invoice_sent",
                    properties={"amount_cents": invoice.amount_cents, "currency": invoice.currency})
    return {"ok": True}


from app.billing import bp as billing_bp  # noqa: E402 (billing imports the models above)

app.register_blueprint(billing_bp)
