# enroll.py
import sounddevice as sd
from scipy.io.wavfile import write
import os

# Configuration for SpeechBrain
SAMPLE_RATE = 16000  # 16kHz
DURATION = 8         # 8 seconds is perfect for a deep voice print
FILENAME = "voice_signatures/admin.wav"

def main():
    print("\n" + "="*50)
    print("🎙️ MINDMATE MASTER VOICE ENROLLMENT")
    print("="*50)
    print("\nGet ready! Recording will start in 3 seconds...")
    sd.sleep(3000)
    
    print("\n🔴 RECORDING NOW! Read the following sentence naturally:")
    print("---------------------------------------------------------")
    print(' "Hi, I am the admin of MindMate. I am recording my master')
    print('  voice signature so the AI can securely recognize me."')
    print("---------------------------------------------------------\n")
    
    # Record audio (Mono channel)
    audio_data = sd.rec(int(DURATION * SAMPLE_RATE), samplerate=SAMPLE_RATE, channels=1, dtype='int16')
    sd.wait()  # Wait for the recording to finish
    
    # Ensure directory exists
    os.makedirs(os.path.dirname(FILENAME), exist_ok=True)
    
    # Save the file
    write(FILENAME, SAMPLE_RATE, audio_data)
    
    print(f"✅ Success! Your voice signature is saved at:\n   {os.path.abspath(FILENAME)}")
    print("\nYou can now restart your FastAPI server and test the Flutter app!")

if __name__ == "__main__":
    main()