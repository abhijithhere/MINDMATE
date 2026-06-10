# rag/memory_writer.py
"""
Writes chat messages and reinforced memories to the DB.
Called from db_helper.log_chat and directly from nlp when needed.
"""

from services.db import get_db
from rag.embedder import generate_embedding


def store_chat(user_id: str, sender: str, text: str) -> None:
    """
    Insert a chat message with its embedding into chat_messages.
    sender: "user" | "ai"
    """
    conn      = get_db()
    cur       = conn.cursor()
    embedding = generate_embedding(text)

    try:
        cur.execute("""
            INSERT INTO chat_messages (user_id, sender, text, embedding)
            VALUES (%s, %s, %s, %s::vector)
        """, (user_id, sender, text, embedding))
        conn.commit()
    except Exception as e:
        conn.rollback()
        print(f"❌ store_chat error: {e}")
    finally:
        cur.close()
        conn.close()


def store_memory(user_id: str, content: str, source: str = "Voice") -> None:
    """
    Insert a reinforced memory into the memories table.
    Used when the AI detects a fact worth long-term retention.
    """
    conn      = get_db()
    cur       = conn.cursor()
    embedding = generate_embedding(content)

    try:
        cur.execute("""
            INSERT INTO memories (user_id, content, embedding, source)
            VALUES (%s, %s, %s::vector, %s)
        """, (user_id, content, embedding, source))
        conn.commit()
    except Exception as e:
        conn.rollback()
        print(f"❌ store_memory error: {e}")
    finally:
        cur.close()
        conn.close()