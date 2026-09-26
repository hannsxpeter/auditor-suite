import json

from app import db, llm

TRIAGE_SYSTEM = """You triage helpdesk tickets for an online store.
Reply with a JSON object with two keys:
"priority": one of "low", "normal", "high", "urgent"
"team": one of "billing", "shipping", "returns", "technical"."""


class TriageIncomplete(Exception):
    pass


def triage_ticket(ctx, ticket_id: str) -> dict:
    ticket = db.fetch_one(
        "SELECT subject, body FROM tickets WHERE tenant_id = %s AND id = %s",
        (ctx.tenant_id, ticket_id),
    )
    response = llm.chat(
        [
            {"role": "system", "content": TRIAGE_SYSTEM},
            {"role": "user", "content": f"Subject: {ticket['subject']}\n\n{ticket['body']}"},
        ],
        response_format={"type": "json_object"},
        max_completion_tokens=200,
    )
    choice = response.choices[0]
    if choice.finish_reason != "stop":
        raise TriageIncomplete(choice.finish_reason)
    result = json.loads(choice.message.content)
    db.execute(
        "UPDATE tickets SET priority = %s, team = %s WHERE tenant_id = %s AND id = %s",
        (result["priority"], result["team"], ctx.tenant_id, ticket_id),
    )
    return result
