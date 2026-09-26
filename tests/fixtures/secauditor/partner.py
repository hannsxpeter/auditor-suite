import os

import requests

PARTNER_URL = "https://rates.partner.example"


def fetch_rates():
    headers = {"Authorization": "Bearer " + os.environ.get("PARTNER_TOKEN", "")}
    return requests.get(PARTNER_URL + "/v1/rates", headers=headers, verify=False, timeout=10).json()
