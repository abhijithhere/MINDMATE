import os
import sqlite3
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routers import auth, chat, memories,dashboard

app = FastAPI(title="MindMate API")

# 🟢 CORS Middleware for Flutter connection
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DB_PATH = os.path.join(BASE_DIR, "db", "mindmate.db")

@app.on_event("startup")
def on_startup():
    os.makedirs(os.path.dirname(DB_PATH), exist_ok=True)
    with sqlite3.connect(DB_PATH) as conn:
        cursor = conn.cursor()
        cursor.execute("CREATE TABLE IF NOT EXISTS users (user_id TEXT PRIMARY KEY, password TEXT)")
        
        # 🟢 CRITICAL: This table is required for Dr. Sarah / Chef Mario tests
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS notes (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id TEXT,
                category TEXT,
                title TEXT,
                summary TEXT,
                original_text TEXT,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP
            )
        """)

        # Existing events/timeline table
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS events (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id TEXT, title TEXT, category TEXT, 
                start_time TEXT, end_time TEXT, location_name TEXT
            )
        """)
        conn.commit()
    print(f"✅ Database Initialized with 'notes' and 'events' tables.")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)