from typing import Literal

from pydantic import BaseModel

from app import db, llm

REPORT_SQL = {
    "open_by_team": (
        "SELECT team, count(*) AS open_tickets FROM tickets"
        " WHERE tenant_id = %s AND status = 'open' GROUP BY team ORDER BY team"
    ),
    "closed_last_30_days": (
        "SELECT date_trunc('day', closed_at) AS day, count(*) AS closed FROM tickets"
        " WHERE tenant_id = %s AND closed_at > now() - interval '30 days' GROUP BY 1 ORDER BY 1"
    ),
    "late_orders": (
        "SELECT number, status, created_at FROM orders"
        " WHERE tenant_id = %s AND status = 'late' ORDER BY created_at DESC LIMIT 100"
    ),
}

CHOICE_SCHEMA = {
    "name": "report_choice",
    "strict": True,
    "schema": {
        "type": "object",
        "properties": {"report": {"type": "string", "enum": list(REPORT_SQL)}},
        "required": ["report"],
        "additionalProperties": False,
    },
}


class ReportChoice(BaseModel):
    report: Literal["open_by_team", "closed_last_30_days", "late_orders"]


class ReportUnavailable(Exception):
    pass


def run_report(ctx, request_text: str) -> list[dict]:
    response = llm.chat(
        [
            {"role": "system", "content": "Pick the saved report that best answers the admin's request."},
            {"role": "user", "content": request_text},
        ],
        response_format={"type": "json_schema", "json_schema": CHOICE_SCHEMA},
        max_completion_tokens=50,
    )
    choice = response.choices[0]
    if choice.finish_reason != "stop" or choice.message.refusal:
        raise ReportUnavailable(choice.finish_reason)
    picked = ReportChoice.model_validate_json(choice.message.content)
    sql = REPORT_SQL[picked.report]
    with db.connect() as conn:
        return conn.execute(sql, (ctx.tenant_id,)).fetchall()
