# app/routers/dashboard.py
"""
Dashboard endpoints.
/dashboard              -> daily stats summary
/dashboard/life-overview -> per-activity time breakdown for a date range
"""

import re
from datetime import datetime
from fastapi import APIRouter
from psycopg2.extras import RealDictCursor
from services.db import get_db

router = APIRouter()


# ── Helper to extract specific activity from text ─────────────────────────────
def _extract_activity(text: str, default_label: str) -> str:
    """Scans text for keywords to categorize into specific activities."""
    if not text:
        return default_label
        
    t = text.lower()
    
    # Priority Activity Mapping
    if any(k in t for k in ["sleep", "nap", "bed", "wake"]): 
        return "Sleep"
    if any(k in t for k in ["assignment", "homework", "project", "thesis"]): 
        return "Assignment"
    if any(k in t for k in ["study", "learn", "course", "read", "lecture"]): 
        return "Study"
    if any(k in t for k in ["work", "office", "job", "client", "meeting"]): 
        return "Work"
    if any(k in t for k in ["walk", "stroll", "walking"]): 
        return "Walk"
    if any(k in t for k in ["gym", "workout", "exercise", "train", "fitness"]): 
        return "Gym"
    if any(k in t for k in ["breakfast", "lunch", "dinner", "eat", "meal", "food"]): 
        return "Food"
    if any(k in t for k in ["rest", "relax", "leisure", "movie", "game", "play"]): 
        return "Rest"
    if any(k in t for k in ["code", "coding", "programming", "bug", "software"]): 
        return "Coding"
    if any(k in t for k in ["clean", "chore", "laundry", "wash"]): 
        return "Chores"
    if any(k in t for k in ["meditate", "yoga", "breathe", "pray"]): 
        return "Wellness"
    if any(k in t for k in ["pill", "medicine", "doctor", "clinic", "health"]): 
        return "Health"
        
    return default_label


# ── /dashboard  (existing daily stats) ────────────────────────────────────────
@router.get("")
async def get_dashboard(user_id: str):
    conn = get_db()
    cur  = conn.cursor(cursor_factory=RealDictCursor)
    try:
        cur.execute("SELECT COUNT(*) AS cnt FROM notes     WHERE user_id=%s", (user_id,))
        notes_count = cur.fetchone()["cnt"]

        cur.execute("SELECT COUNT(*) AS cnt FROM reminders WHERE user_id=%s AND status='active'", (user_id,))
        reminders_count = cur.fetchone()["cnt"]

        cur.execute("SELECT COUNT(*) AS cnt FROM events    WHERE user_id=%s", (user_id,))
        events_count = cur.fetchone()["cnt"]

        cur.execute("SELECT COUNT(*) AS cnt FROM memories  WHERE user_id=%s", (user_id,))
        memories_count = cur.fetchone()["cnt"]

        cur.execute("SELECT COUNT(*) AS cnt FROM chat_messages WHERE user_id=%s", (user_id,))
        chats_count = cur.fetchone()["cnt"]

        return {
            "notes":      notes_count,
            "reminders":  reminders_count,
            "events":     events_count,
            "memories":   memories_count,
            "chats":      chats_count,
        }
    except Exception as e:
        print(f"❌ Dashboard error: {e}")
        return {"notes": 0, "reminders": 0, "events": 0, "memories": 0, "chats": 0}
    finally:
        cur.close(); conn.close()


# ── /dashboard/life-overview  (period activity breakdown) ────────────────────
@router.get("/life-overview")
async def get_life_overview(
    user_id:    str,
    start_date: str = None,
    end_date:   str = None,
):
    """
    Scans events, reminders, notes, memories and chat_messages for the period.
    Returns per-activity time totals and counts categorized by specific actions.
    """
    try:
        start = datetime.strptime(start_date, "%Y-%m-%d") if start_date else \
                datetime.now().replace(hour=0, minute=0, second=0) - \
                __import__('datetime').timedelta(days=7)
        end   = datetime.strptime(end_date, "%Y-%m-%d").replace(
                    hour=23, minute=59, second=59) if end_date else datetime.now()
    except ValueError:
        start = datetime.now() - __import__('datetime').timedelta(days=7)
        end   = datetime.now()

    conn = get_db()
    cur  = conn.cursor(cursor_factory=RealDictCursor)

    activity_buckets: dict[str, dict] = {}

    def _add(label: str, minutes: int) -> None:
        label = label.strip().title() if label else "Other"
        if label not in activity_buckets:
            activity_buckets[label] = {"total_minutes": 0, "count": 0}
        activity_buckets[label]["total_minutes"] += max(minutes, 0)
        activity_buckets[label]["count"]         += 1

    try:
        # ── Events ────────────────────────────────────────────────────────────
        cur.execute("""
            SELECT title, category, start_time, end_time
            FROM events
            WHERE user_id = %s
              AND start_time BETWEEN %s AND %s
        """, (user_id, start, end))
        for row in cur.fetchall():
            raw_text = f"{row['title'] or ''} {row['category'] or ''}"
            fallback_label = row["category"] or row["title"] or "Event"
            label = _extract_activity(raw_text, fallback_label)
            
            mins  = 60  # default 1h if no end_time
            if row["start_time"] and row["end_time"]:
                diff = (row["end_time"] - row["start_time"]).total_seconds() / 60
                mins = int(diff) if diff > 0 else 60
            _add(label, mins)

        # ── Reminders ─────────────────────────────────────────────────────────
        cur.execute("""
            SELECT message, priority_level, trigger_time
            FROM reminders
            WHERE user_id = %s
              AND (trigger_time BETWEEN %s AND %s OR trigger_time IS NULL)
            LIMIT 200
        """, (user_id, start, end))
        for row in cur.fetchall():
            raw_text = row["message"] or ""
            label = _extract_activity(raw_text, "Task")
            _add(label, 15)  # Assume 15 mins per task

        # ── Notes ─────────────────────────────────────────────────────────────
        cur.execute("""
            SELECT original_text, category, created_at
            FROM notes
            WHERE user_id = %s
              AND created_at BETWEEN %s AND %s
        """, (user_id, start, end))
        for row in cur.fetchall():
            raw_text = f"{row['original_text'] or ''} {row['category'] or ''}"
            fallback_label = row["category"] or "Note"
            label = _extract_activity(raw_text, fallback_label)
            
            words = len((row["original_text"] or "").split())
            mins  = max(int(words * 0.5), 2)
            _add(label, mins)

        # ── Memories ──────────────────────────────────────────────────────────
        cur.execute("""
            SELECT memory_type, created_at
            FROM memories
            WHERE user_id = %s
              AND created_at BETWEEN %s AND %s
        """, (user_id, start, end))
        for row in cur.fetchall():
            raw_text = row["memory_type"] or ""
            label = _extract_activity(raw_text, "Memory")
            _add(label, 2)

        # ── Chat messages ─────────────────────────────────────────────────────
        cur.execute("""
            SELECT COUNT(*) AS cnt
            FROM chat_messages
            WHERE user_id = %s
              AND created_at BETWEEN %s AND %s
              AND sender = 'user'
        """, (user_id, start, end))
        chat_cnt = cur.fetchone()["cnt"] or 0
        if chat_cnt:
            _add("AI Assistant", int(chat_cnt * 1.5))

    except Exception as e:
        print(f"❌ Life overview query error: {e}")
    finally:
        cur.close(); conn.close()

    # Build response
    activities = []
    total_entries = 0
    for label, data in sorted(
            activity_buckets.items(),
            key=lambda x: x[1]["total_minutes"],
            reverse=True):
        total_min = data["total_minutes"]
        count     = data["count"]
        total_entries += count
        activities.append({
            "activity":      label,
            "total_minutes": total_min,
            "total_hours":   round(total_min / 60, 1),
            "avg_minutes":   int(total_min / count) if count else 0,
            "count":         count,
        })

    return {
        "activities": activities,
        "summary": {
            "total_entries":  total_entries,
            "total_minutes":  sum(a["total_minutes"] for a in activities),
            "period_days":    (end - start).days + 1,
        },
    }


# ── /dashboard/gmail (email summary) ─────────────────────────────────────────
@router.get("/gmail")
async def get_gmail_summary(user_id: str):
    conn = get_db()
    cur  = conn.cursor(cursor_factory=RealDictCursor)
    try:
        cur.execute("""
            SELECT title, description, start_time, origin_location
            FROM events
            WHERE user_id = %s AND origin_location = 'Gmail'
            ORDER BY start_time DESC LIMIT 20
        """, (user_id,))
        return {"emails": [dict(r) for r in cur.fetchall()]}
    except Exception as e:
        print(f"❌ Gmail summary error: {e}")
        return {"emails": []}
    finally:
        cur.close(); conn.close()