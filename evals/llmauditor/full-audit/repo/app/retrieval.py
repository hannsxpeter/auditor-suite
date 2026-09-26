from app import config, db
from app.embeddings import embed_query, embed_texts


def index_article(tenant_id: str, article_id: str, title: str, chunks: list[str]) -> None:
    vectors = embed_texts(chunks)
    with db.connect() as conn:
        conn.execute("DELETE FROM kb_chunks WHERE tenant_id = %s AND article_id = %s", (tenant_id, article_id))
        for position, (text, vector) in enumerate(zip(chunks, vectors)):
            conn.execute(
                "INSERT INTO kb_chunks (tenant_id, article_id, title, position, body, embedding, embedding_model)"
                " VALUES (%s, %s, %s, %s, %s, %s::vector, %s)",
                (tenant_id, article_id, title, position, text, str(vector), config.EMBED_MODEL),
            )


def search_articles(question: str, k: int = 5) -> list[dict]:
    vector = str(embed_query(question))
    return db.fetch_all(
        "SELECT article_id, title, body FROM kb_chunks"
        " WHERE embedding <=> %s::vector < %s"
        " ORDER BY embedding <=> %s::vector LIMIT %s",
        (vector, config.MAX_CHUNK_DISTANCE, vector, k),
    )
