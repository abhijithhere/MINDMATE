import sounddevice as sd
from scipy.io.wavfile import write
import time

def record_audio(filename, duration):
    print(f"\n🎙️  Recording '{filename}' for {duration} seconds...")
    print("🔴 SPEAK NOW!")
    
    fs = 44100  # Sample rate
    recording = sd.rec(int(duration * fs), samplerate=fs, channels=1)
    sd.wait()  # Wait until recording is finished
    
    write(filename, fs, recording)  # Save as WAV file
    print(f"✅ Saved: {filename}")

if __name__ == "__main__":
    print("--- VOICE AUTH SETUP ---")
    
    # 1. Record Enrollment (The 'Password')
    input("Press Enter to record your ENROLLMENT (Signature) - 10 Seconds...")
    record_audio("my_voice_enroll.wav", 10)
    
    # 2. Record Login (The 'Key')
    input("\nPress Enter to record your LOGIN attempt - 5 Seconds...")
    record_audio("my_voice_login.wav", 5)
    
    print("\n🎉 Files ready! Now run 'python test_voice_auth.py'")