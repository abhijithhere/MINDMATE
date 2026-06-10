# services/events.py
"""
Handles event and voice-entry storage with correct DB schema columns.
"""

from datetime import datetime
from psycopg2.extras import RealDictCursor
from services.db import get_db
from services.db_helper import format_fuzzy_timestamp


def save_voice_entry(user_id: str, original_text: str, analysis: dict) -> str | None:
    """
    Stores a classified voice entry to events or memories.
    Called from advanced NLP flows when a specific category is already known.
    """
    conn = get_db()
    cur  = conn.cursor()
    try:
        category = analysis.get("category", "none").lower()
        saved    = None

        # ── SCHEDULE / EVENT ──────────────────────────────────────────────────
        if category in ("schedule", "event", "meeting"):
            evt        = analysis.get("schedule") or analysis.get("data") or {}
            start_time = format_fuzzy_timestamp(
                evt.get("start_time") or evt.get("date")
            )
            end_time   = format_fuzzy_timestamp(evt.get("end_time")) \
                         if evt.get("end_time") else None
            title      = evt.get("title") or analysis.get("summary", "Untitled")[:80]

            cur.execute("""
                INSERT INTO events
                    (user_id, title, category, start_time, end_time,
                     location_name, origin_location, description)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
                RETURNING id
            """, (
                user_id, title, "personal",
                start_time, end_time,
                evt.get("location") or "",
                "Voice",
                original_text,
            ))
            event_id = cur.fetchone()[0]

            # Log in voice_analysis table
            cur.execute("""
                INSERT INTO voice_analysis
                    (user_id, associated_event_id, original_transcript, stress_level)
                VALUES (%s, %s, %s, %s)
            """, (user_id, event_id, original_text, 0.0))

            saved = f"✅ Event saved: {title}"

        # ── NOTE / MEMORY ─────────────────────────────────────────────────────
        elif category in ("note", "memory"):
            note  = analysis.get("note") or analysis.get("data") or {}
            title = note.get("title") or analysis.get("summary", "")[:80]

            cur.execute("""
                INSERT INTO memories
                    (user_id, memory_type, title, content, confidence_score)
                VALUES (%s, %s, %s, %s, %s)
            """, (
                user_id,
                "general_note",
                title,
                note.get("content") or original_text,
                0.6,
            ))
            saved = f"✅ Memory saved: {title}"

        conn.commit()
        return saved

    except Exception as e:
        conn.rollback()
        print(f"❌ save_voice_entry error: {e}")
        return None
    finally:
        cur.close()
        conn.close()


def get_schedule_for_date(user_id: str, date_str: str) -> list[str]:
    """Returns formatted event list for a given date (YYYY-MM-DD)."""
    conn = get_db()
    cur  = conn.cursor(cursor_factory=RealDictCursor)
    try:
        cur.execute("""
            SELECT title, start_time, location_name
            FROM events
            WHERE user_id = %s AND date(start_time) = %s
            ORDER BY start_time ASC
        """, (user_id, date_str))
        rows = cur.fetchall()

        result = []
        for row in rows:
            t   = str(row['start_time']).split(' ')[1][:5] \
                  if row['start_time'] else "00:00"
            loc = f" at {row['location_name']}" if row['location_name'] else ""
            result.append(f"- {t}: {row['title']}{loc}")
        return result
    finally:
        cur.close()
        conn.close()


def get_upcoming_reminders(user_id: str, limit: int = 10) -> list[dict]:
    """Returns active reminders ordered by priority then trigger_time."""
    conn = get_db()
    cur  = conn.cursor(cursor_factory=RealDictCursor)
    try:
        cur.execute("""
            SELECT message, trigger_time, priority_level, priority, status
            FROM reminders
            WHERE user_id = %s AND status = 'active'
            ORDER BY priority ASC, trigger_time ASC
            LIMIT %s
        """, (user_id, limit))
        return [dict(r) for r in cur.fetchall()]
    finally:
        cur.close()
        conn.close()