import os


def from_env():
    """Settings for a real deployment. Required variables fail fast when missing."""
    return {
        "SECRET_KEY": os.environ["SECRET_KEY"],
        "SQLALCHEMY_DATABASE_URI": os.environ["DATABASE_URL"],
        "SQLALCHEMY_ENGINE_OPTIONS": {"pool_pre_ping": True, "connect_args": {"connect_timeout": 3}},
        "PAYMENTS_URL": os.environ.get("PAYMENTS_URL", "https://sandbox.payments.example/v1"),
        "PAYMENTS_KEY": os.environ["PAYMENTS_KEY"],
        "PAYMENTS_WEBHOOK_SECRET": os.environ["PAYMENTS_WEBHOOK_SECRET"],
        "CARRIER_URL": os.environ.get("CARRIER_URL", "https://sandbox.parcelhub.example/v2"),
        "CARRIER_TOKEN": os.environ["CARRIER_TOKEN"],
    }
