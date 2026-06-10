# rag/retriever.py
"""
Semantic retrieval via pgvector cosine similarity (<=>).

retrieve_context  — searches chat_messages, notes, memories, events
get_recent_history — last N messages for conversational context
"""

from services.db import get_db
from rag.embedder import generate_embedding


def retrieve_context(user_id: str, text: str, top_k: int = 3) -> list[str]:
    """
    Semantic search across all four embedding tables.
    Returns a deduplicated list of relevant text snippets.
    """
    embedding = generate_embedding(text)
    if embedding is None:
        return []

    conn = get_db()
    cur  = conn.cursor()
    results = []

    # (table, text_column, embedding_column)
    tables = [
        ("chat_messages", "text",          "embedding"),
        ("notes",         "original_text", "embedding"),
        ("memories",      "content",       "embedding"),
        ("events",        "description",   "embedding"),
    ]

    for table, text_col, emb_col in tables:
        try:
            cur.execute(f"""
                SELECT {text_col}
                FROM {table}
                WHERE user_id = %s
                  AND {text_col}  IS NOT NULL
                  AND {emb_col}   IS NOT NULL
                ORDER BY {emb_col} <=> %s::vector
                LIMIT %s
            """, (user_id, embedding, top_k))
            rows = cur.fetchall()
            results.extend(r[0] for r in rows if r[0])
        except Exception as e:
            print(f"⚠️  Retrieval skip [{table}]: {e}")

    cur.close()
    conn.close()

    # Deduplicate and drop very short strings
    seen = set()
    clean = []
    for r in results:
        s = r.strip()
        if len(s) > 5 and s not in seen:
            seen.add(s)
            clean.append(s)
    return clean


def get_recent_history(user_id: str, limit: int = 3) -> list[str]:
    """
    Returns the last `limit` chat messages as ["sender: text", ...] (oldest first).
    Used by generate_conversational_response for short-term context.
    """
    conn = get_db()
    cur  = conn.cursor()
    try:
        cur.execute("""
            SELECT sender, text
            FROM chat_messages
            WHERE user_id = %s
            ORDER BY created_at DESC
            LIMIT %s
        """, (user_id, limit))
        rows = cur.fetchall()
        # Reverse so oldest is first (natural reading order)
        return [f"{r[0]}: {r[1]}" for r in reversed(rows)]
    except Exception as e:
        print(f"⚠️  get_recent_history error: {e}")
        return []
    finally:
        cur.close()
        conn.close()