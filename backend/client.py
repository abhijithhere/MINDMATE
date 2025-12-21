import speech_recognition as sr
import requests
import pyttsx3
import os
import time

# --- CONFIGURATION ---
BASE_URL = "http://127.0.0.1:8000"
USER_ID = "test_user"

# Initialize Text-to-Speech Engine
engine = pyttsx3.init()
engine.setProperty('rate', 170) # Speed of speech

def speak(text):
    """Makes the computer speak the text."""
    print(f"🤖 AI: {text}")
    engine.say(text)
    engine.runAndWait()

def listen():
    """Records audio from the microphone."""
    r = sr.Recognizer()
    with sr.Microphone() as source:
        print("\n" + "="*30)
        print("🎤 Listening... (Speak now!)")
        print("="*30)
        # Adjust for ambient noise
        r.adjust_for_ambient_noise(source, duration=0.5)
        try:
            audio = r.listen(source, timeout=5, phrase_time_limit=10)
            return audio
        except sr.WaitTimeoutError:
            print("❌ No speech detected.")
            return None

def main_loop():
    print(f"🚀 MindMate Voice Client Connected to {BASE_URL}")
    speak("System online. I am listening.")

    while True:
        try:
            input("👉 Press Enter to speak (or Ctrl+C to quit)...")
            
            # 1. RECORD AUDIO
            audio = listen()
            if not audio: continue

            # Save temporary file
            with open("temp_command.wav", "wb") as f:
                f.write(audio.get_wav_data())

            # 2. UPLOAD TO BACKEND (STT)
            print("⏳ Processing...")
            files = {"file": ("temp_command.wav", open("temp_command.wav", "rb"), "audio/wav")}
            data = {"user_id": USER_ID}
            
            # Send audio to get transcript
            res = requests.post(f"{BASE_URL}/upload-audio", files=files, data=data)
            
            if res.status_code == 200:
                transcript = res.json().get("transcript")
                print(f"🗣️ You said: '{transcript}'")

                if not transcript:
                    speak("I didn't catch that.")
                    continue

                # 3. GET INTELLIGENT RESPONSE (NLP + DB)
                # We send the transcript to the chat endpoint to get a conversational answer
                chat_payload = {"user_id": USER_ID, "text": transcript, "sender": "user"}
                chat_res = requests.post(f"{BASE_URL}/chat/send", json=chat_payload)
                
                if chat_res.status_code == 200:
                    ai_reply = chat_res.json().get("ai_response")
                    speak(ai_reply)
                else:
                    speak("I'm having trouble thinking right now.")
            else:
                print(f"❌ Server Error: {res.text}")

        except KeyboardInterrupt:
            print("\n👋 Exiting...")
            break
        except Exception as e:
            print(f"❌ Error: {e}")

if __name__ == "__main__":
    main_loop()