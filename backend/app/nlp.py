import json, requests, sqlite3, re, os
import numpy as np
import joblib
import pandas as pd
from datetime import datetime, timedelta
from services.db import get_db

# --- CONFIG ---
OLLAMA_URL = "http://localhost:11434/api/generate"
MODEL_NAME = "phi3"
MODEL_PATH = os.path.join(os.path.dirname(__file__), "../models/habit_model.pkl")

# --- HABIT MODEL ENGINE ---
class HabitEngine:
    def __init__(self):
        self.activity_map = {0: 'Sleep', 1: 'Breakfast', 2: 'Study', 3: 'Work', 4: 'Rest', 5: 'Gym'}
        try:
            self.model = joblib.load(MODEL_PATH)
        except:
            self.model = None

    def get_prediction(self, hour, day, month, prev_id=0):
        if not self.model: return "Rest"
        # Using DataFrame to avoid Feature Name warnings
        features = pd.DataFrame([[hour, day, month, 0, 1, prev_id]], 
                                columns=['Hour', 'DayOfWeek', 'Month', 'Location', 'Fatigue', 'PrevActivity'])
        pred_id = int(self.model.predict(features)[0])
        return self.activity_map.get(pred_id, "Rest")

habit_engine = HabitEngine()

# --- CONTEXT PROVIDERS ---
def get_db_safe(): return get_db()

def get_user_background_summary(user_id: str):
    conn = get_db_safe()
    cur = conn.cursor()
    profile = []
    try:
        cur.execute("SELECT title FROM events WHERE user_id = ? ORDER BY id DESC LIMIT 5", (user_id,))
        recent = [row[0].lower() for row in cur.fetchall()]
        if any(k in e for e in recent for k in ["exam", "lab", "study"]): profile.append("User Persona: Student")
        if any(k in e for e in recent for k in ["patient", "clinic"]): profile.append("User Persona: Medical Prof")
    except: pass
    finally: conn.close()
    return "\n".join(profile)

def get_relevant_knowledge(user_id: str, text: str):
    conn = get_db_safe()
    cur = conn.cursor()
    found = []
    keywords = [w for w in re.findall(r'\w+', text.lower()) if len(w) >= 2]
    try:
        for word in keywords:
            p = f'%{word}%'
            cur.execute("SELECT title, summary FROM notes WHERE user_id=? AND (title LIKE ? OR summary LIKE ?)", (user_id, p, p))
            for row in cur.fetchall(): found.append(f"Note: {row[0]} - {row[1]}")
            cur.execute("SELECT title, start_time FROM events WHERE user_id=? AND (title LIKE ? OR start_time LIKE ?)", (user_id, p, p))
            for row in cur.fetchall(): found.append(f"Event: {row[0]} at {row[1]}")
    except: pass
    finally: conn.close()
    return "\n".join(list(set(found))) if found else "No matching records."

def get_schedule_context(user_id: str):
    conn = get_db_safe()
    cur = conn.cursor()
    now = datetime.now()
    future = now + timedelta(hours=24)
    try:
        cur.execute("SELECT title, start_time FROM events WHERE user_id=? AND start_time BETWEEN ? AND ?", 
                    (user_id, now.strftime("%Y-%m-%d %H:%M"), future.strftime("%Y-%m-%d %H:%M")))
        return "\n".join([f"- {r[0]} at {r[1]}" for r in cur.fetchall()])
    except: return "No upcoming events."
    finally: conn.close()

# --- MAIN ASSISTANT LOGIC ---
def generate_conversational_response(user_id, text):
    knowledge = get_relevant_knowledge(user_id, text)
    schedule = get_schedule_context(user_id)
    background = get_user_background_summary(user_id)
    
    now = datetime.now()
    habit_now = habit_engine.get_prediction(now.hour, now.weekday(), now.month)

    prompt = f"""<|system|>
You are MindMate, a Personal AI Assistant. 
Background: {background} | Records: {knowledge} | Schedule: {schedule}
Habit Insight: At this time, the user usually does: {habit_now}.
INSTRUCTIONS: Use records for the past, habits for the routine, and be professional.<|end|>
<|user|>{text}<|end|><|assistant|>"""

    try:
        response = requests.post(OLLAMA_URL, json={"model": MODEL_NAME, "prompt": prompt, "stream": False})
        return response.json().get("response", "I am listening...")
    except: return "Brain offline. Check Ollama."

def analyze_conversation_payload(user_id, text):
    prompt = f"""<|user|>Input: "{text}". Extract JSON (category: note/schedule, note: {{heading, summary, category}}, schedule: {{title, start_time}}). Return JSON ONLY.<|end|><|assistant|>"""
    try:
        response = requests.post(OLLAMA_URL, json={"model": MODEL_NAME, "prompt": prompt, "format": "json", "stream": False})
        return json.loads(response.json().get("response", "{}"))
    except: return {"has_data": False}