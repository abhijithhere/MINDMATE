import os
import sys

# Add backend root to path so 'app' is visible
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app import stt, nlp
from app.advanced_nlp import IntentAnalyzer

def run_test(audio_path="voice.wav"):
    # 1. Perception
    print("🎧 Transcribing...")
    text = stt.transcribe_audio(audio_path)
    print(f"📝 Heard: {text}")

    # 2. Reflex (Regex)
    analyzer = IntentAnalyzer()
    intent = analyzer.analyze(text)
    print(f"🚦 Intent: {intent['type']}")

    # 3. Cognition (Ollama)
    print("🧠 Thinking...")
    response = nlp.generate_conversational_response("admin", text)
    print(f"💬 MindMate: {response}")

if __name__ == "__main__":
    run_test()