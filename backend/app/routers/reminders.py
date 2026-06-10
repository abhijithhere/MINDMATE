# app/routers/reminders.py

from fastapi import APIRouter, Query, HTTPException
from pydantic import BaseModel
from datetime import datetime
from typing import List
import psycopg2.extras
from psycopg2.extras import RealDictCursor
from services.db import get_db

router = APIRouter(tags=["Reminders"])

# --- MODELS ---

class ToggleRequest(BaseModel):
    reminder_id: int
    is_active: bool

class ReminderCreate(BaseModel):
    user_id: str
    message: str
    trigger_time: datetime
    priority_level: str

# --- HELPERS ---

def format_rows(rows):
    result = []
    for r in rows:
        row_dict = dict(r)
        if row_dict.get('trigger_time'):
            row_dict['trigger_time'] = row_dict['trigger_time'].isoformat()
        result.append(row_dict)
    return result

# --- ROUTES ---

@router.get("/debug")
async def debug_reminders(user_id: str = Query(...)):
    """
    DEBUG: Shows ALL reminders for a user with their exact priority_level
    and status values. Use this to verify what's actually in the DB.
    Call: GET /reminders/debug?user_id=YOUR_ID
    """
    conn = get_db()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    try:
        cur.execute("""
            SELECT id, message, priority_level, status, trigger_time
            FROM reminders
            WHERE user_id = %s
            ORDER BY id DESC
            LIMIT 50
        """, (user_id,))
        rows = cur.fetchall()
        return {
            "count": len(rows),
            "rows": format_rows(rows),
            "distinct_priority_levels": list({r['priority_level'] for r in rows}),
            "distinct_statuses":        list({r['status']         for r in rows}),
        }
    finally:
        cur.close()
        conn.close()


@router.get("/")
async def get_reminders(user_id: str = Query(...)):
    """Fetches all reminders for a specific user."""
    conn = get_db()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    try:
        cur.execute("""
            SELECT
                id,
                message as title,
                TO_CHAR(trigger_time, 'HH12:MI AM') as remind_time,
                trigger_time as raw_time,
                status,
                priority_level,
                priority
            FROM reminders
            WHERE user_id = %s
            ORDER BY priority ASC, trigger_time ASC
        """, (user_id,))

        rows = cur.fetchall()
        for row in rows:
            row['is_active'] = (row['status'] == 'active')
            if isinstance(row['raw_time'], datetime):
                row['raw_time'] = row['raw_time'].isoformat()

        return {"reminders": rows}
    except Exception as e:
        print(f"Database Error: {e}")
        raise HTTPException(status_code=500, detail="Failed to fetch reminders")
    finally:
        cur.close()
        conn.close()


@router.get("/filter")
async def get_filtered_reminders(user_id: str, priorities: List[str] = Query(default=[])):
    conn = get_db()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    try:
        if not priorities:
            cur.execute("""
                SELECT * FROM reminders
                WHERE user_id = %s AND status = 'active'
                ORDER BY trigger_time ASC
            """, (user_id,))
        else:
            cur.execute("""
                SELECT * FROM reminders
                WHERE user_id = %s
                  AND status = 'active'
                  AND LOWER(priority_level) = ANY(%s)
                ORDER BY trigger_time ASC
            """, (user_id, [p.lower() for p in priorities]))

        return [dict(r) for r in cur.fetchall()]
    except Exception as e:
        print(f"Filter Error: {e}")
        raise HTTPException(status_code=500, detail="Database fetch failed")
    finally:
        cur.close()
        conn.close()


@router.get("/organized")
async def get_organized_tasks(user_id: str = Query(...)):
    """
    Returns High priority for reminders page and Low priority for todo page.

    FIX: Uses LOWER(priority_level) for case-insensitive matching so rows
    stored as 'low', 'Low', or 'LOW' all work correctly.
    Also removed the status='active' filter as a fallback — if todos are
    still empty after this, hit /reminders/debug to see what's in the DB.
    """
    conn = get_db()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    try:
        # High Priority → Reminders screen
        cur.execute("""
            SELECT * FROM reminders
            WHERE user_id = %s
              AND LOWER(priority_level) = 'high'
            ORDER BY trigger_time ASC
        """, (user_id,))
        reminders = cur.fetchall()

        # Low Priority → To-Do screen
        cur.execute("""
            SELECT * FROM reminders
            WHERE user_id = %s
              AND LOWER(priority_level) = 'low'
            ORDER BY trigger_time ASC
        """, (user_id,))
        todos = cur.fetchall()

        print(f"📋 organized [{user_id}]: {len(reminders)} high, {len(todos)} low")

        return {
            "reminders": format_rows(reminders),
            "todos":     format_rows(todos),
        }
    except Exception as e:
        print(f"Organized Fetch Error: {e}")
        return {"reminders": [], "todos": []}
    finally:
        cur.close()
        conn.close()


@router.post("/toggle")
async def toggle_reminder(data: ToggleRequest):
    conn = get_db()
    cur = conn.cursor()
    try:
        new_status = 'active' if data.is_active else 'inactive'
        cur.execute(
            "UPDATE reminders SET status = %s WHERE id = %s",
            (new_status, data.reminder_id)
        )
        conn.commit()
        return {"status": "success", "new_status": new_status}
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        cur.close()
        conn.close()


@router.post("/create")
async def create_new_reminder(data: ReminderCreate):
    conn = get_db()
    cur = conn.cursor()
    try:
        priority_map = {"High": 1, "Medium": 2, "Low": 3}
        # Normalize to title-case before saving so DB is always consistent
        normalized_priority = data.priority_level.strip().title()
        num_priority = priority_map.get(normalized_priority, 3)

        cur.execute("""
            INSERT INTO reminders (user_id, message, trigger_time, status, priority_level, priority)
            VALUES (%s, %s, %s, 'active', %s, %s)
            RETURNING id
        """, (data.user_id, data.message, data.trigger_time, normalized_priority, num_priority))

        new_id = cur.fetchone()[0]
        conn.commit()
        return {"status": "success", "message": "Reminder created", "reminder_id": new_id}
    except Exception as e:
        conn.rollback()
        print(f"Insert Error: {e}")
        raise HTTPException(status_code=500, detail="Failed to create reminder")
    finally:
        cur.close()
        conn.close()


@router.delete("/delete/{reminder_id}")
async def delete_reminder(reminder_id: int):
    conn = get_db()
    cur = conn.cursor()
    try:
        cur.execute("DELETE FROM reminders WHERE id = %s", (reminder_id,))
        conn.commit()
        return {"status": "success", "message": "Reminder deleted"}
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        cur.close()
        conn.close()


@router.delete("/delete/all")
async def delete_all_reminders(user_id: str = Query(...)):
    conn = get_db()
    cur = conn.cursor()
    try:
        cur.execute("DELETE FROM reminders WHERE user_id = %s", (user_id,))
        conn.commit()
        deleted_count = cur.rowcount
        return {"status": "success", "message": f"Successfully deleted {deleted_count} reminders"}
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        cur.close()
        conn.close()