import requests
import os

# Base URL of your running server
BASE_URL = "http://127.0.0.1:8000"
USER_ID = "test_user"

def print_separator(title):
    print("\n" + "="*40)
    print(f"🔹 {title}")
    print("="*40)

def test_auth():
    print_separator("Testing Authentication")
    payload = {"user_id": USER_ID, "password": "password123"}
    try:
        requests.post(f"{BASE_URL}/signup", json=payload) # Signup
        response = requests.post(f"{BASE_URL}/login", json=payload) # Login
        if response.status_code == 200:
            print("✅ Login Successful")
        else:
            print(f"❌ Login Failed: {response.text}")
    except Exception as e:
        print(f"❌ Connection Error: {e}")

def test_text_chat():
    print_separator("Testing Basic Chat")
    payload = {
        "user_id": USER_ID,
        "text": "Remind me to call Mom at 5 PM",
        "sender": "user"
    }
    response = requests.post(f"{BASE_URL}/chat/send", json=payload)
    if response.status_code == 200:
        print(f"🤖 AI Response: {response.json().get('ai_response')}")
        print("✅ Basic Chat working")
    else:
        print(f"❌ Chat Error: {response.text}")

def test_retrieval():
    print_separator("Testing Schedule Retrieval (Tomorrow)")
    payload = {
        "user_id": USER_ID,
        "text": "What is my schedule tomorrow?",
        "sender": "user"
    }
    response = requests.post(f"{BASE_URL}/chat/send", json=payload)
    
    if response.status_code == 200:
        print(f"🤖 AI Response:\n{response.json()['ai_response']}")
        print("✅ Retrieval Logic working")
    else:
        print(f"❌ Retrieval Error: {response.text}")

if __name__ == "__main__":
    # Ensure 'requests' is installed: pip install requests
    try:
        test_auth()
        # test_text_chat() # You can comment this out if you just want to test retrieval
        test_retrieval()   # <--- THIS RUNS YOUR NEW TEST
    except requests.exceptions.ConnectionError:
        print("\n❌ CRITICAL ERROR: Could not connect to server.")
        print("   Make sure you ran 'uvicorn main:app --reload' in a separate terminal!")