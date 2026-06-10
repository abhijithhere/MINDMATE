"""
STT for MindMate.

KEY FIXES:
  1. initial_prompt removed to prevent prompt hallucinations.
  2. vad_filter=False to prevent 3-sec clips from being skipped.
  3. Uses 'no_speech_prob' to mathematically detect pure silence.
  4. Strips any leftover hallucinated filler phrases.
"""

import os
import subprocess
import numpy as np
from faster_whisper import WhisperModel

MODEL_SIZE   = "small.en"
DEVICE       = "cpu"
COMPUTE_TYPE = "int8"

print(f"⏳ Loading Whisper ({MODEL_SIZE})...")
model = WhisperModel(MODEL_SIZE, device=DEVICE, compute_type=COMPUTE_TYPE)
print("✅ Whisper ready.")

# Fallback filter just in case the acoustic check misses something
_HALLUCINATIONS = [
    "user is speaking to mindmate", "wake words", "topics:",
    "meetings, reminders", "thank you for watching", "thanks for watching",
    "please subscribe", "you", "[music]", "[applause]", "(music)",
    "thank you", "thank you.", "thanks.", "thanks", "subs by", "amara.org",
]

def _is_hallucination(text: str) -> bool:
    t = text.lower().strip()
    if len(t) < 3: return True
    for phrase in _HALLUCINATIONS:
        if phrase in t: return True
    return False

def transcribe_audio(file_path: str) -> str:
    """
    Transcribe a .wav file.
    Returns "" if silence, error, or hallucinated prompt text detected.
    """
    if not os.path.exists(file_path):
        print(f"⚠️  STT: file not found: {file_path}")
        return ""

    clean_path = file_path.replace(".wav", "_clean.wav")
    try:
        # Standardize audio for Whisper
        subprocess.run(
            ["ffmpeg", "-y", "-i", file_path,
             "-ar", "16000", "-ac", "1", "-sample_fmt", "s16", clean_path],
            check=True, capture_output=True,
        )

        segments, info = model.transcribe(
            clean_path,
            beam_size   = 5,
            language    = "en",
            condition_on_previous_text = False,
            vad_filter  = False,   
        )

        valid_text = []
        for seg in segments:
            # 🟢 STRICT SILENCE DETECTION: 
            # If the model is > 60% sure this is background noise/silence, ignore it.
            if seg.no_speech_prob < 0.60:
                valid_text.append(seg.text)

        text = " ".join(valid_text).strip()

        if not text:
            print(f"👂 STT: acoustic silence detected (dur={getattr(info,'duration','?')}s)")
            return ""

        if _is_hallucination(text):
            print(f"👂 STT: hallucination stripped -> '{text}'")
            return ""

        print(f"👂 STT: '{text}'")
        return text

    except subprocess.CalledProcessError as e:
        print(f"❌ FFmpeg: {e.stderr.decode()}")
        return ""
    except Exception as e:
        print(f"❌ STT: {e}")
        return ""
    finally:
        if os.path.exists(clean_path):
            try: os.remove(clean_path)
            except Exception: pass

def transcribe_audio_chunk(audio_data: np.ndarray) -> str:
    try:
        segments, _ = model.transcribe(
            audio_data,
            beam_size  = 5,
            language   = "en",
            vad_filter = False,
            condition_on_previous_text = False,
        )
        
        valid_text = []
        for seg in segments:
            # 🟢 STRICT SILENCE DETECTION for live chunks
            if seg.no_speech_prob < 0.60:
                valid_text.append(seg.text)
                
        text = " ".join(valid_text).strip()
        
        if text and not _is_hallucination(text):
            print(f"👂 CHUNK: '{text}'")
            return text
            
        return ""
    except Exception as e:
        print(f"❌ Chunk STT: {e}"); return ""