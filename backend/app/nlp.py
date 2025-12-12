import os
import json
import datetime
import google.generativeai as genai

# --- CONFIGURATION ---
# 1. PASTE YOUR GOOGLE GEMINI API KEY INSIDE THE QUOTES BELOW
MY_API_KEY = "AIzaSyCEdicAcQrBYgFDnXaQOkcnbYf27pdLhy0" 

# Logic: Tries to get from Environment, otherwise uses the hardcoded key
api_key = os.getenv("GEMINI_API_KEY")
if not api_key or api_key == "None":
    api_key = MY_API_KEY

# Configure Gemini
if api_key and "PASTE_YOUR" not in api_key:
    genai.configure(api_key=api_key)
else:
    print("❌ ERROR: API Key is missing in nlp.py")

def extract_metadata(text):
    """
    Uses Gemini to extract structured notes.
    Includes fallback to 'gemini-pro' if 'flash' model is unavailable.
    """
    # DEBUG PRINT: Check if function is receiving text
    print(f"\n[NLP DEBUG] Analyzing Text: '{text}'")

    if not text:
        return {"heading": "No Audio", "type": "ERROR", "details": "No text provided to analyze"}
        
    if not api_key or "PASTE_YOUR" in api_key:
        print("[NLP DEBUG] Failed: API Key missing")
        return {
            "heading": "Configuration Error", 
            "type": "ERROR", 
            "details": "Open backend/app/nlp.py and paste your Gemini API Key."
        }

    today = datetime.datetime.now()
    date_str = today.strftime("%Y-%m-%d")
    time_str = today.strftime("%I:%M %p")

    # Prompt Template
    prompt = f"""
    Current System Time: {date_str} at {time_str}.
    
    Task: Extract actionable data from this text: "{text}"
    
    Return STRICT JSON (no markdown) with this structure:
    {{
        "heading": "Short Topic (e.g. 'Project Meeting')",
        "type": "SCHEDULE" or "TODO" or "NOTE",
        "date": "YYYY-MM-DD" (Convert 'tomorrow'/'next friday' to dates),
        "time": "HH:MM AM/PM" (Convert '10 in morning' to '10:00 AM'),
        "details": "A clear, summarized description of the task."
    }}
    """

    def generate_with_model(model_name):
        print(f"[NLP DEBUG] Trying model: {model_name}...")
        model = genai.GenerativeModel(model_name)
        response = model.generate_content(prompt)
        return response.text

    try:
        # 1. Try the Fast/New Model First
        try:
            raw_text = generate_with_model('gemini-1.5-flash')
        except Exception as e:
            print(f"⚠️ [NLP DEBUG] Flash model failed ({e}). Switching to 'gemini-pro'...")
            # 2. Fallback to Stable Model if Flash fails (e.g. 404 error)
            raw_text = generate_with_model('gemini-1.5-flash-latest')

        # Robust cleanup to handle Markdown code blocks
        if "```json" in raw_text:
            raw_text = raw_text.split("```json")[1].split("```")[0]
        elif "```" in raw_text:
            raw_text = raw_text.split("```")[1].split("```")[0]
        
        result_json = json.loads(raw_text.strip())
        
        # DEBUG PRINT: Show what Gemini replied
        print(f"[NLP DEBUG] AI Response: {result_json}\n")
        
        return result_json

    except Exception as e:
        print(f"❌ [NLP DEBUG] Fatal Error: {e}")
        return {"heading": "Analysis Failed", "type": "ERROR", "details": str(e)}