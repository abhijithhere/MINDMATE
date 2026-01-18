import sys
import os

# Ensure the backend root is in the path to find app.nlp
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

try:
    from app import nlp
    print("✅ System Ready: Testing MindMate Retrieval Layers...\n")
except ImportError as e:
    print(f"❌ Setup Error: {e}")
    sys.exit(1)

def run_persona_tests():
    test_cases = [
        # {
        #     "user": "dr_sarah",
        #     "name": "Dr. Sarah",
        #     "query": "What did I note about the patient in bed 4?"
        # },
        # {
        #     "user": "chef_mario",
        #     "name": "Chef Mario",
        #     "query": "what is wrong with risotto"
        # },
        #         {
        #     "user": "admin",
        #     "name": "admin",
        #     "query": "which day that i have a meeting at 6 pm"
        # },
        {
            "user": "admin",
            "name": "admin",
            "query": "give me a plan for tommarow"
        },
        # {
        #     "user": "lawyer_alan",
        #     "name": "Lawyer Alan",
        #     "query": "What is the strategy for the Smith case?"
        # }
    ]

    for case in test_cases:
        print(f"--- 👤 TESTING: {case['name']} ({case['user']}) ---")
        print(f"❓ Q: {case['query']}")
        
        # This calls the RAG logic inside nlp.py
        response = nlp.generate_conversational_response(case['user'], case['query'])
        
        print(f"💬 MindMate: {response}\n")

if __name__ == "__main__":
    run_persona_tests()