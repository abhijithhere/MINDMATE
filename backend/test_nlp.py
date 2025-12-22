from app.advanced_nlp import IntentAnalyzer

analyzer = IntentAnalyzer()

print(f"{'INPUT STRING':<50} | {'EXPECTED':<15} | {'RESULT':<15} | {'STATUS'}")
print("-" * 95)

test_cases = [
    # --- LEVEL 1: HYPOTHETICALS (Should Ignore) ---
    ("Suppose I fly to New York tomorrow", "assumption"),
    ("Imagine if I had a meeting", "assumption"),
    ("Let's say I finish strictly by Friday", "assumption"),

    # --- LEVEL 2: RETRIEVAL (Should Search) ---
    ("When did I say the meeting was?", "retrieval"),
    ("Check if I have any plans", "retrieval"),
    ("Do I have a reminder to call Mom?", "retrieval"),
    
    # --- THE TRICKY CASE (Must be Retrieval) ---
    # "Suppose" is present, but "What to do" makes it a question.
    ("Suppose I have a meeting, what to do?", "retrieval"), 

    # --- LEVEL 3: COMMANDS (Should Execute) ---
    ("Remind me to wake up at 7 AM", "command"),
    ("Schedule a flight to California", "command"),
    ("Note that I need milk", "command"),
    ("I have a meeting at 6 PM", "command"), # Matches "have a"

    # --- LEVEL 4: NOISE (Should Log) ---
    ("He told me that he was going to the gym", "conversation_or_noise"),
    ("The weather looks nice today", "conversation_or_noise"),
    ("Hello Jarvis", "conversation_or_noise"),
]

for text, expected in test_cases:
    result = analyzer.analyze(text)
    actual = result['type']
    status = "✅ PASS" if actual == expected else "❌ FAIL"
    print(f"{text:<50} | {expected:<15} | {actual:<15} | {status}")