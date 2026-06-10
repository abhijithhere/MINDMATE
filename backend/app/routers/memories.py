from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel
import requests
from datetime import datetime
import datetime as dt 
from services.db import get_db
from psycopg2.extras import RealDictCursor
from models.predictor import HabitEngine # 🟢 Uses the updated Engine with LabelEncoder

from fastapi import APIRouter, Query

router = APIRouter(tags=["Memories & Planner"])

# Single router definition
router = APIRouter(tags=["Memories & Planner"])

OLLAMA_URL = "http://localhost:11434/api/generate"

class MemoryRequest(BaseModel):
    user_id: str
    title: str
    content: str
    category: str
    type: str = "note"

# --- 1. TIMELINE & MEMORY MANAGEMENT ---

@router.get("/")
async def get_memories(user_id: str = Query(...)):
    """Fetches user memories/timeline for the Life Overview."""
    conn = get_db()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    try:
        cur.execute("""
            SELECT id, type, title, content, category, start_time as created_at 
            FROM timeline 
            WHERE user_id = %s 
            ORDER BY id DESC
        """, (user_id,))
        rows = cur.fetchall()
        return {"timeline": rows if rows else []}
    finally:
        cur.close()
        conn.close()

@router.post("/memories")
def add_memory(memory: MemoryRequest):
    """Adds a manual entry to the timeline."""
    try:
        conn = get_db()
        cursor = conn.cursor()
        now = dt.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        cursor.execute("""
            INSERT INTO timeline (user_id, type, title, content, category, start_time) 
            VALUES (%s, %s, %s, %s, %s, %s)
        """, (memory.user_id, memory.type, memory.title, memory.content, memory.category, now))
        conn.commit()
        return {"status": "success", "message": "Memory added"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        cursor.close()
        conn.close()



@router.get("/predict-timetable")
async def predict_timetable(user_id: str, target_date: str = Query(...)):
    try:
        # 1. Parse the date (e.g., "2026-04-22")
        dt_obj = datetime.strptime(target_date, "%Y-%m-%d")
        
        # 2. Initialize Engine with the current user
        # This will load: models/users/meanonymus87@gmail.com.pkl
        engine = HabitEngine(user_id)
        
        timetable = []
        for hour in range(24):
            # 🟢 THE FIX: Pass DayOfWeek and Month to the model
            # weekday() returns 0 for Monday, 6 for Sunday
            activity = engine.predict(hour, dt_obj.weekday(), dt_obj.month)
            
            timetable.append({
                "time": f"{str(hour).zfill(2)}:00",
                "activity": activity.replace("acctivity", "activity")
            })
            
        return {"timetable": timetable}
    except Exception as e:
        print(f"❌ Timetable Error: {e}")
        return {"timetable": [], "error": str(e)}

# --- 3. OLLAMA FALLBACK ---

@router.get("/predict/schedule")
def predict_schedule_ollama(date: str):
    """Optional LLM-based fallback for general planning."""
    mock_schedule = [
        {"time": "09:00 AM", "activity": "Work Start"},
        {"time": "01:00 PM", "activity": "Lunch"},
        {"time": "05:00 PM", "activity": "Review"}
    ]
    return {"suggested_schedule": mock_schedule}