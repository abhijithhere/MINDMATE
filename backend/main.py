from fastapi import FastAPI, UploadFile, File, Form, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import shutil
import os
import uvicorn
import sqlite3
import re 
import json
from datetime import datetime
from pydantic import BaseModel
from services.voice_auth import voice_security
from app.stt import transcribe_audio, transcribe_audio_chunk
from services.init_db import init_db
from services.db import get_db
from services.analytics import get_daily_summary
from app.nlp import extract_metadata, detect_retrieval_intent, generate_conversational_response
from services.events import save_voice_entry, get_schedule_for_date
from app.advanced_nlp import IntentAnalyzer
from services.gmail import fetch_recent_emails, send_email
from fastapi import WebSocket, WebSocketDisconnect
import numpy as np
import io
import scipy.io.wavfile as wav


app = FastAPI(title="MindMate API")

# --- CORS ---
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

intent_analyzer = IntentAnalyzer()

# --- MODELS ---
class UserAuth(BaseModel):
    user_id: str
    password: str

class ChatMessage(BaseModel):
    user_id: str
    text: str
    sender: str = "user" 

class WakeWordUpdate(BaseModel):
    user_id: str
    wake_word: str

# --- HELPERS ---
def verify_password(plain_password, stored_password):
    return plain_password == stored_password

def extract_email_address(text):
    match = re.search(r'[\w\.-]+@[\w\.-]+', text)
    return match.group(0) if match else None

# --- STARTUP ---
@app.on_event("startup")
def on_startup():
    init_db()

@app.websocket("/ws/listen/{user_id}")
async def listen_socket(websocket: WebSocket, user_id: str):
    """
    Real-time Audio Stream Handler
    1. Receives raw audio bytes from client.
    2. Converts to Numpy for Whisper.
    3. Transcribes instantly.
    4. If text is found, sends to NLP for analysis.
    """
    await websocket.accept()
    print(f"🟢 User {user_id} Connected to Voice Stream")
    
    try:
        while True:
            # 1. Receive Audio Chunk
            data = await websocket.receive_bytes()
            
            # --- DEBUG LOG ---
            print(f"📥 RECEIVED PACKET: {len(data)} bytes") 
            # -----------------
            
            # 2. Convert to Numpy
            audio_chunk = np.frombuffer(data, dtype=np.float32)

            # 3. Transcribe Instantly
            transcript = transcribe_audio_chunk(audio_chunk)
            
            if transcript:
                print(f"🗣️ Heard: {transcript}")
                
                # 4. Instant NLP Processing
                # We reuse your existing logic inside chat/send
                # But we call the logic functions directly, not via HTTP
                
                # A. Check if it's a command/note
                # Using your existing extraction logic
                analysis = extract_metadata(transcript)
                
                response_text = ""
                is_saved = False

                # B. Save if important (Passive Recording)
                if analysis.get("event", {}).get("title"):
                    save_voice_entry(user_id, transcript, analysis)
                    is_saved = True
                    response_text = f"✅ Saved: {analysis['event']['title']}"
                
                # C. If user asked a question (Active Bot)
                # You can add wake-word logic here if you want strict "Hey Jarvis"
                # For now, we process everything since it's a direct stream
                if not is_saved:
                     # Only respond if it looks like a question/command
                    intent = intent_analyzer.analyze(transcript)
                    if intent['type'] != 'conversation_or_noise':
                        response_text = generate_conversational_response(user_id, transcript)

                # 5. Send Response back to Client (if any)
                if response_text:
                    await websocket.send_json({
                        "transcript": transcript,
                        "ai_response": response_text,
                        "is_saved": is_saved
                    })
                else:
                    # Just send the transcript for UI update
                    await websocket.send_json({"transcript": transcript})

    except WebSocketDisconnect:
        print(f"🔴 User {user_id} Disconnected")
    except Exception as e:
        print(f"❌ WebSocket Error: {e}")

# --- AUTH ENDPOINTS ---
@app.post("/signup")
async def signup(user: UserAuth):
    conn = get_db()
    cur = conn.cursor()
    try:
        cur.execute("SELECT user_id FROM users WHERE user_id = ?", (user.user_id,))
        if cur.fetchone():
            raise HTTPException(status_code=400, detail="Username taken")
        cur.execute("INSERT INTO users (user_id, password_hash) VALUES (?, ?)", (user.user_id, user.password))
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

@app.post("/user/set-wake-word")
async def set_wake_word(data: WakeWordUpdate):
    conn = get_db()
    cur = conn.cursor()
    try:
        clean_word = data.wake_word.strip().lower()
        cur.execute("UPDATE users SET wake_word = ? WHERE user_id = ?", (clean_word, data.user_id))
        conn.commit()
        return {"status": "success", "message": f"Wake word updated to '{clean_word}'"}
    finally:
        conn.close()

# --- 🧠 THE SMART LOGIC ---
@app.post("/chat/send")
async def send_chat_message(message: ChatMessage):
    conn = get_db()
    conn.row_factory = sqlite3.Row
    cur = conn.cursor()
    
    # 1. GET WAKE WORD
    cur.execute("SELECT wake_word FROM users WHERE user_id = ?", (message.user_id,))
    user_row = cur.fetchone()
    wake_word = user_row['wake_word'].lower() if user_row and user_row['wake_word'] else "mindmate"

    # 2. CHECK "AWAKE" STATUS
    user_text_raw = message.text.strip()
    if not user_text_raw:
        conn.close()
        return {"status": "ignored", "message": "Empty text"}

    user_text_lower = user_text_raw.lower()
    is_awake = user_text_lower.startswith(wake_word)
    
    # Remove wake word for analysis
    processed_text = user_text_raw[len(wake_word):].strip() if is_awake else user_text_raw

    # 3. ANALYZE INTENT
    intent_result = intent_analyzer.analyze(processed_text)
    intent_type = intent_result['type']
    
    ai_text = None
    status = "success"

    print(f"🔍 Analysis: Text='{processed_text}' | Awake={is_awake} | Intent={intent_type}")

    # --- LOGIC BRANCH A: SENSITIVE ACTIONS (REQUIRE WAKE WORD) ---
    is_email_action = "email" in processed_text.lower() or "mail" in processed_text.lower()
    
    if intent_type == 'retrieval' or (intent_type == 'command' and is_email_action):
        if not is_awake:
            print("🔒 Privacy Shield: Blocked sensitive request.")
            conn.close()
            return {"status": "ignored", "ai_response": None, "message": "Wake word required."}
        
        # Execute Sensitive Action (Schedule/Email)
        if intent_type == 'retrieval':
            retrieval_data = detect_retrieval_intent(processed_text)
            if retrieval_data and retrieval_data.get('intent') == 'get_schedule':
                events = get_schedule_for_date(message.user_id, retrieval_data['date_str'])
                ai_text = f"📅 Schedule for {retrieval_data['display_date']}:\n" + "\n".join(events) if events else f"No events for {retrieval_data['display_date']}."
            else:
                ai_text = generate_conversational_response(message.user_id, processed_text)
        elif is_email_action:
             # (Keep your existing email logic here)
             ai_text = generate_conversational_response(message.user_id, processed_text)

    # --- LOGIC BRANCH B: PASSIVE DATA MINING (STRICTER NOW) ---
    else:
        # 🟢 STRICTER FILTER: Only run AI extraction if text looks like an event
        # (Must contain numbers for time, or words like "tomorrow", "meet", "schedule")
        has_time_cue = any(char.isdigit() for char in processed_text) or any(w in processed_text.lower() for w in ["tomorrow", "today", "tonight", "next", "meet", "schedule", "remind"])
        
        is_important = False
        
        if has_time_cue:
            analysis = extract_metadata(processed_text)
            # Only save if we strictly found a Title AND (Time OR Location)
            if analysis.get("event") and analysis["event"].get("title"):
                if analysis["event"].get("start_time") or (analysis.get("location") and analysis["location"] != "null"):
                    is_important = True
        
        if is_important:
            save_voice_entry(message.user_id, processed_text, analysis)
            print(f"💾 Passive Save: Captured important info.")
            
            if is_awake:
                evt_title = analysis.get("event", {}).get("title", "Note")
                ai_text = f"✅ I've saved that: {evt_title}"
            else:
                ai_text = None
                status = "passive_save"
        
        else:
            # --- NOISE HANDLING ---
            if not is_awake:
                print("💤 Ignored: Background noise/conversation.")
                conn.close()
                return {"status": "ignored", "message": "Noise ignored"}
            
            # If awake but not an event -> Just Chat
            ai_text = generate_conversational_response(message.user_id, processed_text)

    # 4. SAVE & RETURN
    cur.execute("INSERT INTO chat_messages (user_id, sender, text) VALUES (?, ?, ?)", (message.user_id, 'user', message.text))
    if ai_text:
        cur.execute("INSERT INTO chat_messages (user_id, sender, text) VALUES (?, ?, ?)", (message.user_id, 'ai', ai_text))
    
    conn.commit()
    conn.close()
    
    return {"status": status, "ai_response": ai_text}


@app.post("/upload-audio")
async def upload_audio(file: UploadFile = File(...), user_id: str = Form(...)):
    # 🟢 FIX: Calculate the path correctly right here
    current_dir = os.path.dirname(os.path.abspath(__file__))
    file_path = os.path.join(current_dir, "voice.wav")
    
    try:
        # Save the file
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
        
        # Verify
        file_size = os.path.getsize(file_path)
        print(f"📥 SAVED: {file_path}")
        print(f"📊 SIZE: {file_size} bytes")

        if file_size < 1000:
            print("⚠️ WARNING: Audio file is empty/silent.")
            return {"status": "success", "transcript": ""}

        # Transcribe
        text = transcribe_audio(file_path)
        print(f"📝 TRANSCRIPT: '{text}'")

        return {"status": "success", "transcript": text or ""}

    except Exception as e:
        print(f"❌ Error: {e}")
        return {"status": "error", "message": str(e)}

@app.get("/dashboard")
async def get_dashboard(user_id: str):
    return get_daily_summary(user_id)

@app.get("/chat/history")
async def get_chat_history(user_id: str):
    conn = get_db()
    conn.row_factory = sqlite3.Row
    cur = conn.cursor()
    cur.execute("SELECT sender, text, timestamp FROM chat_messages WHERE user_id = ? ORDER BY timestamp ASC", (user_id,))
    rows = [dict(row) for row in cur.fetchall()]
    conn.close()
    return {"messages": rows}

# Voice Auth Endpoints (Keep existing logic)
@app.post("/auth/enroll-voice")
async def enroll_voice(file: UploadFile = File(...), user_id: str = Form(...)):
    temp_filename = f"temp_enroll_{user_id}.wav"
    try:
        with open(temp_filename, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
        voice_security.enroll_user(user_id, temp_filename)
        return {"status": "success", "message": "Voice Signature Saved."}
    finally:
        if os.path.exists(temp_filename): os.remove(temp_filename)

@app.post("/auth/login-voice")
async def login_with_voice(file: UploadFile = File(...), user_id: str = Form(...)):
    temp_filename = f"temp_login_{user_id}.wav"
    try:
        with open(temp_filename, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
        is_match, score = voice_security.verify_user(user_id, temp_filename)
        if is_match:
            return {"status": "success", "message": "Voice Verified", "confidence": score, "user_id": user_id}
        else:
            raise HTTPException(status_code=401, detail=f"Voice not recognized. Score: {score:.2f}")
    finally:
        if os.path.exists(temp_filename): os.remove(temp_filename)

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)