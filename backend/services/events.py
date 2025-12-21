from services.db import get_db
from datetime import datetime
import sqlite3

def get_or_create_location(cur, user_id, location_name):
    """Helper to find a location ID or create a new one."""
    if not location_name: return None
    
    # Check if exists
    cur.execute("SELECT location_id FROM locations WHERE user_id = ? AND name = ?", (user_id, location_name))
    row = cur.fetchone()
    if row: return row[0]
    
    # Create new
    cur.execute("INSERT INTO locations (user_id, name) VALUES (?, ?)", (user_id, location_name))
    return cur.lastrowid

def save_voice_entry(user_id: str, text: str, data: dict):
    """Parses the NLP JSON and inserts into appropriate DB tables."""
    conn = get_db()
    cur = conn.cursor()
    
    try:
        # 1. SAVE MEMORY
        if data.get("memory"):
            mem = data["memory"]
            cur.execute("""
                INSERT INTO memories (user_id, memory_type, content, confidence_score)
                VALUES (?, ?, ?, ?)
            """, (user_id, mem.get("type", "fact"), mem["content"], mem.get("confidence", 0.5)))
            print(f"💾 Memory Saved: {mem['content']}")

        # 2. SAVE EVENT
        event_id = None
        if data.get("event"):
            evt = data["event"]
            loc_id = get_or_create_location(cur, user_id, evt.get("location_name"))
            
            cur.execute("""
                INSERT INTO events (user_id, title, category, start_time, location_id)
                VALUES (?, ?, ?, ?, ?)
            """, (user_id, evt["title"], evt.get("category", "Personal"), evt["start_time"], loc_id))
            
            event_id = cur.lastrowid
            print(f"📅 Event Saved: {evt['title']}")

        # 3. SAVE REMINDER
        if data.get("reminder") and event_id:
            rem = data["reminder"]
            cur.execute("""
                INSERT INTO reminders (event_id, user_id, trigger_time, recurrence_rule, priority_level)
                VALUES (?, ?, ?, ?, ?)
            """, (event_id, user_id, data["event"]["start_time"], rem.get("recurrence"), rem.get("priority", "Medium")))

        # 4. SAVE RAW LOG (Voice Analysis)
        meta = data.get("voice_meta", {})
        cur.execute("""
            INSERT INTO voice_analysis (user_id, associated_event_id, original_transcript, emotion_label, stress_level)
            VALUES (?, ?, ?, ?, ?)
        """, (user_id, event_id, text, meta.get("emotion_label", "neutral"), meta.get("stress_level", 0.0)))

        conn.commit()
        return True

    except Exception as e:
        print(f"❌ Database Save Error: {e}")
        conn.rollback()
        return False
    finally:
        conn.close()
        

def get_schedule_for_date(user_id: str, date_str: str):
    """
    Fetches all events for a specific date string (YYYY-MM-DD).
    """
    conn = get_db()
    conn.row_factory = sqlite3.Row
    cur = conn.cursor()
    
    # We use LIKE 'YYYY-MM-DD%' to match the start of the ISO timestamp
    query_date = f"{date_str}%"
    
    cur.execute("""
        SELECT title, start_time, category 
        FROM events 
        WHERE user_id = ? 
        AND start_time LIKE ? 
        ORDER BY start_time ASC
    """, (user_id, query_date))
    
    rows = cur.fetchall()
    conn.close()
    
    if not rows:
        return []
        
    # Convert to a clean list of dicts
    schedule = []
    for row in rows:
        # Extract just the time (HH:MM) from the full timestamp
        full_dt = datetime.fromisoformat(row['start_time'])
        time_str = full_dt.strftime("%I:%M %p") # e.g., "09:30 AM"
        
        schedule.append({
            "time": time_str,
            "title": row['title'],
            "category": row['category']
        })
        
    return schedule

def get_schedule_for_date(user_id: str, date_str: str):
    """Fetches all events for a specific date string (YYYY-MM-DD)."""
    conn = get_db()
    conn.row_factory = sqlite3.Row  # Ensure this is imported or available
    cur = conn.cursor()
    
    query_date = f"{date_str}%"
    
    cur.execute("""
        SELECT title, start_time, category 
        FROM events 
        WHERE user_id = ? 
        AND start_time LIKE ? 
        ORDER BY start_time ASC
    """, (user_id, query_date))
    
    rows = cur.fetchall()
    conn.close()
    
    schedule = []
    for row in rows:
        # Simple string formatting
        schedule.append(f"{row['start_time'].split('T')[1][:5]} - {row['title']}")
        
    return schedule