# main.py
import os
import asyncio
import psycopg2
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.routers import auth, chat, memories, dashboard, reminders
from services.gmail import deep_sync_gmail
from models.trainer import run_weekly_retraining

PG_CONFIG = {
    "dbname":   "mindmate",
    "user":     "postgres",
    "password": "postgres123",
    "host":     "127.0.0.1",
    "port":     5432,
}


def initialize_db():
    """
    Ensures all tables exist with correct schema.
    NO foreign key constraints on user_id — matches actual production schema.
    user_id is plain TEXT so any authenticated user_id string works.
    """
    try:
        conn   = psycopg2.connect(**PG_CONFIG)
        cursor = conn.cursor()

        cursor.execute("CREATE EXTENSION IF NOT EXISTS vector;")

        # ── users ──────────────────────────────────────────────────────────────
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS users (
                user_id       TEXT PRIMARY KEY,
                username      VARCHAR,
                password_hash TEXT NOT NULL DEFAULT '',
                password      TEXT,
                wake_word     TEXT,
                created_at    TIMESTAMP DEFAULT now()
            )
        """)

        # ── chat_messages ──────────────────────────────────────────────────────
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS chat_messages (
                id             SERIAL PRIMARY KEY,
                user_id        TEXT,
                sender         TEXT,
                text           TEXT,
                location       TEXT,
                embedding      vector(384),
                is_owner_voice INTEGER DEFAULT 0,
                created_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)

        # ── notes ──────────────────────────────────────────────────────────────
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS notes (
                id              SERIAL PRIMARY KEY,
                user_id         TEXT,
                category        TEXT,
                title           TEXT,
                summary         TEXT,
                original_text   TEXT,
                origin_location TEXT,
                embedding       vector(384),
                is_owner_voice  INTEGER DEFAULT 0,
                created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)

        # ── reminders ──────────────────────────────────────────────────────────
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS reminders (
                id              SERIAL PRIMARY KEY,
                user_id         TEXT,
                event_id        INTEGER,
                message         TEXT,
                trigger_time    TIMESTAMP,
                status          TEXT DEFAULT 'active',
                recurrence_rule TEXT,
                priority_level  TEXT,
                priority        INTEGER DEFAULT 3,
                is_owner_voice  INTEGER DEFAULT 0
            )
        """)

        # ── events ─────────────────────────────────────────────────────────────
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS events (
                id              SERIAL PRIMARY KEY,
                user_id         TEXT,
                title           TEXT,
                category        TEXT,
                start_time      TIMESTAMP,
                end_time        TIMESTAMP,
                location_id     INTEGER,
                location_name   TEXT,
                origin_location TEXT,
                description     TEXT
            )
        """)

        # ── memories ───────────────────────────────────────────────────────────
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS memories (
                id               SERIAL PRIMARY KEY,
                user_id          TEXT,
                memory_type      TEXT,
                title            TEXT,
                content          TEXT,
                confidence_score REAL,
                embedding        vector(384),
                created_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                last_reinforced  TIMESTAMP
            )
        """)

        # ── timeline ───────────────────────────────────────────────────────────
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS timeline (
                id         SERIAL PRIMARY KEY,
                user_id    TEXT,
                type       TEXT,
                title      TEXT,
                content    TEXT,
                category   TEXT,
                start_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)

        # ── locations ──────────────────────────────────────────────────────────
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS locations (
                location_id SERIAL PRIMARY KEY,
                user_id     TEXT,
                name        TEXT
            )
        """)

        # ── voice_analysis ─────────────────────────────────────────────────────
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS voice_analysis (
                id                   SERIAL PRIMARY KEY,
                user_id              TEXT,
                associated_event_id  INTEGER,
                original_transcript  TEXT,
                emotion_label        TEXT,
                stress_level         REAL
            )
        """)

        conn.commit()
        cursor.close()
        conn.close()
        print("✅ PostgreSQL tables verified (no FK constraints).")
    except Exception as e:
        print(f"❌ Database init error: {e}")


async def monitor_new_emails_loop():
    """Syncs Gmail every 5 minutes."""
    user_id = "meanonymus87@gmail.com"
    while True:
        try:
            print(f"📬 Gmail agent: checking for {user_id}...")
            deep_sync_gmail(user_id, count=5)
        except Exception as e:
            print(f"❌ Gmail monitor error: {e}")
        await asyncio.sleep(300)


async def schedule_retraining():
    """Retrains models every 7 days."""
    while True:
        try:
            print("🚀 Weekly model retrain starting...")
            await run_weekly_retraining()
        except Exception as e:
            print(f"❌ Retrain error: {e}")
        await asyncio.sleep(604800)


@asynccontextmanager
async def lifespan(app: FastAPI):
    initialize_db()
    email_task = asyncio.create_task(monitor_new_emails_loop())
    train_task = asyncio.create_task(schedule_retraining())
    print("🚀 Background tasks started.")
    yield
    email_task.cancel()
    train_task.cancel()
    print("🛑 Background tasks stopped.")


app = FastAPI(lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router,      prefix="/auth",      tags=["Auth"])
app.include_router(chat.router,      prefix="/chat",      tags=["Chat"])
app.include_router(memories.router,  prefix="/memories",  tags=["Memories"])
app.include_router(dashboard.router, prefix="/dashboard", tags=["Dashboard"])
app.include_router(reminders.router, prefix="/reminders", tags=["Reminders"])


@app.get("/")
async def root():
    return {"message": "MindMate Backend Active"}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)