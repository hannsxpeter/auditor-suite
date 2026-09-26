from dataclasses import dataclass

from fastapi import BackgroundTasks, Depends, FastAPI, Header, HTTPException
from pydantic import BaseModel

from app import agent, db, insights, reports, summaries, tagging, tracking, triage

app = FastAPI(title="Helpdesk Copilot")


@dataclass
class Context:
    tenant_id: str
    company: str
    customer_id: str | None = None


class Question(BaseModel):
    question: str


def widget_context(x_widget_key: str = Header(), x_customer_token: str | None = Header(default=None)) -> Context:
    tenant = db.fetch_one("SELECT id, company FROM tenants WHERE widget_key = %s", (x_widget_key,))
    if tenant is None:
        raise HTTPException(status_code=401)
    customer = None
    if x_customer_token:
        customer = db.fetch_one(
            "SELECT id FROM customers WHERE tenant_id = %s AND session_token = %s",
            (tenant["id"], x_customer_token),
        )
    return Context(tenant_id=tenant["id"], company=tenant["company"], customer_id=customer["id"] if customer else None)


def admin_context(authorization: str = Header()) -> Context:
    admin = db.fetch_one(
        "SELECT t.id, t.company FROM admins a JOIN tenants t ON t.id = a.tenant_id WHERE a.api_token = %s",
        (authorization.removeprefix("Bearer "),),
    )
    if admin is None:
        raise HTTPException(status_code=401)
    return Context(tenant_id=admin["id"], company=admin["company"])


@app.post("/widget/chat")
def widget_chat(body: Question, ctx: Context = Depends(widget_context)):
    return {"answer": agent.answer(ctx, body.question)}


@app.post("/widget/tracking")
def widget_tracking(body: Question, ctx: Context = Depends(widget_context)):
    return {"answer": tracking.where_is_my_parcel(body.question)}


@app.post("/admin/tickets/{ticket_id}/triage")
def admin_triage(ticket_id: str, ctx: Context = Depends(admin_context)):
    result = triage.triage_ticket(ctx, ticket_id)
    tags = tagging.tag_ticket(ctx, ticket_id)
    return {**result, "tags": tags}


@app.post("/admin/tickets/{ticket_id}/close")
def admin_close(ticket_id: str, background: BackgroundTasks, ctx: Context = Depends(admin_context)):
    db.execute(
        "UPDATE tickets SET status = 'closed', closed_at = now() WHERE tenant_id = %s AND id = %s",
        (ctx.tenant_id, ticket_id),
    )
    background.add_task(summaries.summarize_closed_ticket, ctx, ticket_id)
    return {"status": "closed"}


@app.post("/admin/reports")
def admin_reports(body: Question, ctx: Context = Depends(admin_context)):
    return {"rows": reports.run_report(ctx, body.question)}


@app.post("/admin/insights")
def admin_insights(body: Question, ctx: Context = Depends(admin_context)):
    return {"rows": insights.ask(ctx, body.question)}
