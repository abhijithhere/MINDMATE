import sqlite3
import os
from datetime import datetime, timedelta
import random

# Fix path to point to your actual database location
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
# Navigate to services/mindmate.db or db/mindmate.db depending on your folder
DB_PATH = os.path.join(BASE_DIR, "db", "mindmate.db") 

# If your DB is in services/mindmate.db, change the line above to:
# DB_PATH = os.path.join(BASE_DIR, "services", "mindmate.db")

def seed_history(user_id="admin"):
    if not os.path.exists(DB_PATH):
        print(f"❌ Error: DB not found at {DB_PATH}")
        return

    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()

    print(f"🌱 Planting 30 days of fake history for '{user_id}'...")

    activities = [
        ("08:00", "Gym"),
        ("09:00", "Breakfast"),
        ("10:00", "Work"),
        ("13:00", "Lunch"),
        ("14:00", "Work"),
        ("18:00", "Study"),
        ("20:00", "Dinner"),
        ("23:00", "Sleep")
    ]

    # Generate data for the PAST 30 days
    base_date = datetime.now() - timedelta(days=30)

    count = 0
    for day in range(30):
        current_date = base_date + timedelta(days=day)
        date_str = current_date.strftime("%Y-%m-%d")
        
        for time_str, title in activities:
            # 20% chance to skip an activity (adds realism)
            if random.random() < 0.2:
                continue

            start_dt = f"{date_str} {time_str}:00"
            
            # Simple Insert
            try:
                cursor.execute("""
                    INSERT INTO events (user_id, title, start_time, location_id, category)
                    VALUES (?, ?, ?, ?, ?)
                """, (user_id, title, start_dt, "Home", "Routine"))
                count += 1
            except Exception as e:
                print(f"Error inserting: {e}")

    conn.commit()
    conn.close()
    print(f"✅ Successfully added {count} event logs for '{user_id}'!")

if __name__ == "__main__":
    seed_history()