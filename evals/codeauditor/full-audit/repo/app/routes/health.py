from flask import Blueprint, jsonify
from sqlalchemy import text

from app.models import db

bp = Blueprint("health", __name__)


@bp.get("/healthz")
def liveness():
    # Liveness: the process is up. Kubernetes restarts the pod when this fails,
    # so it must not depend on the database; /readyz covers that.
    return jsonify(status="ok")


@bp.get("/readyz")
def readiness():
    try:
        db.session.execute(text("SELECT 1"))
    except Exception:
        db.session.rollback()
        return jsonify(status="database unavailable"), 503
    return jsonify(status="ready")
