import os
import numpy as np
from faster_whisper import WhisperModel

# --- CONFIG FOR ACCURACY ---
# 1. UPGRADE MODEL: "small.en" is much smarter than "base" but still fast on Ryzen 7.
MODEL_SIZE = "small.en" 
DEVICE = "cpu"
COMPUTE_TYPE = "int8" 

print(f"⏳ Loading Smarter Whisper Model ({MODEL_SIZE})...")
model = WhisperModel(MODEL_SIZE, device=DEVICE, compute_type=COMPUTE_TYPE)
print("✅ Whisper Model Loaded! Ready.")

def transcribe_audio_chunk(audio_data: np.ndarray):
    """
    High-Accuracy Real-time Transcription
    """
    try:
        # 2. DEFINING CONTEXT
        # This tells the AI exactly what words to expect.
        # It fixes name recognition (Abhijith) and domain words (MindMate).
        prompt = "User is Abhijith NB. He is speaking to his assistant MindMate. Topics: Coding, Schedule, Emails, Reminders."

        segments, info = model.transcribe(
            audio_data, 
            beam_size=5,                # 3. BEAM SEARCH: Look for best accuracy (Default was 1)
            language="en",
            condition_on_previous_text=False, # CRITICAL: Prevents getting stuck on old text
            initial_prompt=prompt,      # Apply the context hint
            vad_filter=True,
            vad_parameters=dict(min_silence_duration_ms=400)
        )
        
        text = " ".join([segment.text for segment in segments]).strip()
        
        # Debug Log to see what it heard
        if text:
            print(f"👂 HIGH-ACCURACY HEARD: '{text}'")
            
        return text

    except Exception as e:
        print(f"❌ Transcription Error: {e}")
        return ""

# Keep legacy function for file uploads
def transcribe_audio(file_path: str):
    if not os.path.exists(file_path): return ""
    segments, _ = model.transcribe(file_path, beam_size=5)
    return " ".join([segment.text for segment in segments]).strip()