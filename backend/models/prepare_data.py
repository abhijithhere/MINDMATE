# models/prepare_data.py
"""
Scans events, reminders, notes, and chat_messages for a user
and generates a training CSV at models/users/{user_id}_data.csv

Run:  python models/prepare_data.py
"""

import os
import sys
import pandas as pd
from datetime import datetime

sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from services.db import get_db

USERS_DIR = os.path.join(os.path.dirname(__file__), "users")
os.makedirs(USERS_DIR, exist_ok=True)

# ── Simple keyword → activity label ───────────────────────────────────────────
def _label(text: str) -> str:
    t = (text or "").lower()
    if any(k in t for k in ["sleep", "bed", "nap"]):          return "Sleep"
    if any(k in t for k in ["breakfast", "morning meal"]):    return "Breakfast"
    if any(k in t for k in ["lunch", "afternoon meal"]):      return "Lunch"
    if any(k in t for k in ["dinner", "supper", "evening meal"]): return "Dinner"
    if any(k in t for k in ["gym", "workout", "exercise", "run", "walk"]): return "Gym"
    if any(k in t for k in ["study", "class", "lecture", "course", "learn"]): return "Study"
    if any(k in t for k in ["work", "office", "meeting", "project", "task", "deadline"]): return "Work"
    if any(k in t for k in ["medicine", "tablet", "pill", "medication"]): return "Medicine"
    if any(k in t for k in ["remind", "todo", "to-do"]): return "Task"
    if any(k in t for k in ["note", "idea", "thought"]): return "Note"
    if any(k in t for k in ["chat", "talk", "convers"]): return "Conversation"
    return "General"


def export_to_csv(user_id: str) -> str:
    conn = get_db()
    rows = []

    try:
        cur = conn.cursor()

        # ── Events ────────────────────────────────────────────────────────────
        cur.execute("""
            SELECT title, category, start_time, end_time, origin_location
            FROM events
            WHERE user_id = %s AND start_time IS NOT NULL
            ORDER BY start_time
        """, (user_id,))
        for title, category, start, end, origin in cur.fetchall():
            label    = _label(category or title or "")
            dur_mins = 60
            if start and end:
                diff = (end - start).total_seconds() / 60
                dur_mins = max(int(diff), 5)
            dt = start if start else datetime.now()
            rows.append({
                "title":       title or "",
                "activity":    label,
                "Hour":        dt.hour,
                "DayOfWeek":   dt.weekday(),
                "Month":       dt.month,
                "duration_min": dur_mins,
                "source":      origin or "Voice",
            })

        # ── Reminders ─────────────────────────────────────────────────────────
        cur.execute("""
            SELECT message, priority_level, trigger_time
            FROM reminders
            WHERE user_id = %s
        """, (user_id,))
        for msg, priority, trigger in cur.fetchall():
            label = _label(msg or "")
            dt    = trigger if trigger else datetime.now()
            rows.append({
                "title":        msg or "",
                "activity":     label,
                "Hour":         dt.hour,
                "DayOfWeek":    dt.weekday(),
                "Month":        dt.month,
                "duration_min": 15,
                "source":       "Reminder",
            })

        # ── Notes ─────────────────────────────────────────────────────────────
        cur.execute("""
            SELECT summary, original_text, category, created_at
            FROM notes
            WHERE user_id = %s AND created_at IS NOT NULL
        """, (user_id,))
        for summary, text, category, created in cur.fetchall():
            label    = _label(category or summary or text or "")
            words    = len((text or "").split())
            dur_mins = max(int(words * 0.5), 2)
            dt       = created if created else datetime.now()
            rows.append({
                "title":        summary or "",
                "activity":     label,
                "Hour":         dt.hour,
                "DayOfWeek":    dt.weekday(),
                "Month":        dt.month,
                "duration_min": dur_mins,
                "source":       "Note",
            })

        # ── Chat messages ──────────────────────────────────────────────────────
        cur.execute("""
            SELECT text, created_at
            FROM chat_messages
            WHERE user_id = %s AND sender = 'user' AND created_at IS NOT NULL
        """, (user_id,))
        for text, created in cur.fetchall():
            dt = created if created else datetime.now()
            rows.append({
                "title":        (text or "")[:60],
                "activity":     "Conversation",
                "Hour":         dt.hour,
                "DayOfWeek":    dt.weekday(),
                "Month":        dt.month,
                "duration_min": 2,
                "source":       "Chat",
            })

        cur.close()
    except Exception as e:
        print(f"❌ DB error: {e}")
    finally:
        conn.close()

    if not rows:
        print(f"❌ No data found for {user_id}.")
        return ""

    df       = pd.DataFrame(rows)
    csv_path = os.path.join(USERS_DIR, f"{user_id}_data.csv")
    df.to_csv(csv_path, index=False)
    print(f"✅ CSV saved: {csv_path}  ({len(df)} rows)")
    return csv_path


if __name__ == "__main__":
    export_to_csv("meanonymus87@gmail.com")