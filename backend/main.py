from fastapi import FastAPI, UploadFile, File, Form, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import shutil
import os
import uvicorn
import sqlite3
from datetime import datetime
from pydantic import BaseModel
from passlib.context import CryptContext 

# --- IMPORTS (Ensure these exist in your project) ---
from app.stt import transcribe_file
from services.init_db import init_db
from services.db import get_db
from services.analytics import get_daily_summary
from services.model import MindMateModel 
from app.nlp import extract_metadata, detect_retrieval_intent
from services.events import save_voice_entry, get_schedule_for_date
from app.advanced_nlp import IntentAnalyzer


app = FastAPI(title="MindMate API")

# --- CORS ---
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
ml_brain = None

intent_analyzer = IntentAnalyzer()# --- MODELS ---
class UserAuth(BaseModel):
    user_id: str
    password: str

class ChatMessage(BaseModel):
    user_id: str
    text: str
    sender: str  # 'user' or 'ai'

# --- HELPERS ---
def get_password_hash(password):
    return pwd_context.hash(password)

def verify_password(plain_password, hashed_password):
    return pwd_context.verify(plain_password, hashed_password)

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

# 3. MEMORY ENDPOINT
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
    
    # Fetch Memories (Using the FIXED version with last_reinforced)
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

# 4. AUDIO UPLOAD
@app.post("/upload-audio")
async def upload_audio(file: UploadFile = File(...), user_id: str = Form(...)):
    temp_filename = f"temp_{file.filename}"
    try:
        with open(temp_filename, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
            
        text = transcribe_file(temp_filename)
        if not text: return {"status": "error", "message": "No speech detected"}

        # We don't save here anymore; saving happens in /chat/send
        return {"status": "success", "transcript": text}
    finally:
        if os.path.exists(temp_filename): os.remove(temp_filename)

# 5. PREDICTION & ANALYTICS
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

@app.get("/predict/schedule")
async def get_ai_schedule(date: str):
    if not ml_brain:
        return {"error": "Brain not loaded"}
    
    # Generate schedule for the requested date
    timetable = ml_brain.suggest_daily_schedule(date)
    return {"date": date, "suggested_schedule": timetable}

# 6. CHAT ENDPOINTS
@app.get("/chat/history")
async def get_chat_history(user_id: str):
    conn = get_db()
    conn.row_factory = sqlite3.Row
    cur = conn.cursor()
    
    cur.execute("SELECT sender, text, timestamp FROM chat_messages WHERE user_id = ? ORDER BY timestamp ASC", (user_id,))
    rows = [dict(row) for row in cur.fetchall()]
    conn.close()
    
    return {"messages": rows}

@app.post("/chat/send")
async def send_chat_message(message: ChatMessage):
    conn = get_db()
    cur = conn.cursor()
    
    # 1. SAVE USER MESSAGE & COMMIT IMMEDIATELY
    cur.execute("INSERT INTO chat_messages (user_id, sender, text) VALUES (?, ?, ?)", 
                (message.user_id, 'user', message.text))
    conn.commit() 
    
    ai_text = ""

    # 2. ANALYZE INTENT (The Traffic Cop)
    # This decides IF we should act, before we decide HOW to act.
    intent_result = intent_analyzer.analyze(message.text)
    intent_type = intent_result['type']

    print(f"DEBUG: NLP Analysis -> {intent_type} | Reason: {intent_result['reason']}")

    # --- CASE A: HYPOTHETICAL / ASSUMPTION ---
    # e.g., "Suppose I have a meeting..." -> IGNORE
    if intent_type == 'assumption':
        ai_text = "I understand that is a hypothetical situation ('Suppose/Imagine'), so I won't schedule it."

    # --- CASE B: RETRIEVAL ---
    # e.g., "When I said..." or "What is my schedule?"
    elif intent_type == 'retrieval':
        # Now we use the OLD nlp.py helper to find the specific DATES
        retrieval_data = detect_retrieval_intent(message.text)
        
        # If the old logic fails to find a date, default to "today" or "tomorrow"
        # But usually, it returns a valid dict if it's a schedule query.
        if retrieval_data and retrieval_data['intent'] == 'get_schedule':
            events = get_schedule_for_date(message.user_id, retrieval_data['date_str'])
            if events:
                ai_text = f"Here is your schedule for {retrieval_data['display_date']}:\n" + "\n".join(events)
            else:
                ai_text = f"You have no events scheduled for {retrieval_data['display_date']}."
        else:
            # Fallback if advanced NLP said "retrieval" but basic NLP couldn't find a date
            ai_text = "I think you're asking for information, but I couldn't figure out which date to check."

    # --- CASE C: VALID COMMAND ---
    # e.g., "Remind me to call John" -> EXECUTE
    elif intent_type == 'command':
        # Now we use the OLD nlp.py to extract the TITLE and TIME
        analysis = extract_metadata(message.text)
        save_success = save_voice_entry(message.user_id, message.text, analysis)
        
        if save_success and "event" in analysis:
            evt = analysis["event"]
            ai_text = f"✅ Done. I've scheduled '{evt['title']}' for {evt['start_time'].split('T')[1][:5]}."
        else:
            ai_text = "I understood that as a command, but I had trouble saving the details."

    # --- CASE D: NOISE / CONVERSATION ---
    # e.g., "He went to the store" or "Hello"
    else: 
        # Quick check for greetings
        if "hello" in message.text.lower():
            ai_text = "Hello! I am ready to help you plan."
        else:
            # It's just random conversation or noise.
            # We log it to memory but don't schedule it.
            ai_text = "I've noted that in your journal."
            # Optional: You can still save this as a "thought" if you want
            analysis = extract_metadata(message.text)
            save_voice_entry(message.user_id, message.text, analysis)

    # 3. SAVE AI RESPONSE
    cur.execute("INSERT INTO chat_messages (user_id, sender, text) VALUES (?, ?, ?)", 
                (message.user_id, 'ai', ai_text))
    
    conn.commit()
    conn.close()
    
    return {"status": "success", "ai_response": ai_text}


@app.get("/dashboard")
async def get_dashboard(user_id: str):
    """
    Returns the daily summary card for the home screen.
    """
    summary = get_daily_summary(user_id)
    return summary

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)