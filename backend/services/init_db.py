import sqlite3
import os
from services.db import get_db

def init_db():
    conn = get_db()
    cur = conn.cursor()

    # 1. USERS - Core Identity (CORRECTED with Password)
    cur.execute("""
    CREATE TABLE IF NOT EXISTS users (
        user_id TEXT PRIMARY KEY,
        email TEXT,
        password_hash TEXT NOT NULL, -- ✅ The critical column
        settings_json TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
    );
    """)

    # 2. LOCATIONS - Places
    cur.execute("""
    CREATE TABLE IF NOT EXISTS locations (
        location_id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        address TEXT,
        latitude REAL,
        longitude REAL,
        is_confirmed BOOLEAN DEFAULT 0,
        FOREIGN KEY(user_id) REFERENCES users(user_id)
    );
    """)

    # 3. EVENTS - Time-based actions
    cur.execute("""
    CREATE TABLE IF NOT EXISTS events (
        event_id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        title TEXT NOT NULL,
        category TEXT,
        start_time TEXT NOT NULL,
        end_time TEXT,
        location_id INTEGER,
        is_completed BOOLEAN DEFAULT 0,
        FOREIGN KEY(user_id) REFERENCES users(user_id),
        FOREIGN KEY(location_id) REFERENCES locations(location_id)
    );
    """)

    # 4. REMINDERS - Notifications
    cur.execute("""
    CREATE TABLE IF NOT EXISTS reminders (
        reminder_id INTEGER PRIMARY KEY AUTOINCREMENT,
        event_id INTEGER,
        user_id TEXT NOT NULL,
        trigger_time TEXT NOT NULL,
        recurrence_rule TEXT,
        priority_level TEXT,
        hard_vs_soft TEXT,
        is_active BOOLEAN DEFAULT 1,
        FOREIGN KEY(event_id) REFERENCES events(event_id),
        FOREIGN KEY(user_id) REFERENCES users(user_id)
    );
    """)

    # 5. MEMORIES - Conceptual Facts
    cur.execute("""
    CREATE TABLE IF NOT EXISTS memories (
        memory_id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        memory_type TEXT,
        content TEXT NOT NULL,
        confidence_score REAL DEFAULT 0.5,
        last_reinforced TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY(user_id) REFERENCES users(user_id)
    );
    """)

    # 6. HABITS - Derived Patterns
    cur.execute("""
    CREATE TABLE IF NOT EXISTS habits (
        habit_id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        activity_name TEXT NOT NULL,
        time_window_start TEXT,
        time_window_end TEXT,
        frequency_count INTEGER DEFAULT 1,
        stability_score REAL DEFAULT 0.0,
        FOREIGN KEY(user_id) REFERENCES users(user_id)
    );
    """)

    # 7. VOICE_ANALYSIS - Input Metadata
    cur.execute("""
    CREATE TABLE IF NOT EXISTS voice_analysis (
        analysis_id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        associated_event_id INTEGER, 
        original_transcript TEXT,
        emotion_label TEXT,
        stress_level REAL,
        speaking_rate REAL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY(associated_event_id) REFERENCES events(event_id)
    );
    """)

    # 8. FEEDBACK - User Corrections
    cur.execute("""
    CREATE TABLE IF NOT EXISTS feedback (
        feedback_id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        target_id INTEGER,
        target_table TEXT,
        action_type TEXT,
        user_comment TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
    );
    """)
    
    conn.commit()
    conn.close()
    print("✅ Database initialized with Correct Architecture.")

if __name__ == "__main__":
    init_db()