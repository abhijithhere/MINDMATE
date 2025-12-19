import sqlite3
import random
import bcrypt
from datetime import datetime, timedelta
import os

# --- CONFIGURATION ---
DB_PATH = os.path.join("db", "mindmate.db")
USER_ID = "test_user"
PASSWORD = "password"  # You will use this to login

def get_db():
    return sqlite3.connect(DB_PATH)

def generate_comprehensive_data():
    conn = get_db()
    cur = conn.cursor()

    print("🧹 Cleaning old data...")
    tables = ["events", "locations", "memories", "reminders", "voice_analysis", "habits", "feedback", "users"]
    for table in tables:
        cur.execute(f"DELETE FROM {table}")
        cur.execute(f"DELETE FROM sqlite_sequence WHERE name='{table}'")

    # 1. CREATE USER (With Valid Password Hash)
    print(f"👤 Creating user: {USER_ID}...")
    pwd_bytes = PASSWORD.encode('utf-8')
    salt = bcrypt.gensalt()
    hashed_password = bcrypt.hashpw(pwd_bytes, salt).decode('utf-8')

    cur.execute("""
        INSERT INTO users (user_id, email, password_hash)
        VALUES (?, ?, ?)
    """, (USER_ID, "test@example.com", hashed_password))

    # 2. LOCATIONS
    print("📍 Creating Locations...")
    loc_map = {}
    locations = [
        ("Home", "123 Main St", 0.0, 0.0),
        ("Office", "Tech Park, Bld 4", 0.0, 0.0),
        ("Gym", "Iron Paradise", 0.0, 0.0),
        ("Cafe", "Starbucks Downtown", 0.0, 0.0)
    ]
    for name, addr, lat, lon in locations:
        cur.execute("INSERT INTO locations (user_id, name, address, latitude, longitude) VALUES (?, ?, ?, ?, ?)", 
                    (USER_ID, name, addr, lat, lon))
        loc_map[name] = cur.lastrowid

    # 3. MEMORIES (Facts & Goals)
    print("🧠 Implanting Memories...")
    memories = [
        ("fact", "I am allergic to peanuts", 1.0),
        ("preference", "I prefer aisle seats on flights", 0.8),
        ("goal", "Read 12 books this year", 0.9),
        ("fact", "My passport expires in 2026", 1.0),
        ("preference", "I like my coffee black", 0.95)
    ]
    for m_type, content, conf in memories:
        # Note: Using 'last_reinforced' to match your schema
        cur.execute("INSERT INTO memories (user_id, memory_type, content, confidence_score, last_reinforced) VALUES (?, ?, ?, ?, ?)",
                    (USER_ID, m_type, content, conf, datetime.now().isoformat()))

    # 4. EVENTS & LINKED DATA (Voice, Reminders)
    print("📅 Generating Schedule (Past 14 Days)...")
    
    # Routine Template: (Hour, Duration, Title, Category, Location, StressLevel)
    routine = [
        (7, 0.5, "Morning Jog", "Health", "Home", 0.1),
        (8, 0.5, "Breakfast", "Personal", "Home", 0.0),
        (9, 3.5, "Deep Work", "Work", "Office", 0.6),
        (13, 1.0, "Lunch Break", "Personal", "Cafe", 0.1),
        (14, 4.0, "Meetings & Coding", "Work", "Office", 0.7),
        (18, 1.5, "Gym Session", "Health", "Gym", 0.2),
        (20, 1.0, "Dinner", "Personal", "Home", 0.0),
        (22, 0.5, "Reading", "Personal", "Home", 0.0),
        (23, 7.0, "Sleep", "Health", "Home", 0.0),
    ]

    start_date = datetime.now() - timedelta(days=14)

    for i in range(16): # 14 days past + 2 days future
        current_day = start_date + timedelta(days=i)
        is_weekend = current_day.weekday() >= 5
        
        for hour, duration, title, category, loc_name, stress in routine:
            # Weekend Variation
            if is_weekend and category == "Work":
                title = "Gaming / Relaxing"
                category = "Personal"
                loc_name = "Home"
                stress = 0.0
            
            # Add Random Noise (+/- 15 mins)
            noise = random.randint(-15, 15)
            start_time = current_day.replace(hour=hour, minute=0, second=0) + timedelta(minutes=noise)
            end_time = start_time + timedelta(hours=duration)
            
            # Insert Event
            cur.execute("""
                INSERT INTO events (user_id, title, category, start_time, end_time, location_id, is_completed)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            """, (USER_ID, title, category, start_time.isoformat(), end_time.isoformat(), loc_map.get(loc_name), 1))
            
            event_id = cur.lastrowid

            # 5. VOICE ANALYSIS (Simulate Voice Input)
            if random.random() > 0.6: # 40% of events have voice data
                emotions = ["Neutral", "Happy", "Stressed", "Tired"]
                emotion = emotions[2] if stress > 0.5 else emotions[0]
                cur.execute("""
                    INSERT INTO voice_analysis (user_id, associated_event_id, original_transcript, emotion_label, stress_level)
                    VALUES (?, ?, ?, ?, ?)
                """, (USER_ID, event_id, f"Schedule {title} for {hour} o'clock", emotion, stress))

            # 6. REMINDERS
            if category == "Work" or category == "Health":
                 cur.execute("""
                    INSERT INTO reminders (event_id, user_id, trigger_time, recurrence_rule, priority_level)
                    VALUES (?, ?, ?, ?, ?)
                """, (event_id, USER_ID, (start_time - timedelta(minutes=15)).isoformat(), "DAILY", "High"))

    conn.commit()
    conn.close()
    print("✅ DATABASE FULLY LOADED.")
    print(f"👉 Login with User: '{USER_ID}' | Pass: '{PASSWORD}'")

if __name__ == "__main__":
    generate_comprehensive_data()