import os
import sys
import json

# 1. Path Setup
ROOT_DIR = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, ROOT_DIR)

try:
    from app import stt,nlp
    # We will use nlp.analyze_conversation_payload for better detection than Regex
    print("\n✅ MindMate Intelligence Online.")
except ImportError as e:
    print(f"❌ Setup Error: {e}")
    sys.exit(1)

def manual_terminal_session():
    user_id = "admin"

    print("\n--- 🧠 MindMate Manual Command Lab ---")
    
    while True:
        user_input = input("\n👤 User: ").strip()
        if user_input.lower() == 'exit': break
        
        # --- PHASE 1: TRANSCRIPTION ---
        text = user_input
        if user_input.lower() == 'audio':
            text = stt.transcribe_audio("voice.wav")
            print(f"📝 Heard: '{text}'")

        # --- PHASE 2: EXTRACTION (The Missing Link) ---
        # This uses the LLM to find the "Hidden" data
        print("🔍 Extracting Intent...")
        extracted_data = nlp.analyze_conversation_payload(user_id, text)
        
        if extracted_data.get("has_data"):
            category = extracted_data.get("category")
            print(f"✨ ACTION DETECTED: {category.upper()}")
            
            # --- PHASE 3: DATABASE SAVING ---
            # This is where we actually save to the DB
            if category == "schedule":
                event = extracted_data.get("schedule")
                print(f"💾 Saving to Database: {event['title']} at {event['start_time']}")
                # Here you would call your db save function, e.g.:
                # db.add_event(user_id, event['title'], event['start_time'])
        else:
            print("💬 Intent: Casual Conversation")

        # --- PHASE 4: RESPONSE ---
        print("🧠 Thinking...")
        response = nlp.generate_conversational_response(user_id, text)
        print(f"💬 MindMate: {response}")

if __name__ == "__main__":
    manual_terminal_session()