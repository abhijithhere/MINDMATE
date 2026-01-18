import sqlite3
import datetime
import os

# 🟢 CONFIGURATION
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DB_PATH = os.path.join(BASE_DIR, "db", "mindmate.db")

def get_time(day_offset, hour, minute):
    """Helper to generate timestamp strings relative to today."""
    now = datetime.datetime.now()
    target_date = now + datetime.timedelta(days=day_offset)
    target_time = target_date.replace(hour=hour, minute=minute, second=0)
    return target_time.strftime("%Y-%m-%d %H:%M:%S")

def seed_data():
    print(f"📍 Script Location: {BASE_DIR}")
    print(f"🎯 Target Database: {DB_PATH}")

    # Ensure db folder exists
    if not os.path.exists(os.path.dirname(DB_PATH)):
        os.makedirs(os.path.dirname(DB_PATH))

    try:
        conn = sqlite3.connect(DB_PATH)
        cursor = conn.cursor()

        # --- 1. DROP OLD TABLES (CRITICAL FIX) ---
        # This deletes the old 'users' table so we can recreate it with the 'password' column
        print("\n💥 Dropping old tables to update schema...")
        cursor.execute("DROP TABLE IF EXISTS users")
        cursor.execute("DROP TABLE IF EXISTS timeline")
        cursor.execute("DROP TABLE IF EXISTS messages")

        # --- 2. CREATE TABLES (New Structure) ---
        print("🛠️ Creating new tables...")
        cursor.execute("CREATE TABLE users (user_id TEXT PRIMARY KEY, password TEXT)")
        
        cursor.execute("""
            CREATE TABLE timeline (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id TEXT,
                type TEXT,
                title TEXT,
                content TEXT, 
                category TEXT,
                start_time TEXT,
                end_time TEXT,
                is_completed BOOLEAN DEFAULT 0
            )
        """)
        
        cursor.execute("CREATE TABLE messages (id INTEGER PRIMARY KEY, user_id TEXT, sender TEXT, text TEXT)")

        # --- 3. DEFINE DATA ---
        users_data = [
            {
                "user_id": "admin",
                "pass": "1234",
                "profession": "Software Engineer",
                "timeline": [
                    ("event", "Daily Standup", "Zoom link: bit.ly/standup", "Work", get_time(0, 10, 0)),
                    ("event", "Code Review", "Review PR #42 for backend API", "Work", get_time(0, 14, 0)),
                    ("event", "Gym Session", "Chest and Triceps", "Health", get_time(0, 18, 0)),
                    ("note", "Project Ideas", "Build a Flutter plugin for Ollama", "Personal", get_time(0, 20, 0)),
                    ("event", "Flutter Debugging", "Fix the chat screen UI bugs", "Work", get_time(1, 9, 0)),
                ],
                "chat": [
                    ("user", "How do I fix a CORS error in FastAPI?"),
                    ("ai", "You need to add the CORSMiddleware to your FastAPI app instance."),
                    ("user", "What is my schedule for today?"),
                    ("ai", "You have a Daily Standup at 10:00 AM and a Code Review at 2:00 PM."),
                ]
            },
            {
                "user_id": "sarah_design",
                "pass": "design2026",
                "profession": "Graphic Designer",
                "timeline": [
                    ("event", "Client Briefing", "Discuss logo requirements for EcoBrand", "Work", get_time(0, 9, 30)),
                    ("event", "Sketching Phase", "Draft 5 concepts on iPad", "Work", get_time(0, 11, 0)),
                    ("event", "Art Gallery Visit", "Inspiration trip downtown", "Personal", get_time(0, 16, 0)),
                    ("note", "Color Palette", "Teal #008080, Coral #FF7F50, Cream #FFFDD0", "Work", get_time(0, 13, 0)),
                ],
                "chat": [
                    ("user", "Give me some color ideas for a nature brand."),
                    ("ai", "Try using Earth tones: Sage Green, Terracotta, and Sandstone."),
                    ("user", "Remind me to export the SVG files tonight."),
                    ("ai", "Noted. I'll remind you to export SVGs."),
                ]
            },
            {
                "user_id": "dr_mike",
                "pass": "med123",
                "profession": "Doctor",
                "timeline": [
                    ("event", "Morning Rounds", "Check on patients in Ward 3", "Work", get_time(0, 7, 0)),
                    ("event", "Surgery: Appendectomy", "OR Room 4", "Work", get_time(0, 10, 0)),
                    ("event", "Lunch with Staff", "Hospital Cafeteria", "Social", get_time(0, 13, 0)),
                    ("event", "Clinic Consultations", "Outpatient department", "Work", get_time(0, 15, 0)),
                ],
                "chat": [
                    ("user", "What is the dosage for Amoxicillin for adults?"),
                    ("ai", "Standard dosage is often 500mg every 8 hours, but please consult official guidelines."),
                    ("user", "Do I have any surgeries left today?"),
                    ("ai", "Checking your timeline... No, your last surgery was the Appendectomy at 10 AM."),
                ]
            }
        ]

        # --- 4. INSERT DATA ---
        print("🚀 Inserting data for 3 users...")
        
        for user in users_data:
            # Insert User
            cursor.execute("INSERT INTO users (user_id, password) VALUES (?, ?)", (user['user_id'], user['pass']))
            
            # Insert Timeline
            for item in user['timeline']:
                cursor.execute("""
                    INSERT INTO timeline (user_id, type, title, content, category, start_time) 
                    VALUES (?, ?, ?, ?, ?, ?)
                """, (user['user_id'], item[0], item[1], item[2], item[3], item[4]))
            
            # Insert Chat
            for msg in user['chat']:
                cursor.execute("""
                    INSERT INTO messages (user_id, sender, text) 
                    VALUES (?, ?, ?)
                """, (user['user_id'], msg[0], msg[1]))

        conn.commit()
        print(f"\n✅ SUCCESS! Database schema updated and seeded.")

    except Exception as e:
        print(f"\n❌ ERROR: {e}")
    finally:
        if conn:
            conn.close()

if __name__ == "__main__":
    seed_data()