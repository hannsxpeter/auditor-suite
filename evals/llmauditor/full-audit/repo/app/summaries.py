from datetime import datetime, timezone
from pathlib import Path

from app import db, llm

# House style and worked examples. The text is the same on every call, so the
# provider caches it, and prompt_cache_key keeps these requests on one cache.
STYLE_GUIDE = (Path(__file__).parent / "house_style.md").read_text()


class SummaryIncomplete(Exception):
    pass


def summary_system() -> str:
    return f"Summary generated at {datetime.now(timezone.utc).isoformat()}.\n\n" + STYLE_GUIDE


def summarize_closed_ticket(ctx, ticket_id: str) -> str:
    thread = db.fetch_all(
        "SELECT author, body FROM ticket_messages WHERE tenant_id = %s AND ticket_id = %s ORDER BY created_at",
        (ctx.tenant_id, ticket_id),
    )
    transcript = "\n\n".join(f"{m['author']}: {m['body']}" for m in thread)
    response = llm.chat(
        [
            {"role": "system", "content": summary_system()},
            {"role": "user", "content": transcript},
        ],
        prompt_cache_key="ticket-summary",
        max_completion_tokens=600,
    )
    choice = response.choices[0]
    if choice.finish_reason != "stop":
        raise SummaryIncomplete(choice.finish_reason)
    db.execute(
        "UPDATE tickets SET summary = %s WHERE tenant_id = %s AND id = %s",
        (choice.message.content, ctx.tenant_id, ticket_id),
    )
    return choice.message.content
