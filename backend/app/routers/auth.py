from fastapi import APIRouter, HTTPException, UploadFile, File, Form
import shutil
import os
import sqlite3
from pydantic import BaseModel
from services.db import get_db
from services.voice_auth import voice_security

router = APIRouter(prefix="/auth", tags=["Authentication"])

class UserAuth(BaseModel):
    user_id: str
    password: str

class WakeWordUpdate(BaseModel):
    user_id: str
    wake_word: str

def verify_password(plain, stored):
    return plain == stored

@router.post("/signup")
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

@router.post("/login")
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

@router.post("/set-wake-word")
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

# --- VOICE AUTH ---
@router.post("/enroll-voice")
async def enroll_voice(file: UploadFile = File(...), user_id: str = Form(...)):
    temp_filename = f"temp_enroll_{user_id}.wav"
    try:
        with open(temp_filename, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
        voice_security.enroll_user(user_id, temp_filename)
        return {"status": "success", "message": "Voice Signature Saved."}
    finally:
        if os.path.exists(temp_filename): os.remove(temp_filename)

@router.post("/login-voice")
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