import json
import requests
import sqlite3
import re
from datetime import datetime, timedelta
from services.db import get_db
from services.gmail import fetch_recent_emails # 👈 IMPORT GMAIL

# --- CONFIG ---
OLLAMA_URL = "http://localhost:11434/api/generate"
MODEL_NAME = "llama3.2"

def get_db_safe():
    return get_db()

# --- 1. USER IDENTITY ---
def get_user_background_summary(user_id: str):
    conn = get_db_safe()
    cur = conn.cursor()
    profile_points = []
    try:
        cur.execute("SELECT title FROM events WHERE user_id = ? ORDER BY id DESC LIMIT 5", (user_id,))
        recent_events = [row[0].lower() for row in cur.fetchall()]
        if any("exam" in e or "lab" in e for e in recent_events):
            profile_points.append("- User is likely a Student.")
    except: pass
    finally: conn.close()
    return "\n".join(profile_points)

# --- 2. SEARCH ENGINE ---
def get_relevant_knowledge(user_id: str, text: str):
    conn = get_db_safe()
    cur = conn.cursor()
    found_info = []
    try:
        words = re.findall(r'\w+', text.lower())
        keywords = [w for w in words if len(w) > 3]
        for word in keywords:
            try:
                cur.execute("SELECT content FROM memories WHERE user_id = ? AND content LIKE ? LIMIT 1", (user_id, f'%{word}%'))
                for row in cur.fetchall(): found_info.append(f"- Memory: '{row[0]}'")
            except: pass
    except: pass
    finally: conn.close()
    return "\n".join(list(set(found_info)))

# --- 3. CALENDAR ---
def get_schedule_context(user_id: str):
    context_lines = []
    conn = get_db_safe()
    cur = conn.cursor()
    now = datetime.now().strftime("%Y-%m-%d %H:%M")
    future = (datetime.now() + timedelta(hours=24)).strftime("%Y-%m-%d %H:%M")
    try:
        cur.execute("SELECT title, start_time FROM events WHERE user_id = ? AND start_time BETWEEN ? AND ?", (user_id, now, future))
        events = cur.fetchall()
        if events:
            context_lines.append("📅 SCHEDULE (Next 24h):")
            for e in events: context_lines.append(f"- {e[0]} at {e[1]}")
        else:
            context_lines.append("📅 SCHEDULE: No events in the next 24 hours.")
    except: pass
    finally: conn.close()
    return "\n".join(context_lines)

# --- 4. THE BRAIN (Now with Gmail!) ---
def generate_conversational_response(user_id: str, user_text: str):
    # Gather Context
    user_profile = get_user_background_summary(user_id)
    specific_knowledge = get_relevant_knowledge(user_id, user_text)
    schedule_data = get_schedule_context(user_id)
    current_time = datetime.now().strftime("%A, %Y-%m-%d %H:%M")

    # 📧 CHECK GMAIL (The New Logic)
    email_context = ""
    # If the user mentions "email", "mail", "inbox", fetch data!
    if any(w in user_text.lower() for w in ["email", "mail", "inbox", "message"]):
        print("📧 DETECTED EMAIL REQUEST: Fetching from Gmail...")
        email_data = fetch_recent_emails(limit=5)
        email_context = f"\n📧 RECENT EMAILS:\n{email_data}\n"

    system_prompt = f"""
    You are MindMate, a smart personal assistant.
    Current Time: {current_time}
    
    👤 USER PROFILE:
    {user_profile}
    
    📅 CALENDAR:
    {schedule_data}

    {email_context}  <-- EMAILS ARE HERE
    
    🗄️ NOTES:
    {specific_knowledge}
    
    ❓ USER SAYS:
    "{user_text}"
    
    INSTRUCTIONS:
    1. Answer the user's question.
    2. If 'RECENT EMAILS' are provided above, summarize them for the user.
    3. Be concise and helpful.
    """

    try:
        response = requests.post(OLLAMA_URL, json={
            "model": MODEL_NAME, "prompt": system_prompt, "stream": False
        })
        if response.status_code == 200:
            return response.json().get("response", "I'm thinking...")
        return "Error: Brain Offline"
    except Exception as e:
        return f"Connection Error: {e}"

# --- 5. HELPERS ---
def extract_metadata(text: str):
    # (Keep your existing extract_metadata code here - it is used for commands)
    current_time = datetime.now().strftime("%Y-%m-%d %H:%M")
    prompt = f"""
    Current Date: {current_time}
    Input: "{text}"
    Extract JSON: {{ "event": {{ "title": "...", "start_time": "YYYY-MM-DD HH:MM:SS", "category": "work/personal" }}, "location": "...", "reminder": {{ "is_reminder": true }} }}
    Return ONLY JSON.
    """
    try:
        response = requests.post(OLLAMA_URL, json={
            "model": MODEL_NAME, "prompt": prompt, "stream": False, "format": "json"
        })
        if response.status_code == 200:
            return json.loads(response.json().get("response", "{}"))
    except: return {}
    return {}

def detect_retrieval_intent(text: str):
    # (Keep your existing detect_retrieval_intent code here)
    today = datetime.now().strftime("%Y-%m-%d")
    tomorrow = (datetime.now() + timedelta(days=1)).strftime("%Y-%m-%d")
    prompt = f"""
    Today: {today}, Tomorrow: {tomorrow}
    User: "{text}"
    Task: Is this asking about a specific date?
    Return JSON: {{ "intent": "get_schedule", "date_str": "...", "display_date": "..." }} OR {{ "intent": "none" }}
    """
    try:
        response = requests.post(OLLAMA_URL, json={
            "model": MODEL_NAME, "prompt": prompt, "stream": False, "format": "json"
        })
        return json.loads(response.json().get("response", "{}"))
    except: return {"intent": "none"}