import sqlite3
from services.db import get_db

def save_voice_entry(user_id, original_text, analysis):
    """
    The Master Saver Function.
    Handles:
    1. Events (Schedules) -> events table
    2. Notes (Memories)   -> memories table
    3. Chat Logs          -> chat_messages table
    4. Locations          -> locations table
    """
    conn = get_db()
    cur = conn.cursor()
    saved_message = None
    
    try:
        # The NLP returns a 'category' key to tell us what it found
        category = analysis.get("category", "none")

        # --- 1. HANDLE SCHEDULES / EVENTS ---
        if category == "schedule" and analysis.get("schedule"):
            evt = analysis["schedule"]
            loc_name = evt.get("location")
            location_id = None

            # A. Handle Location (Check if exists, or Create new)
            if loc_name and loc_name.lower() != "null":
                cur.execute("SELECT location_id FROM locations WHERE user_id = ? AND name = ?", (user_id, loc_name))
                existing_loc = cur.fetchone()
                
                if existing_loc:
                    location_id = existing_loc[0]
                else:
                    cur.execute("INSERT INTO locations (user_id, name) VALUES (?, ?)", (user_id, loc_name))
                    location_id = cur.lastrowid

            # B. Insert Event
            # We use .get() to avoid errors if a field is missing
            cur.execute("""
                INSERT INTO events (user_id, title, category, start_time, end_time, location_id, location_name) 
                VALUES (?, ?, ?, ?, ?, ?, ?)
            """, (
                user_id, 
                evt.get("title", "Untitled Event"), 
                "personal",  # Default category
                evt.get("start_time"), 
                evt.get("end_time"), 
                location_id,
                loc_name # Save the text name too for easy access
            ))
            
            # C. Save Voice Log (Linked to event)
            event_id = cur.lastrowid
            cur.execute("""
                INSERT INTO voice_analysis (user_id, associated_event_id, original_transcript, stress_level) 
                VALUES (?, ?, ?, ?)
            """, (user_id, event_id, original_text, 0.0))

            saved_message = f"✅ Scheduled: {evt.get('title')} at {evt.get('start_time')}"

        # --- 2. HANDLE NOTES / MEMORIES ---
        # (This is the part that was previously in data_saver.py)
        elif category == "note" and analysis.get("note"):
            note = analysis["note"]
            cur.execute("""
                INSERT INTO memories (user_id, memory_type, title, content, confidence_score)
                VALUES (?, ?, ?, ?, ?)
            """, (
                user_id, 
                "general_note",
                note.get("title", "Quick Note"),    # The Heading
                note.get("content", original_text), # The Summary
                0.9
            ))
            saved_message = f"✅ Saved Note: {note.get('title')}"

        # --- 3. ALWAYS SAVE CHAT HISTORY ---
        # (This ensures every conversation is logged, whether it had data or not)
        cur.execute("""
            INSERT INTO chat_messages (user_id, sender, text) 
            VALUES (?, ?, ?)
        """, (user_id, "user", original_text))

        conn.commit()
        return saved_message

    except Exception as e:
        print(f"❌ Error saving entry: {e}")
        conn.rollback()
        return None
    finally:
        conn.close()

def get_schedule_for_date(user_id: str, date_str: str):
    """
    Fetches events for a specific day.
    Used by the dashboard or when the user asks "What am I doing today?"
    """
    conn = get_db()
    conn.row_factory = sqlite3.Row
    cur = conn.cursor()
    
    query = """
        SELECT title, start_time, location_name
        FROM events
        WHERE user_id = ? 
        AND date(start_time) = ?
        ORDER BY start_time ASC
    """
    
    try:
        cur.execute(query, (user_id, date_str))
        rows = cur.fetchall()
    except Exception as e:
        print(f"Query Error: {e}")
        return []
    finally:
        conn.close()
    
    formatted_events = []
    for row in rows:
        # Parse time safely to just show HH:MM
        start_t = row['start_time']
        time_only = start_t.split(' ')[1][:5] if ' ' in start_t else start_t
        
        loc = f" at {row['location_name']}" if row['location_name'] else ""
        formatted_events.append(f"- {time_only}: {row['title']}{loc}")
        
    return formatted_events