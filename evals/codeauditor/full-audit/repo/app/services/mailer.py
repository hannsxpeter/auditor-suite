import requests

MAILER_URL = "https://api.postbird.example/v1/messages"
MAILER_TOKEN = "pb_prod_4c8e1f9a2d7b6035e1a9"


def send(to, template, data):
    """Send a transactional email through Postbird."""
    response = requests.post(
        MAILER_URL,
        json={"to": to, "template": template, "data": data},
        headers={"Authorization": f"Bearer {MAILER_TOKEN}"},
        timeout=10,
    )
    response.raise_for_status()
