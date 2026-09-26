from app import config
from app.llm import client


def embed_texts(texts: list[str]) -> list[list[float]]:
    response = client.embeddings.create(model=config.EMBED_MODEL, input=texts, dimensions=config.EMBED_DIMENSIONS)
    return [item.embedding for item in response.data]


def embed_query(text: str) -> list[float]:
    return embed_texts([text])[0]
