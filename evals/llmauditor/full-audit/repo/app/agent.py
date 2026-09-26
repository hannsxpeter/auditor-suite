import json

from app import llm
from app.prompts import build_support_system
from app.retrieval import search_articles
from app.tools import TOOLS, execute_tool


class AnswerIncomplete(Exception):
    pass


def answer(ctx, question: str) -> str:
    articles = search_articles(question)
    messages = [
        {"role": "system", "content": build_support_system(ctx.company, articles)},
        {"role": "user", "content": question},
    ]

    while True:
        response = llm.chat(messages, tools=TOOLS, max_completion_tokens=1024)
        choice = response.choices[0]
        messages.append(choice.message.model_dump(exclude_none=True))
        if choice.finish_reason == "stop":
            return choice.message.content or ""
        if choice.finish_reason != "tool_calls":
            raise AnswerIncomplete(choice.finish_reason)
        for call in choice.message.tool_calls:
            try:
                result = execute_tool(ctx, call.function.name, call.function.arguments)
            except Exception as exc:
                result = json.dumps({"error": str(exc)})
            messages.append({"role": "tool", "tool_call_id": call.id, "content": result})
