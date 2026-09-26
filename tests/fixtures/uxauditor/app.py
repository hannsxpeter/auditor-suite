import random
from datetime import datetime, timezone

from flask import Flask, redirect, render_template, request, url_for

app = Flask(__name__)

CLASSES = {
    1: {"id": 1, "name": "Morning flow", "teacher": "Ana", "starts": "Mon 07:00", "photo": "flow.jpg"},
    2: {"id": 2, "name": "Yin and breath", "teacher": "Sam", "starts": "Tue 18:30", "photo": "yin.jpg"},
}
BOOKINGS = []
MEMBERSHIP = {"plan": "Monthly unlimited", "price": "$95", "renews": "1 October"}


@app.route("/")
def classes():
    week = request.args.get("week", "this")
    listing = []
    for cls in CLASSES.values():
        spots_left = random.randint(1, 3)
        listing.append({**cls, "spots_left": spots_left})
    return render_template("classes.html", classes=listing, week=week)


@app.route("/book/<int:class_id>", methods=["GET", "POST"])
def book(class_id):
    cls = CLASSES.get(class_id)
    if cls is None:
        return redirect(url_for("classes"))
    if request.method == "GET":
        return render_template("book.html", cls=cls, errors={})
    errors = {}
    name = request.form.get("name", "").strip()
    email = request.form.get("email", "").strip()
    if not name:
        errors["name"] = "Enter the name to put on the class list."
    if "@" not in email:
        errors["email"] = "Enter an email address, like ana@example.com."
    if errors:
        return render_template("book.html", cls=cls, errors=errors)
    BOOKINGS.append({"class_id": class_id, "name": name, "email": email, "at": datetime.now(timezone.utc)})
    return redirect(url_for("classes"))


@app.route("/account")
def account():
    return render_template("account.html", membership=MEMBERSHIP)


@app.route("/membership/cancel", methods=["POST"])
def cancel_membership():
    MEMBERSHIP["cancelled"] = True
    return render_template("account.html", membership=MEMBERSHIP)


@app.route("/membership/resume", methods=["POST"])
def resume_membership():
    MEMBERSHIP["cancelled"] = False
    return render_template("account.html", membership=MEMBERSHIP)
