import sqlite3
import os
import random
from datetime import datetime, timedelta

# Database Path
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DB_PATH = os.path.join(BASE_DIR, "db", "mindmate.db")
USER_ID = "test_user"

def get_db():
    return sqlite3.connect(DB_PATH)

def generate_history():
    print(f"🕰️ Generating 30 days of history for '{USER_ID}'...")
    conn = get_db()
    cur = conn.cursor()

    # 1. Clear existing events to avoid duplicates
    cur.execute("DELETE FROM events WHERE user_id = ?", (USER_ID,))
    
    # 2. Define Routines
    weekday_routine = [
        ("Morning Jog", "Health", 6, 7, "Park"),
        ("Work", "Work", 9, 17, "Office"),
        ("Read Book", "Personal", 20, 21, "Home"),
        ("Sleep", "Health", 23, 7, "Home"), # Ends next day (handled simply here)
    ]
    
    weekend_routine = [
        ("Sleep In", "Health", 0, 9, "Home"),
        ("Gaming", "Leisure", 14, 16, "Home"),
        ("Movie Night", "Social", 19, 22, "Cinema"),
    ]

    events_to_add = []
    
    # 3. Loop back 30 days
    start_date = datetime.now().date() - timedelta(days=30)
    
    for day_offset in range(31): # 0 to 30
        current_day = start_date + timedelta(days=day_offset)
        is_weekend = current_day.weekday() >= 5 # 5=Sat, 6=Sun
        
        routine = weekend_routine if is_weekend else weekday_routine
        
        for title, cat, start_hour, end_hour, loc in routine:
            # Add randomness (e.g., +/- 15 mins)
            minute_offset = random.randint(-15, 15)
            
            # Construct ISO timestamps
            s_time = datetime(current_day.year, current_day.month, current_day.day, start_hour, 0) + timedelta(minutes=minute_offset)
            e_time = datetime(current_day.year, current_day.month, current_day.day, end_hour, 0) + timedelta(minutes=minute_offset)
            
            # Handle overnight sleep (end time is next day)
            if end_hour < start_hour:
                e_time += timedelta(days=1)

            events_to_add.append((
                USER_ID, title, cat, s_time.isoformat(), e_time.isoformat(), loc
            ))

    # 4. Batch Insert
    cur.executemany("""
        INSERT INTO events (user_id, title, category, start_time, end_time)
        VALUES (?, ?, ?, ?, ?)
    """, [e[:5] for e in events_to_add]) # We ignore location for now as schema might vary

    conn.commit()
    conn.close()
    print(f"✅ Successfully added {len(events_to_add)} events.")

if __name__ == "__main__":
    generate_history()