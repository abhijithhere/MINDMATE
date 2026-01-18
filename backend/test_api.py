# backend/test_api.py
import requests
import uuid

BASE_URL = "http://localhost:8000"
TEST_USER = "test_admin"
TEST_PASS = "admin123"

def run_tests():
    print("🚀 STARTING API SYSTEM CHECK...\n")
    
    # 1. TEST AUTH (Signup/Login)
    print("🔹 Testing Auth...")
    try:
        # Try login (might fail if user doesn't exist, which is fine)
        login_resp = requests.post(f"{BASE_URL}/auth/login", json={"user_id": TEST_USER, "password": TEST_PASS})
        
        if login_resp.status_code == 401:
            # Create user if missing
            print("   User not found, creating...")
            requests.post(f"{BASE_URL}/auth/signup", json={"user_id": TEST_USER, "password": TEST_PASS})
            login_resp = requests.post(f"{BASE_URL}/auth/login", json={"user_id": TEST_USER, "password": TEST_PASS})
        
        if login_resp.status_code == 200:
            print("   ✅ Auth Module: ONLINE")
        else:
            print(f"   ❌ Auth Module: FAILED ({login_resp.status_code})")
            return
    except Exception as e:
        print(f"   ❌ Connection Failed. Is the server running? ({e})")
        return

    # 2. TEST DASHBOARD
    print("\n🔹 Testing Dashboard...")
    dash_resp = requests.get(f"{BASE_URL}/dashboard?user_id={TEST_USER}")
    if dash_resp.status_code == 200:
        data = dash_resp.json()
        print(f"   ✅ Dashboard Module: ONLINE (Events Today: {data.get('event_count')})")
    else:
        print(f"   ❌ Dashboard Module: FAILED ({dash_resp.status_code})")

    # 3. TEST CHAT (Text)
    print("\n🔹 Testing Chat Router...")
    chat_resp = requests.post(f"{BASE_URL}/chat/send", json={
        "user_id": TEST_USER, 
        "text": "Check my schedule for today."
    })
    if chat_resp.status_code == 200:
        print(f"   ✅ Chat Module: ONLINE")
        print(f"   🤖 AI Reply: {chat_resp.json().get('ai_response')}")
    else:
        print(f"   ❌ Chat Module: FAILED ({chat_resp.status_code})")

    print("\n🎉 SYSTEM CHECK COMPLETE.")

if __name__ == "__main__":
    run_tests()