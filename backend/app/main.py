from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import shutil
import os
import uvicorn
import uuid
from app.nlp import extract_metadata
from app.stt import transcribe_file

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
def read_root():
    return {"status": "online"}

@app.post("/process-audio")
async def process_audio_endpoint(file: UploadFile = File(...)):
    print(f"\n📥 Received Audio: {file.filename}")
    
    unique_id = uuid.uuid4()
    temp_filename = f"temp_{unique_id}.wav"
    
    try:
        with open(temp_filename, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
        
        # DEBUG: Check file size
        file_size = os.path.getsize(temp_filename)
        print(f"   📊 File Size: {file_size} bytes")
        
        if file_size < 1000:
            print("   ⚠️ WARNING: Audio file is too small/empty!")
            return {"original_text": "Error: Audio file empty", "analysis": {}}

        # Transcribe
        print("   ... Transcribing ...")
        transcribed_text = transcribe_file(temp_filename)
        print(f"📝 Text: '{transcribed_text}'")
        
        # Analyze
        if transcribed_text and "Error" not in transcribed_text:
            analysis = extract_metadata(transcribed_text)
        else:
            analysis = {"heading": "No Speech Detected", "details": "Try speaking closer to the mic."}
        
        return {
            "original_text": transcribed_text,
            "analysis": analysis
        }

    except Exception as e:
        print(f"❌ Server Error: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if os.path.exists(temp_filename):
            os.remove(temp_filename)

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)