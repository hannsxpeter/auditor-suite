SUPPORT_RULES = """You are the support assistant for {company}.
Answer questions about orders, shipping, and returns using the knowledge base below.
Call lookup_order before you answer a question about a specific order.
Call send_customer_email when the shopper asks for a written summary.
Keep answers short and friendly."""


def build_support_system(company: str, articles: list[dict]) -> str:
    knowledge = "\n\n".join(f"## {a['title']}\n{a['body']}" for a in articles)
    return SUPPORT_RULES.format(company=company) + "\n\nKnowledge base:\n" + knowledge
