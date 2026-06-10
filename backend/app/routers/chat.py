# app/routers/chat.py
 
import os, time, traceback, asyncio
from fastapi import APIRouter, File, UploadFile, Form, Request
from fastapi.responses import JSONResponse
from psycopg2.extras import RealDictCursor
 
from services.db import get_db
from services.db_helper import log_chat
from app.stt import transcribe_audio
from app.nlp import classify_and_route, detect_wake_word
from services.gmail import handle_voice_email_command
 
router = APIRouter()
 
# ─────────────────────────────────────────────────────────────
# TRANSCRIPT BUFFER
# Structure: { user_id: { text: str, last_heard_at: float } }
# ─────────────────────────────────────────────────────────────
TRANSCRIPT_BUFFER: dict[str, dict] = {}
 
# 🟢 FIX: Increased to 8.0 seconds to comfortably clear the new 6-second audio chunks
SILENCE_THRESHOLD = 8.0
 
 
# ── Buffer helpers ────────────────────────────────────────────
 
def _ensure_buf(uid: str) -> None:
    if uid not in TRANSCRIPT_BUFFER:
        TRANSCRIPT_BUFFER[uid] = {"text": "", "last_heard_at": 0.0}
 
 
def _append(uid: str, chunk: str) -> None:
    """Add a new STT chunk and update the last-heard timestamp."""
    _ensure_buf(uid)
    TRANSCRIPT_BUFFER[uid]["text"] += f" {chunk}"
    TRANSCRIPT_BUFFER[uid]["last_heard_at"] = time.time()
 
 
def _silence_ready(uid: str) -> bool:
    """
    True when:
      • there IS accumulated text, AND
      • no new audio has arrived for at least SILENCE_THRESHOLD seconds.
    """
    entry = TRANSCRIPT_BUFFER.get(uid)
    if not entry or not entry["text"].strip():
        return False
    return (time.time() - entry["last_heard_at"]) >= SILENCE_THRESHOLD
 
 
def _flush(uid: str) -> str:
    """Return the buffered text and reset the buffer."""
    _ensure_buf(uid)
    text = TRANSCRIPT_BUFFER[uid]["text"].strip()
    TRANSCRIPT_BUFFER[uid] = {"text": "", "last_heard_at": time.time()}
    return text
 
 
# ── Response / logging helpers ────────────────────────────────
 
def _ok(transcript="", ai_response="", action="", table="", summary="") -> dict:
    return {
        "transcript":   transcript,
        "ai_response":  ai_response,
        "action":       action,
        "table":        table,
        "summary":      summary,
    }
 
 
def _safe_log(uid: str, sender: str, text: str) -> None:
    try:
        log_chat(uid, sender, text, flag=1)
    except Exception as e:
        print(f"⚠️  log_chat: {e}")
 
 
# ── Core NLP pipeline (runs in a thread) ─────────────────────
 
def _process(uid: str, text: str) -> dict:
    """
    Called once per complete utterance (after silence is detected).
    Runs classify_and_route (or the email shortcut) and logs both sides.
    """
    tl = text.lower()
 
    # Email shortcut
    if "send" in tl and ("email" in tl or "mail" in tl):
        reply = handle_voice_email_command(uid, text)
        _safe_log(uid, "user", text)
        _safe_log(uid, "ai",   reply)
        return _ok(text, reply, action="email_sent")
 
    result   = classify_and_route(user_id=uid, text=text, source="Voice")
    ai_reply = result.get("ai_reply", "")
 
    _safe_log(uid, "user", text)
    if ai_reply:
        _safe_log(uid, "ai", ai_reply)
 
    return _ok(
        transcript  = text,
        ai_response = ai_reply,
        action      = result.get("status",  "monitoring"),
        table       = result.get("table",   ""),
        summary     = result.get("summary", ""),
    )
 
 
# ── Audio upload endpoint ─────────────────────────────────────
 
@router.post("/upload-audio")
async def handle_audio_upload(
    user_id: str        = Form(...),
    file:    UploadFile = File(...),
):
    if not user_id or not user_id.strip():
        user_id = "guest"
 
    temp_dir  = os.path.join(os.getcwd(), "app", "routers", "uploads")
    os.makedirs(temp_dir, exist_ok=True)
    safe_id   = user_id.replace("@", "_").replace(".", "_").replace(" ", "_")
    temp_path = os.path.join(temp_dir, f"{safe_id}_temp.wav")
 
    try:
        content = await file.read()
 
        # ── Empty upload ──────────────────────────────────────
        if not content:
            if _silence_ready(user_id):
                text = _flush(user_id)
                if text:
                    print(f"🔇 Silence detected (empty chunk) → NLP: '{text}'")
                    return await asyncio.to_thread(_process, user_id, text)
            return _ok(action="silence")
 
        with open(temp_path, "wb") as f:
            f.write(content)
 
        # ── STT (non-blocking) ────────────────────────────────
        chunk_text = await asyncio.to_thread(transcribe_audio, temp_path)
 
        # ── No speech in this chunk ───────────────────────────
        if not chunk_text:
            if _silence_ready(user_id):
                text = _flush(user_id)
                if text:
                    print(f"🔇 Silence detected (no speech) → NLP: '{text}'")
                    return await asyncio.to_thread(_process, user_id, text)
            return _ok(action="silence")
 
        # ── Speech detected → accumulate ──────────────────────
        _append(user_id, chunk_text)
        buffered = TRANSCRIPT_BUFFER[user_id]["text"].strip()
        print(f"📝 Buffer [{user_id}]: '{buffered}'")
 
        # Only trigger NLP on a clear wake-word command
        if detect_wake_word(chunk_text):
            text = _flush(user_id)
            print(f"🔔 Wake-word flush → NLP: '{text}'")
            return await asyncio.to_thread(_process, user_id, text)
 
        # Still accumulating — return the live partial transcript
        return _ok(transcript=buffered, action="buffering")
 
    except Exception as e:
        print(f"❌ Router: {e}")
        traceback.print_exc()
        return {**_ok(action="error"), "error": str(e)}
 
    finally:
        if os.path.exists(temp_path):
            try:
                os.remove(temp_path)
            except Exception:
                pass
 
 
# ── Text chat endpoint ────────────────────────────────────────
 
@router.post("/send")
async def send_text_chat(request: Request):
    user_id = text = ""
    ct = request.headers.get("content-type", "")
    try:
        if "application/json" in ct:
            b       = await request.json()
            user_id = b.get("user_id", "")
            text    = b.get("text", "")
        else:
            f       = await request.form()
            user_id = str(f.get("user_id", ""))
            text    = str(f.get("text", ""))
    except Exception as e:
        return JSONResponse(422, {"detail": str(e)})
 
    if not text:
        return JSONResponse(422, {"detail": "text required"})
    if not user_id:
        user_id = "guest"
 
    tl = text.lower()
    if "send" in tl and ("email" in tl or "mail" in tl):
        reply = handle_voice_email_command(user_id, text)
        _safe_log(user_id, "user", text)
        _safe_log(user_id, "ai",   reply)
        return _ok(text, reply, action="email_sent")
 
    result   = await asyncio.to_thread(
        classify_and_route, user_id=user_id, text=text, source="Text"
    )
    ai_reply = result.get("ai_reply", "")
 
    _safe_log(user_id, "user", text)
    if ai_reply:
        _safe_log(user_id, "ai", ai_reply)
 
    return _ok(
        text, ai_reply,
        action  = result.get("status",  "success"),
        table   = result.get("table",   ""),
        summary = result.get("summary", ""),
    )
 
 
# ── Chat history endpoint ─────────────────────────────────────
 
@router.get("/history")
async def get_chat_history(user_id: str, limit: int = 100):
    conn = get_db()
    cur  = conn.cursor(cursor_factory=RealDictCursor)
    try:
        cur.execute("""
            SELECT sender, text AS content, created_at AS time, is_owner_voice
            FROM chat_messages WHERE user_id=%s
            ORDER BY created_at DESC LIMIT %s
        """, (user_id, limit))
        return {"history": [dict(r) for r in cur.fetchall()]}
    except Exception as e:
        print(f"❌ History: {e}")
        return {"history": []}
    finally:
        cur.close()
        conn.close()