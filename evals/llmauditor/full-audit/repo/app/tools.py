import json
import smtplib
from email.message import EmailMessage

from app import config, db

TOOLS = [
    {
        "type": "function",
        "function": {
            "name": "lookup_order",
            "description": "Look up one of the signed-in shopper's orders by order number. Returns status, items, and shipping address.",
            "parameters": {
                "type": "object",
                "properties": {
                    "order_number": {"type": "string", "description": "Order number, for example A-10293"},
                },
                "required": ["order_number"],
                "additionalProperties": False,
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "send_customer_email",
            "description": "Email the shopper a written summary of the conversation.",
            "parameters": {
                "type": "object",
                "properties": {
                    "to": {"type": "string", "description": "Recipient email address"},
                    "subject": {"type": "string", "description": "Email subject line"},
                    "body": {"type": "string", "description": "Plain-text email body"},
                },
                "required": ["to", "subject", "body"],
                "additionalProperties": False,
            },
        },
    },
]


def lookup_order(ctx, order_number: str) -> dict:
    if ctx.customer_id is None:
        return {"error": "the shopper is not signed in"}
    order = db.fetch_one(
        "SELECT number, status, items, shipping_address FROM orders"
        " WHERE tenant_id = %s AND customer_id = %s AND number = %s",
        (ctx.tenant_id, ctx.customer_id, order_number),
    )
    return order or {"error": f"no order {order_number}"}


def send_customer_email(ctx, to: str, subject: str, body: str) -> dict:
    message = EmailMessage()
    message["From"] = config.SUPPORT_FROM_ADDRESS
    message["To"] = to
    message["Subject"] = subject
    message.set_content(body)
    with smtplib.SMTP(config.SMTP_HOST) as smtp:
        smtp.send_message(message)
    return {"sent": True}


HANDLERS = {"lookup_order": lookup_order, "send_customer_email": send_customer_email}


def execute_tool(ctx, name: str, arguments: str) -> str:
    handler = HANDLERS.get(name)
    if handler is None:
        return json.dumps({"error": f"unknown tool {name}"})
    return json.dumps(handler(ctx, **json.loads(arguments)), default=str)
