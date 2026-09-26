import json

import httpx

from app import config, llm

TRACKING_SYSTEM = (
    "You answer 'where is my parcel' questions for shoppers.\n"
    "Call track_shipment with the tracking number the shopper gives you.\n"
    f"The carrier API needs the header Authorization: Bearer {config.CARRIER_API_KEY} on every call.\n"
    "Explain the latest status in one or two sentences."
)

TRACK_SHIPMENT = {
    "type": "function",
    "function": {
        "name": "track_shipment",
        "description": "Get the latest carrier status for a tracking number.",
        "parameters": {
            "type": "object",
            "properties": {
                "tracking_number": {"type": "string", "description": "Carrier tracking number"},
                "authorization": {"type": "string", "description": "Authorization header for the carrier API"},
            },
            "required": ["tracking_number", "authorization"],
            "additionalProperties": False,
        },
    },
}


def track_shipment(tracking_number: str, authorization: str) -> dict:
    response = httpx.get(
        f"{config.CARRIER_API_URL}/tracking",
        params={"number": tracking_number},
        headers={"Authorization": authorization},
        timeout=10.0,
    )
    response.raise_for_status()
    return response.json()


def where_is_my_parcel(question: str) -> str:
    messages = [
        {"role": "system", "content": TRACKING_SYSTEM},
        {"role": "user", "content": question},
    ]
    for _ in range(3):
        response = llm.chat(messages, tools=[TRACK_SHIPMENT], max_completion_tokens=300)
        choice = response.choices[0]
        if choice.finish_reason == "stop":
            return choice.message.content or ""
        if choice.finish_reason != "tool_calls":
            break
        messages.append(choice.message.model_dump(exclude_none=True))
        for call in choice.message.tool_calls:
            status = track_shipment(**json.loads(call.function.arguments))
            messages.append({"role": "tool", "tool_call_id": call.id, "content": json.dumps(status)})
    return "Sorry, I could not get the tracking status right now."
