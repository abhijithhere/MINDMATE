import os
import json
import datetime
import google.generativeai as genai
from dotenv import load_dotenv

# Load API Key from .env file
load_dotenv()
api_key = os.getenv("GEMINI_API_KEY")
if not api_key:
    print("⚠️ WARNING: GEMINI_API_KEY not found in .env")
else:
    genai.configure(api_key=api_key)

def extract_metadata(text: str):
    """Uses Gemini to categorize text into Event, Note, or Reminder."""
    print(f"\n[NLP] Analyzing: '{text}'")
    if not text: return {}

    now = datetime.datetime.now().strftime("%Y-%m-%d %H:%M")
    
    prompt = f"""
    Current Time: {now}
    User Input: "{text}"
    
    Analyze the input and return a JSON object with these keys (use null if not applicable):
    
    1. "event": For specific actions with a time.
       Fields: title, category (Work/Personal/Health), start_time (YYYY-MM-DD HH:MM), location_name
    
    2. "reminder": For tasks needing a notification.
       Fields: priority (High/Med/Low), recurrence (DAILY/WEEKLY/null)
    
    3. "memory": For facts, preferences, or ideas.
       Fields: type (preference/fact/goal), content (summarized), confidence (0.0-1.0)
    
    4. "voice_meta": Sentiment analysis.
       Fields: emotion_label (neutral/happy/stressed), stress_level (0.0-1.0)

    Return ONLY Raw JSON. No markdown formatting.
    """

    try:
        model = genai.GenerativeModel('gemini-1.5-flash')
        response = model.generate_content(prompt)
        
        # Clean the response text to ensure valid JSON
        raw_text = response.text.replace("```json", "").replace("```", "").strip()
        return json.loads(raw_text)

    except Exception as e:
        print(f"❌ NLP Error: {e}")
        return {}