import json
from typing import Literal

from pydantic import BaseModel, Field, ValidationError

from app import db, llm

TAG_VALUES = ["refund", "damaged", "late", "address-change", "account", "other"]


class TicketTags(BaseModel):
    tags: list[Literal["refund", "damaged", "late", "address-change", "account", "other"]] = Field(
        min_length=1, max_length=3
    )


TAGS_SCHEMA = {
    "name": "ticket_tags",
    "strict": True,
    "schema": {
        "type": "object",
        "properties": {
            "tags": {"type": "array", "items": {"type": "string", "enum": TAG_VALUES}},
        },
        "required": ["tags"],
        "additionalProperties": False,
    },
}


class TaggingFailed(Exception):
    pass


def tag_ticket(ctx, ticket_id: str) -> list[str]:
    ticket = db.fetch_one(
        "SELECT subject, body FROM tickets WHERE tenant_id = %s AND id = %s",
        (ctx.tenant_id, ticket_id),
    )
    response = llm.chat(
        [
            {"role": "system", "content": "Tag the helpdesk ticket with one to three tags from the schema."},
            {"role": "user", "content": f"Subject: {ticket['subject']}\n\n{ticket['body']}"},
        ],
        response_format={"type": "json_schema", "json_schema": TAGS_SCHEMA},
        max_completion_tokens=100,
    )
    choice = response.choices[0]
    if choice.finish_reason != "stop" or choice.message.refusal:
        raise TaggingFailed(f"ticket {ticket_id}: no usable answer ({choice.finish_reason})")
    try:
        parsed = TicketTags.model_validate(json.loads(choice.message.content))
    except (json.JSONDecodeError, ValidationError) as exc:
        raise TaggingFailed(f"ticket {ticket_id}: invalid tags") from exc
    db.execute(
        "UPDATE tickets SET tags = %s WHERE tenant_id = %s AND id = %s",
        (parsed.tags, ctx.tenant_id, ticket_id),
    )
    return parsed.tags
