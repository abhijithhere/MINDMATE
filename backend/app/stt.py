from faster_whisper import WhisperModel

# Keep 'base.en' for accuracy
MODEL_SIZE = "base.en"

model = None

def load_model():
    global model
    if model is None:
        print(f"Loading Whisper: {MODEL_SIZE} ...")
        model = WhisperModel(MODEL_SIZE, device="cpu", compute_type="int8", cpu_threads=4)
        print("Whisper Loaded.")
    return model

def transcribe_file(file_path: str) -> str:
    loaded_model = load_model()
    try:
        # CHANGED: vad_filter=False (Don't auto-delete silence/noise)
        # This ensures even quiet speech gets transcribed.
        segments, _ = loaded_model.transcribe(
            file_path, 
            beam_size=5, 
            language="en",
            condition_on_previous_text=False,
            vad_filter=False 
        )
        text = " ".join([s.text for s in segments]).strip()
        return text
    except Exception as e:
        return f"Error: {str(e)}"