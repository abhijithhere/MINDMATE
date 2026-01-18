import sqlite3, os
from services.db import get_db

def log_chat(user_id, sender, text):
    conn = get_db()
    try:
        conn.execute("INSERT INTO messages (user_id, sender, text) VALUES (?, ?, ?)", (user_id, sender, text))
        conn.commit()
    except: pass
    finally: conn.close()

def save_extracted_data(user_id, data):
    category = data.get("category", "").lower()
    conn = get_db()
    try:
        cur = conn.cursor()
        if category == "schedule" or "schedule" in data:
            s = data.get("schedule", {})
            cur.execute("INSERT INTO events (user_id, title, start_time, location_name) VALUES (?, ?, ?, ?)",
                        (user_id, s.get('title'), s.get('start_time'), s.get('location')))
        elif category == "note" or "note" in data:
            n = data.get("note", {})
            cur.execute("INSERT INTO notes (user_id, category, title, summary, original_text) VALUES (?, ?, ?, ?, ?)",
                        (user_id, n.get('category'), n.get('heading'), n.get('summary'), data.get('raw_text')))
        conn.commit()
        return True
    except Exception as e:
        print(f"Error: {e}")
        return False
    finally: conn.close()