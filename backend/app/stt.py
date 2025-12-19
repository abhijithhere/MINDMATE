from faster_whisper import WhisperModel
import os

# Configuration: 'tiny', 'base', 'small', 'medium', 'large'
# 'base.en' is a good tradeoff for speed/accuracy on CPU
MODEL_SIZE = "base.en" 
_model_instance = None

def get_model():
    """Singleton to load the heavy model only once."""
    global _model_instance
    if _model_instance is None:
        print(f"⏳ Loading Whisper Model ({MODEL_SIZE})...")
        try:
            # Run on CPU with INT8 quantization (faster, less RAM)
            _model_instance = WhisperModel(MODEL_SIZE, device="cpu", compute_type="int8")
            print("✅ Whisper Loaded.")
        except Exception as e:
            print(f"❌ Error loading Whisper: {e}")
            return None
    return _model_instance

def transcribe_file(audio_path: str) -> str:
    """Transcribes an audio file to text."""
    if not os.path.exists(audio_path):
        print(f"❌ Audio file not found: {audio_path}")
        return ""

    try:
        model = get_model()
        if not model:
            return ""

        # Transcribe
        segments, info = model.transcribe(
            audio_path,
            beam_size=5,
            language="en",
            vad_filter=True # Filter out silence
        )

        # Combine segments into one string
        full_text = " ".join([segment.text for segment in segments]).strip()
        print(f"📝 Transcription: '{full_text}'")
        return full_text

    except Exception as e:
        print(f"❌ STT Error: {e}")
        return ""