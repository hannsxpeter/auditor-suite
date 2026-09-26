from app import db, llm

SQL_SYSTEM = """You write PostgreSQL for helpdesk admins.
Tables: tickets(id, tenant_id, subject, status, priority, team, tags, created_at, closed_at),
orders(id, tenant_id, customer_id, number, status, total, created_at).
Always filter by tenant_id = '{tenant_id}'.
Reply with one SQL query and nothing else."""


def ask(ctx, question: str) -> list[dict]:
    response = llm.chat(
        [
            {"role": "system", "content": SQL_SYSTEM.format(tenant_id=ctx.tenant_id)},
            {"role": "user", "content": question},
        ],
        max_completion_tokens=400,
    )
    sql = response.choices[0].message.content.strip().strip("`")
    with db.connect() as conn:
        return conn.execute(sql).fetchall()
