import requests
import json

BASE_URL = "http://localhost:8000"

def test_persona(user_id, question, persona_name):
    print(f"\n--- TESTING: {persona_name} ({user_id}) ---")
    print(f"❓ Q: {question}")
    
    payload = {"user_id": user_id, "text": question, "sender": "user"}
    try:
        response = requests.post(f"{BASE_URL}/chat/send", json=payload)
        ai_reply = response.json().get('ai_response')
        print(f"🤖 AI: {ai_reply}")
    except Exception as e:
        print(f"❌ Error: {e}")

def run_tests():
    # 1. Test Doctor
    # Expecting: Medical terminology, reference to "Atrial Fibrillation"
    test_persona("dr_sarah", "What did I note about the patient in bed 4?", "Dr. Sarah")
    
    # 2. Test Chef
    # Expecting: Culinary terms, reference to "Risotto" and "Lemon Zest"
    test_persona("chef_mario", "What was wrong with the Risotto?", "Chef Mario")
    
    # 3. Test Lawyer
    # Expecting: Legal jargon, reference to "Miranda vs Arizona" or "NDA"
    test_persona("lawyer_alan", "What is the strategy for the Smith case?", "Lawyer Alan")

    # 4. Test Adaptive Explanations (Same question, different users)
    # The AI should explain "Pressure" differently to a Doctor (Blood Pressure) vs a Chef (Pressure Cooker)
    # (Note: This depends on how smart your Llama 3.2 model is with the profile prompt)
    print("\n--- ADAPTIVITY TEST ---")
    test_persona("dr_sarah", "Do I have any important meetings today?", "Dr. Sarah (Schedule)")
    test_persona("chef_mario", "Do I have any important meetings today?", "Chef Mario (Schedule)")

if __name__ == "__main__":
    run_tests()