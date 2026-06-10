# rag/embedder.py
"""
Text embedding using sentence-transformers.
Produces 384-dimensional vectors (all-MiniLM-L6-v2).

Output format: Python list[float]  — stored as ::vector in PostgreSQL.
psycopg2 passes the list directly; pgvector casts it automatically when
the column is vector(384) and you use %s::vector in the SQL.
"""

from sentence_transformers import SentenceTransformer

print("⏳ Loading embedding model...")
_model = SentenceTransformer('all-MiniLM-L6-v2')
print("✅ Embedding model ready (384-dim).")


def generate_embedding(text: str) -> list[float] | None:
    """
    Returns a 384-dimensional float list, or None if text is too short.
    """
    try:
        if not text or len(text.strip()) < 5:
            return None
        vector = _model.encode(text, normalize_embeddings=True)
        result = vector.tolist()
        if len(result) != 384:
            print(f"❌ Unexpected embedding dim: {len(result)}")
            return None
        return result
    except Exception as e:
        print(f"❌ Embedding error: {e}")
        return None


# Alias used in older code
embed_text = generate_embedding