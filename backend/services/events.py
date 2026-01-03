import sqlite3
from services.db import get_db

def save_voice_entry(user_id, text, analysis):
    """
    Saves the extracted data into the new Relational DB structure.
    1. Locations -> 2. Events -> 3. Reminders -> 4. Voice Analysis
    """
    conn = get_db()
    cur = conn.cursor()
    
    try:
        # --- 1. HANDLE LOCATION (If detected) ---
        location_id = None
        if "location" in analysis and analysis["location"]:
            loc_name = analysis["location"]
            if loc_name and loc_name.lower() != "null":
                # Check if location already exists to avoid duplicates
                cur.execute("SELECT location_id FROM locations WHERE user_id = ? AND name = ?", (user_id, loc_name))
                existing_loc = cur.fetchone()
                
                if existing_loc:
                    location_id = existing_loc[0]
                else:
                    cur.execute("INSERT INTO locations (user_id, name) VALUES (?, ?)", (user_id, loc_name))
                    location_id = cur.lastrowid # Get the new ID
        
        # --- 2. HANDLE EVENT (If detected) ---
        event_id = None
        if "event" in analysis and analysis["event"].get("title"):
            evt = analysis["event"]
            
            # Insert into the new EVENTS table structure
            cur.execute("""
                INSERT INTO events (user_id, title, category, start_time, location_id) 
                VALUES (?, ?, ?, ?, ?)
            """, (user_id, evt['title'], evt['category'], evt['start_time'], location_id))
            
            event_id = cur.lastrowid # We need this ID for the reminder and voice log

        # --- 3. HANDLE REMINDER (If is_reminder is True) ---
        if "reminder" in analysis and analysis["reminder"].get("is_reminder"):
            if event_id:
                # Use the event's start time as the trigger time
                trigger_time = analysis["event"]["start_time"]
                
                cur.execute("""
                    INSERT INTO reminders (event_id, user_id, trigger_time, recurrence_rule, priority_level) 
                    VALUES (?, ?, ?, ?, ?)
                """, (event_id, user_id, trigger_time, None, 'normal'))
            else:
                print("⚠️ Warning: Reminder requested but no Event created. Skipping reminder.")

        # --- 4. SAVE VOICE ANALYSIS (Linked to Event) ---
        # Now we save the raw text and link it to the event we just made
        cur.execute("""
            INSERT INTO voice_analysis (user_id, associated_event_id, original_transcript, stress_level) 
            VALUES (?, ?, ?, ?)
        """, (user_id, event_id, text, 0.0)) # Default stress to 0.0 for now

        conn.commit()
        print(f"✅ Data Saved! Event ID: {event_id}, Location ID: {location_id}")
        return True

    except Exception as e:
        print(f"❌ Error saving entry: {e}")
        conn.rollback()
        return False
    finally:
        conn.close()

def get_schedule_for_date(user_id: str, date_str: str):
    """
    Fetches events for a specific day using the new table structure.
    """
    conn = get_db()
    conn.row_factory = sqlite3.Row
    cur = conn.cursor()
    
    # We now JOIN events with locations to get the location name
    query = """
        SELECT e.title, e.start_time, l.name as location_name
        FROM events e
        LEFT JOIN locations l ON e.location_id = l.location_id
        WHERE e.user_id = ? 
        AND date(e.start_time) = ?
        ORDER BY e.start_time ASC
    """
    
    cur.execute(query, (user_id, date_str))
    rows = cur.fetchall()
    conn.close()
    
    formatted_events = []
    for row in rows:
        time_only = row['start_time'].split(' ')[1][:5] # Extract HH:MM
        loc = f" at {row['location_name']}" if row['location_name'] else ""
        formatted_events.append(f"- {time_only}: {row['title']}{loc}")
        
    return formatted_events