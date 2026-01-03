import requests

BASE_URL = "http://localhost:8000"
USER_ID = "dr_sarah" # Testing with our Doctor persona

def test_voice_flow():
    # 1. ENROLL (Set up the password)
    print("🎤 Enrolling Voice...")
    with open("my_voice_enroll.wav", "rb") as f:
        files = {"file": f}
        data = {"user_id": USER_ID}
        res = requests.post(f"{BASE_URL}/auth/enroll-voice", files=files, data=data)
        print(res.json())

    # 2. LOGIN (Try to access)
    print("\n🔐 Attempting Voice Login...")
    with open("my_voice_login.wav", "rb") as f:
        files = {"file": f}
        data = {"user_id": USER_ID}
        res = requests.post(f"{BASE_URL}/auth/login-voice", files=files, data=data)
        
        if res.status_code == 200:
            print("✅ LOGIN SUCCESS!")
            print(res.json())
        else:
            print("❌ LOGIN FAILED!")
            print(res.json())

if __name__ == "__main__":
    # Ensure you have recorded the wav files first!
    try:
        test_voice_flow()
    except FileNotFoundError:
        print("⚠️ Please record 'my_voice_enroll.wav' and 'my_voice_login.wav' first!")