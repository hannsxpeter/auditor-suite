"""Plan catalog: what each plan includes, and which plan applies to an account."""
import os
from datetime import datetime, timezone

TRIAL_DAYS = int(os.environ.get("TRIAL_DAYS", "7"))

PLANS = {
    "free": {
        "variant_id": None,
        "limits": {"clients": 2, "invoices_per_month": 5},
        "features": set(),
    },
    "pro": {
        "variant_id": os.environ.get("LS_PRO_VARIANT_ID"),
        "limits": {"clients": 50, "invoices_per_month": None},
        "features": {"multi_currency"},
    },
}


def plan_for(account, now=None):
    """The plan that applies now: Pro during the trial, else the stored plan, else free."""
    now = now or datetime.now(timezone.utc)
    if account.trial_ends_at and account.trial_ends_at > now:
        return PLANS["pro"]
    return PLANS.get(account.plan, PLANS["free"])
