import requests
from flask import current_app


class CarrierError(Exception):
    pass


def create_label(subscription):
    """Book a shipping label for the next box and return its tracking number."""
    config = current_app.config
    response = requests.post(
        f"{config['CARRIER_URL']}/labels",
        json={
            "reference": f"sub-{subscription.id}",
            "service": "ground",
            "to": subscription.shipping_address,
            "weight_grams": subscription.plan.weight_grams,
        },
        headers={"Authorization": f"Bearer {config['CARRIER_TOKEN']}"},
    )
    if response.status_code != 201:
        raise CarrierError(f"label request for subscription {subscription.id} failed with {response.status_code}")
    return response.json()["tracking_number"]
