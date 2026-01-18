import sys
import os
import shutil
from fastapi import APIRouter, UploadFile, File, Form, HTTPException, Body
from app import stt, nlp
from services.db_helper import log_chat, save_extracted_data

router = APIRouter()
UPLOAD_DIR = "uploads" # Simplified for reliability
os.makedirs(UPLOAD_DIR, exist_ok=True)

@router.post("/send")
async def send_chat(user_id: str = Body(...), text: str = Body(...)):
    try:
        log_chat(user_id, "user", text)
        extracted = nlp.analyze_conversation_payload(user_id, text)
        if extracted.get("has_data"):
            save_extracted_data(user_id, extracted)
        ai_response = nlp.generate_conversational_response(user_id, text)
        log_chat(user_id, "ai", ai_response)
        return {"status": "success", "ai_response": ai_response}
    except Exception as e: raise HTTPException(status_code=500, detail=str(e))

@router.post("/upload-audio")
async def upload_audio(user_id: str = Form(...), file: UploadFile = File(...)):
    try:
        file_path = os.path.join(UPLOAD_DIR, f"{user_id}_voice.wav")
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
        transcript = stt.transcribe_audio(file_path) #
        if not transcript: return {"status": "error", "message": "Silence detected."}
        ai_response = nlp.generate_conversational_response(user_id, transcript)
        return {"status": "success", "transcript": transcript, "ai_response": ai_response}
    except Exception as e: raise HTTPException(status_code=500, detail=str(e))