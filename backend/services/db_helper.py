# services/db_helper.py
"""
Central data router for MindMate.
IMPORTANT: This file must NOT import from any other services/ file.
           It only imports from rag/ and services/db.py.
           This prevents circular imports (gmail → db_helper → gmail).
"""

from datetime import datetime, timedelta
from dateutil.parser import parse as date_parse
from psycopg2.extras import RealDictCursor

from services.db import get_db
from rag.embedder import generate_embedding   # rag/ is safe — no back-reference


# ─────────────────────────────────────────────────────────────────────────────
# 1. MAIN ROUTER
# ─────────────────────────────────────────────────────────────────────────────
def save_to_appropriate_table(
    user_id:         str,
    analysis:        dict,
    text:            str  = "",
    source:          str  = "Voice",
    flag:            int  = 0,
    origin_location: str  = None,
) -> str:
    """
    Routes classified content to the correct DB table.

    analysis keys used:
      decision        : STORE | CRUD | IGNORE
      category        : reminder | event | memory | lecture | note | task
      type            : (Gmail) event | note | task  — overrides category
      data            : (Gmail) nested dict {title, content, date, location}
      summary         : short string
      priority        : "High" | "Low"
      is_long         : bool
      trigger_time    : fuzzy or ISO timestamp string
    """
    src = origin_location or source

    if not text or len(text.strip()) < 5:
        return "Skipped: too short"
    if analysis.get("decision") == "IGNORE":
        return "Ignored"

    # Gmail compat: analysis may have type + data instead of category
    gmail_data = analysis.get("data") or {}
    gmail_type = analysis.get("type", "")
    category   = (gmail_type or analysis.get("category", "note")).lower()
    summary    = analysis.get("summary", text[:120])

    priority_label = analysis.get("priority", "Low")
    priority_int   = 1 if priority_label == "High" else 0

    embedding = generate_embedding(text)

    conn = get_db()
    cur  = conn.cursor()

    try:
        # ── REMINDER / TASK / TODO / MEDICINE / DEADLINE ──────────────────────
        if category in ("reminder", "task", "todo", "medicine", "deadline", "appointment"):
            trigger = format_fuzzy_timestamp(
                gmail_data.get("date") or analysis.get("trigger_time")
            )
            cur.execute("""
                INSERT INTO reminders
                    (user_id, message, trigger_time, status,
                     priority_level, priority, is_owner_voice)
                VALUES (%s, %s, %s, 'active', %s, %s, %s)
            """, (
                user_id,
                gmail_data.get("content") or summary,
                trigger,
                priority_label,
                priority_int,
                flag,
            ))
            _log_timeline(cur, user_id,
                          type_="reminder",
                          title=gmail_data.get("title") or summary[:60],
                          content=gmail_data.get("content") or text,
                          category=category)
            saved = f"reminders (priority={priority_label}/{priority_int})"

        # ── CALENDAR EVENT / MEETING / SCHEDULE ───────────────────────────────
        elif category in ("event", "meeting", "schedule"):
            start = format_fuzzy_timestamp(
                gmail_data.get("date") or analysis.get("start_time")
            )
            cur.execute("""
                INSERT INTO events
                    (user_id, title, category, start_time,
                     location_name, origin_location, description)
                VALUES (%s, %s, %s, %s, %s, %s, %s)
            """, (
                user_id,
                gmail_data.get("title") or summary[:80],
                "personal",
                start,
                gmail_data.get("location") or "",
                src,
                gmail_data.get("content") or text,
            ))
            _log_timeline(cur, user_id,
                          type_="event",
                          title=gmail_data.get("title") or summary[:60],
                          content=gmail_data.get("content") or text,
                          category="event",
                          start_time=start)
            saved = "events"

        # ── MEMORY ────────────────────────────────────────────────────────────
        elif category == "memory":
            cur.execute("""
                INSERT INTO memories
                    (user_id, memory_type, content, embedding, confidence_score)
                VALUES (%s, %s, %s, %s::vector, %s)
            """, (user_id, "general", text, embedding, 0.6))
            saved = "memories"

        # ── LECTURE (long note with summary) ─────────────────────────────────
        elif category == "lecture" or analysis.get("is_long"):
            cur.execute("""
                INSERT INTO notes
                    (user_id, summary, original_text, embedding,
                     origin_location, is_owner_voice)
                VALUES (%s, %s, %s, %s::vector, %s, %s)
            """, (user_id, summary, text, embedding, src, flag))
            _log_timeline(cur, user_id,
                          type_="note",
                          title=summary[:60],
                          content=text,
                          category="lecture")
            saved = "notes (lecture)"

        # ── SHORT NOTE (default) ──────────────────────────────────────────────
        else:
            cur.execute("""
                INSERT INTO notes
                    (user_id, summary, original_text, embedding,
                     origin_location, is_owner_voice)
                VALUES (%s, %s, %s, %s::vector, %s, %s)
            """, (user_id, summary, text, embedding, src, flag))
            saved = "notes"

        conn.commit()
        print(f"✅ Stored → {saved}  [user={user_id}, flag={flag}]")
        return saved

    except Exception as e:
        conn.rollback()
        print(f"❌ DB Save Error [{category}]: {e}")
        return "Storage failed"
    finally:
        cur.close()
        conn.close()


# ─────────────────────────────────────────────────────────────────────────────
# 2. CHAT LOG
# ─────────────────────────────────────────────────────────────────────────────
def log_chat(
    user_id:  str,
    sender:   str,
    text:     str,
    location: str = None,
    flag:     int = 0,
) -> None:
    conn = get_db()
    cur  = conn.cursor()
    try:
        vec = generate_embedding(text)
        cur.execute("""
            INSERT INTO chat_messages
                (user_id, sender, text, location, embedding, is_owner_voice)
            VALUES (%s, %s, %s, %s, %s, %s)
        """, (user_id, sender, text, location, vec, flag))
        conn.commit()
    except Exception as e:
        print(f"❌ log_chat error: {e}")
    finally:
        cur.close()
        conn.close()


# ─────────────────────────────────────────────────────────────────────────────
# 3. TIMELINE LOG (internal helper, uses open cursor)
# ─────────────────────────────────────────────────────────────────────────────
def _log_timeline(
    cur,
    user_id:    str,
    type_:      str,
    title:      str,
    content:    str,
    category:   str = "",
    start_time: str = None,
) -> None:
    try:
        cur.execute("""
            INSERT INTO timeline (user_id, type, title, content, category, start_time)
            VALUES (%s, %s, %s, %s, %s, %s)
        """, (
            user_id, type_, title[:120], content[:500],
            category,
            start_time or datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        ))
    except Exception as e:
        print(f"⚠️  timeline log skipped: {e}")


# ─────────────────────────────────────────────────────────────────────────────
# 4. FUZZY TIMESTAMP PARSER
# ─────────────────────────────────────────────────────────────────────────────
def format_fuzzy_timestamp(time_str=None) -> str:
    if not time_str:
        return datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    t   = str(time_str).lower().strip()
    now = datetime.now()
    target = now
    if "tomorrow"   in t: target = now + timedelta(days=1)
    elif "next week" in t: target = now + timedelta(days=7)
    if   "morning"   in t: return target.replace(hour=9,  minute=0, second=0).strftime("%Y-%m-%d %H:%M:%S")
    elif "afternoon" in t: return target.replace(hour=14, minute=0, second=0).strftime("%Y-%m-%d %H:%M:%S")
    elif "evening"   in t: return target.replace(hour=18, minute=0, second=0).strftime("%Y-%m-%d %H:%M:%S")
    elif "night"     in t: return target.replace(hour=21, minute=0, second=0).strftime("%Y-%m-%d %H:%M:%S")
    try:
        return date_parse(t).strftime("%Y-%m-%d %H:%M:%S")
    except Exception:
        return (now + timedelta(hours=1)).strftime("%Y-%m-%d %H:%M:%S")


# ─────────────────────────────────────────────────────────────────────────────
# 5. SEMANTIC CONTEXT (top-3 notes for RAG)
# ─────────────────────────────────────────────────────────────────────────────
def get_semantic_context(user_query: str, user_id: str) -> str:
    query_vec = generate_embedding(user_query)
    if not query_vec:
        return ""
    conn = get_db()
    cur  = conn.cursor()
    try:
        cur.execute("""
            SELECT original_text FROM notes
            WHERE user_id = %s AND embedding IS NOT NULL
            ORDER BY embedding <=> %s::vector
            LIMIT 3
        """, (user_id, query_vec))
        return " ".join(r[0] for r in cur.fetchall() if r[0])
    except Exception as e:
        print(f"⚠️  get_semantic_context: {e}")
        return ""
    finally:
        cur.close()
        conn.close()