import psycopg2
from psycopg2.extras import execute_values
from faker import Faker
import random
from datetime import datetime, timedelta

# Initialize Faker
fake = Faker()

# ── Database Configuration ──
DB_CONFIG = {
    "dbname": "mindmate",
    "user": "postgres",
    "password": "postgres123",  # 🟢 UPDATE THIS TO YOUR DB PASSWORD
    "host": "127.0.0.1",
    "port": 5432
}

USER_EMAIL = "meanonymus87@gmail.com"

# ── Contextual Data Pools ──
PROJECTS = ["MindMate AI", "Artogram", "Smart Blind Stick", "Solar Cleaner", "SAP ABAP Concept"]
TECH_STACK = ["FastAPI", "Python", "Flutter", "PostgreSQL", "Arduino"]
LOCATIONS = ["Jai Bharath Campus", "Cydez Tech Office", "Home Lab", "Library"]

def generate_data():
    chats, events, reminders, memories, notes = [], [], [], [], []
    now = datetime.now()

    # 1. Generate Chat Messages (200 records)
    for _ in range(200):
        dt = now - timedelta(days=random.randint(0, 30), hours=random.randint(0, 23))
        topic = random.choice(PROJECTS + TECH_STACK)
        chats.append((USER_EMAIL, 'user', f"Let's discuss {topic}. {fake.sentence()}", 1, dt))
        chats.append((USER_EMAIL, 'ai', f"Got it. I've updated your notes on {topic}.", 0, dt + timedelta(seconds=2)))

    # 2. Generate Events (50 records)
    for _ in range(50):
        start_time = now + timedelta(days=random.randint(-10, 20), hours=random.randint(-5, 12))
        end_time = start_time + timedelta(hours=random.randint(1, 3))
        events.append((
            USER_EMAIL, 
            f"Meeting regarding {random.choice(PROJECTS)}", 
            random.choice(['College', 'Work', 'Personal']), 
            start_time, 
            end_time, 
            random.choice(LOCATIONS), 
            random.choice(['Voice', 'Gmail']), 
            fake.text(max_nb_chars=100)
        ))

    # 3. Generate Reminders (50 records)
    for _ in range(50):
        trigger = now + timedelta(days=random.randint(0, 14), hours=random.randint(1, 24))
        priority_level = random.choice(['High', 'Medium', 'Low'])
        priority_num = {'High': 1, 'Medium': 2, 'Low': 3}[priority_level]
        reminders.append((
            USER_EMAIL, 
            f"{fake.catch_phrase()} for {random.choice(PROJECTS)}", 
            trigger, 
            'active', 
            priority_level, 
            priority_num, 
            1
        ))

    # 4. Generate Memories (30 records)
    for _ in range(30):
        dt = now - timedelta(days=random.randint(5, 60))
        memories.append((
            USER_EMAIL, 
            random.choice(["Preference", "Fact", "Skill"]), 
            f"Knowledge: {random.choice(TECH_STACK)}", 
            fake.sentence(), 
            round(random.uniform(0.7, 1.0), 2), 
            dt
        ))

    # 5. Generate Notes (40 records) - 🟢 ADDED THIS
    for _ in range(40):
        notes.append((
            USER_EMAIL, 
            random.choice(['Study', 'Project', 'General']), 
            f"Research on {random.choice(TECH_STACK)}", 
            fake.sentence(), 
            fake.paragraph(nb_sentences=4), 
            random.choice(['Voice', 'Manual']), 
            1
        ))

    return chats, events, reminders, memories, notes


def seed_database():
    print("🌱 Connecting to the database...")
    try:
        conn = psycopg2.connect(**DB_CONFIG)
        cur = conn.cursor()

        print("⚙️ Generating contextual dataset...")
        chats, events, reminders, memories, notes = generate_data()

        # ── Insert Chats ──
        execute_values(cur, """
            INSERT INTO chat_messages (user_id, sender, text, is_owner_voice, created_at) VALUES %s
        """, chats)
        print(f"✅ Inserted {len(chats)} chat messages.")

        # ── Insert Events ──
        execute_values(cur, """
            INSERT INTO events (user_id, title, category, start_time, end_time, location_name, origin_location, description) VALUES %s
        """, events)
        print(f"✅ Inserted {len(events)} events.")

        # ── Insert Reminders ──
        execute_values(cur, """
            INSERT INTO reminders (user_id, message, trigger_time, status, priority_level, priority, is_owner_voice) VALUES %s
        """, reminders)
        print(f"✅ Inserted {len(reminders)} reminders.")

        # ── Insert Memories ──
        execute_values(cur, """
            INSERT INTO memories (user_id, memory_type, title, content, confidence_score, created_at) VALUES %s
        """, memories)
        print(f"✅ Inserted {len(memories)} memories.")

        # ── Insert Notes ── 🟢 ADDED THIS
        execute_values(cur, """
            INSERT INTO notes (user_id, category, title, summary, original_text, origin_location, is_owner_voice) VALUES %s
        """, notes)
        print(f"✅ Inserted {len(notes)} notes.")

        # Commit transaction
        conn.commit()
        print("\n🎉 ALL DATA SUCCESSFULLY SAVED TO DATABASE!")

    except Exception as e:
        print(f"\n❌ ERROR: {e}")
        if conn:
            conn.rollback()
    finally:
        if cur:
            cur.close()
        if conn:
            conn.close()

if __name__ == "__main__":
    seed_database()