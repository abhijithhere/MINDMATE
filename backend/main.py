from fastapi import FastAPI, UploadFile, File, Form, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import shutil
import os
import uvicorn
import sqlite3
from datetime import datetime
from passlib.context import CryptContext
from pydantic import BaseModel

# --- IMPORTS (Ensure these exist in your project) ---
from app.stt import transcribe_file
from app.nlp import extract_metadata
from services.events import save_voice_entry
from services.init_db import init_db
from services.db import get_db
from services.model import MindMateModel 

app = FastAPI(title="MindMate API")

@app.get("/memories")
async def get_memories(user_id: str):
    conn = get_db()
    conn.row_factory = sqlite3.Row
    cur = conn.cursor()
    
    # Fetch Events
    cur.execute("""
        SELECT title, category, start_time, 'event' as type 
        FROM events 
        WHERE user_id = ? 
        ORDER BY start_time DESC
    """, (user_id,))
    events = [dict(row) for row in cur.fetchall()]
    
    # Fetch Memories (✅ FIXED: Changed 'created_at' to 'last_reinforced')
    cur.execute("""
        SELECT content, memory_type as category, last_reinforced as start_time, 'memory' as type 
        FROM memories 
        WHERE user_id = ? 
        ORDER BY last_reinforced DESC
    """, (user_id,))
    memories = [dict(row) for row in cur.fetchall()]
    
    conn.close()
    
    timeline = events + memories
    # Sort mixed list by time (newest first)
    timeline.sort(key=lambda x: x['start_time'], reverse=True)
    
    return {"timeline": timeline}

# --- CORS (Important for Mobile App connection) ---
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- SECURITY CONFIG ---
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def get_password_hash(password):
    return pwd_context.hash(password)

def verify_password(plain_password, hashed_password):
    return pwd_context.verify(plain_password, hashed_password)

class UserAuth(BaseModel):
    user_id: str
    password: str

# --- GLOBAL ML BRAIN ---
ml_brain = None

# 1. STARTUP EVENT
@app.on_event("startup")
def on_startup():
    init_db()
    global ml_brain
    ml_brain = MindMateModel()
    print("🚀 MindMate Backend & ML Brain Started")

# 2. AUTH ENDPOINTS
@app.post("/signup")
async def signup(user: UserAuth):
    conn = get_db()
    cur = conn.cursor()
    try:
        cur.execute("SELECT user_id FROM users WHERE user_id = ?", (user.user_id,))
        if cur.fetchone():
            raise HTTPException(status_code=400, detail="Username taken")
        
        hashed_pw = get_password_hash(user.password)
        cur.execute("INSERT INTO users (user_id, password_hash) VALUES (?, ?)", 
                    (user.user_id, hashed_pw))
        conn.commit()
        return {"status": "success", "message": "User created"}
    finally:
        conn.close()

@app.post("/login")
async def login(user: UserAuth):
    conn = get_db()
    conn.row_factory = sqlite3.Row
    cur = conn.cursor()
    try:
        cur.execute("SELECT password_hash FROM users WHERE user_id = ?", (user.user_id,))
        row = cur.fetchone()
        
        if not row or not verify_password(user.password, row['password_hash']):
            raise HTTPException(status_code=401, detail="Invalid credentials")
        
        return {"status": "success", "user_id": user.user_id}
    finally:
        conn.close()

# 3. MEMORY ENDPOINT (MISSING BEFORE!)
@app.get("/memories")
async def get_memories(user_id: str):
    conn = get_db()
    conn.row_factory = sqlite3.Row
    cur = conn.cursor()
    
    # Fetch Events
    cur.execute("""
        SELECT title, category, start_time, 'event' as type 
        FROM events 
        WHERE user_id = ? 
        ORDER BY start_time DESC
    """, (user_id,))
    events = [dict(row) for row in cur.fetchall()]
    
    # Fetch Memories
    cur.execute("""
        SELECT content, memory_type as category, created_at as start_time, 'memory' as type 
        FROM memories 
        WHERE user_id = ? 
        ORDER BY created_at DESC
    """, (user_id,))
    memories = [dict(row) for row in cur.fetchall()]
    
    conn.close()
    
    timeline = events + memories
    # Sort mixed list by time (newest first)
    timeline.sort(key=lambda x: x['start_time'], reverse=True)
    
    return {"timeline": timeline}

# 4. AUDIO UPLOAD
@app.post("/upload-audio")
async def upload_audio(
    file: UploadFile = File(...),
    user_id: str = Form(...) 
):
    temp_filename = f"temp_{file.filename}"
    try:
        with open(temp_filename, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
            
        print(f"🎤 Processing audio for: {user_id}")
        text = transcribe_file(temp_filename)
        
        if not text:
            return {"status": "error", "message": "No speech detected"}

        analysis = extract_metadata(text)
        save_voice_entry(user_id, text, analysis)

        return {"status": "success", "transcript": text, "data": analysis}
    except Exception as e:
        print(f"❌ Error: {e}")
        return {"status": "error", "message": str(e)}
    finally:
        if os.path.exists(temp_filename):
            os.remove(temp_filename)

# 5. PREDICTION ENDPOINT
@app.post("/predict")
async def predict_next(
    previous_activity: str,
    current_location: str,
    current_fatigue: str
):
    if not ml_brain:
        return {"status": "error", "message": "Model not loaded"}
    
    preds = ml_brain.predict_next_slot(
        previous_activity, 
        current_location, 
        current_fatigue, 
        datetime.now()
    )
    return {"predictions": preds}

@app.get("/analytics/period")
async def get_period_overview(user_id: str, start_date: str, end_date: str):
    conn = get_db()
    cur = conn.cursor()
    
    # Get all events in range
    cur.execute("""
        SELECT category, start_time, end_time 
        FROM events 
        WHERE user_id = ? AND start_time BETWEEN ? AND ?
    """, (user_id, start_date, end_date))
    
    rows = cur.fetchall()
    conn.close()
    
    stats = {}
    total_hours = 0
    
    for cat, start, end in rows:
        try:
            s = datetime.fromisoformat(start)
            e = datetime.fromisoformat(end)
            duration = (e - s).total_seconds() / 3600 # in hours
            
            stats[cat] = stats.get(cat, 0) + duration
            total_hours += duration
        except:
            continue
            
    return {"stats": stats, "total_tracked_hours": total_hours}

# 7. PREDICT FUTURE TIMETABLE
@app.get("/predict/schedule")
async def get_ai_schedule(date: str):
    if not ml_brain:
        return {"error": "Brain not loaded"}
    
    # Generate schedule for the requested date
    timetable = ml_brain.suggest_daily_schedule(date)
    return {"date": date, "suggested_schedule": timetable}

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)