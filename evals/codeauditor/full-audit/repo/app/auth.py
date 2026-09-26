import hashlib
from functools import wraps

from flask import abort, g, request

from app.models import Customer


def _customer_from_request():
    header = request.headers.get("Authorization", "")
    if not header.startswith("Bearer "):
        return None
    # API keys are random 32-byte tokens, so a fast hash is enough to store them.
    key_hash = hashlib.sha256(header[len("Bearer "):].encode()).hexdigest()
    return Customer.query.filter_by(api_key_hash=key_hash).one_or_none()


def require_customer(view):
    @wraps(view)
    def wrapper(*args, **kwargs):
        customer = _customer_from_request()
        if customer is None:
            abort(401)
        g.customer = customer
        return view(*args, **kwargs)

    return wrapper


def require_admin(view):
    @wraps(view)
    def wrapper(*args, **kwargs):
        customer = _customer_from_request()
        if customer is None:
            abort(401)
        if not customer.is_admin:
            abort(403)
        g.customer = customer
        return view(*args, **kwargs)

    return wrapper
