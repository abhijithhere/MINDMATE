from services.db import get_db

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