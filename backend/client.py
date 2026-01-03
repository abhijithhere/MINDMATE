import requests
import os

# CONFIG
BASE_URL = "http://localhost:8000"
# ✅ UPDATED: Matching your actual file name
AUDIO_FILE = "my_voice_recording.wav"  
USER_ID = "test_user_123"

def run_test():
    print(f"🚀 Starting Test with file: {AUDIO_FILE}...")

    # --- STEP 1: UPLOAD AUDIO (The "Ears") ---
    print("\n🎧 Step 1: Sending Audio to Whisper...")
    
    # Check if the file actually exists in this folder
    if not os.path.exists(AUDIO_FILE):
        print(f"❌ Error: Could not find '{AUDIO_FILE}' in the current folder.")
        print(f"   Current Folder: {os.getcwd()}")
        print("   -> Please make sure you pasted the wav file here!")
        return

    # Prepare file for upload
    try:
        files = {'file': open(AUDIO_FILE, 'rb')}
        data = {'user_id': USER_ID}
    
        response = requests.post(f"{BASE_URL}/upload-audio", files=files, data=data)
        
        if response.status_code == 200:
            result = response.json()
            transcript = result.get('transcript', '')
            print(f"✅ Transcription Success: '{transcript}'")
        else:
            print(f"❌ Transcription Failed: {response.text}")
            return
            
    except Exception as e:
        print(f"❌ Connection Error: {e}")
        return

    # --- STEP 2: SEND TO AI (The "Brain") ---
    if transcript:
        print(f"\n🧠 Step 2: Sending text to Ollama...")
        
        chat_payload = {
            "user_id": USER_ID,
            "text": transcript,
            "sender": "user"
        }
        
        try:
            response = requests.post(f"{BASE_URL}/chat/send", json=chat_payload)
            
            if response.status_code == 200:
                ai_result = response.json()
                print(f"🤖 AI Response: {ai_result.get('ai_response')}")
                print("✅ Test Complete! The backend is working perfectly.")
            else:
                print(f"❌ AI Logic Failed: {response.text}")
        except Exception as e:
            print(f"❌ Connection Error during Chat: {e}")

if __name__ == "__main__":
    run_test()