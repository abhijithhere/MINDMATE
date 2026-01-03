import sqlite3
import os

# Define path to the database
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DB_PATH = os.path.join(BASE_DIR, "db", "mindmate.db")

def get_db_connection():
    os.makedirs(os.path.dirname(DB_PATH), exist_ok=True)
    return sqlite3.connect(DB_PATH)

def init_db():
    conn = get_db_connection()
    cur = conn.cursor()
    
    # 1. USERS TABLE
    cur.execute("""
        CREATE TABLE IF NOT EXISTS users (
            user_id TEXT PRIMARY KEY,
            password_hash TEXT NOT NULL,
            wake_word TEXT DEFAULT 'mindmate',
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )
    """)

    # --- 🟢 AUTO-CREATE DEFAULT USER (PLAIN TEXT) ---
    cur.execute("SELECT user_id FROM users WHERE user_id = 'admin'")
    if not cur.fetchone():
        # DIRECTLY INSERTING 'admin' AS PASSWORD (NO HASHING)
        cur.execute("INSERT INTO users (user_id, password_hash) VALUES (?, ?)", ('admin', 'admin'))
        print("👤 Default user 'admin' created (Password: admin)")
    # -----------------------------------------------

    # 2. EVENTS TABLE
    cur.execute("""
        CREATE TABLE IF NOT EXISTS events (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id TEXT,
            title TEXT,
            category TEXT,
            start_time TEXT,
            end_time TEXT,
            location_id INTEGER,
            FOREIGN KEY(user_id) REFERENCES users(user_id)
        )
    """)

    # 3. MEMORIES TABLE
    cur.execute("""
        CREATE TABLE IF NOT EXISTS memories (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id TEXT,
            memory_type TEXT,
            content TEXT,
            confidence_score REAL,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            last_reinforced DATETIME DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY(user_id) REFERENCES users(user_id)
        )
    """)

    # 4. CHAT MESSAGES TABLE
    cur.execute("""
        CREATE TABLE IF NOT EXISTS chat_messages (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id TEXT,
            sender TEXT,
            text TEXT,
            timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY(user_id) REFERENCES users(user_id)
        )
    """)

    # 5. LOCATIONS TABLE
    cur.execute("""
        CREATE TABLE IF NOT EXISTS locations (
            location_id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id TEXT,
            name TEXT
        )
    """)
    
    # 6. REMINDERS TABLE
    cur.execute("""
        CREATE TABLE IF NOT EXISTS reminders (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id TEXT,
            event_id INTEGER,
            message TEXT,
            trigger_time TEXT,
            status TEXT DEFAULT 'pending',
            recurrence_rule TEXT,
            priority_level TEXT,
            FOREIGN KEY(event_id) REFERENCES events(id)
        )
    """)

    # 7. VOICE ANALYSIS TABLE
    cur.execute("""
        CREATE TABLE IF NOT EXISTS voice_analysis (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id TEXT,
            associated_event_id INTEGER,
            original_transcript TEXT,
            emotion_label TEXT,
            stress_level REAL,
            FOREIGN KEY(associated_event_id) REFERENCES events(id)
        )
    """)

    conn.commit()
    conn.close()
    print("✅ Database tables checked/initialized (Plain Text Mode).")

if __name__ == "__main__":
    init_db()