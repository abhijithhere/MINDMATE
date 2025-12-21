import re
from datetime import datetime, timedelta
from dateutil import parser

def analyze_sentiment(text):
    """
    Simple rule-based sentiment/stress detection.
    Returns: (emotion_label, stress_level)
    """
    text = text.lower()
    stress_keywords = ["tired", "exhausted", "stressed", "busy", "deadline", "anxious", "angry"]
    happy_keywords = ["happy", "great", "good", "excited", "love", "done", "accomplished"]
    
    stress_score = 0.0
    for word in stress_keywords:
        if word in text:
            stress_score += 0.3
            
    if stress_score > 0.6:
        return "negative", min(stress_score, 1.0)
    elif any(word in text for word in happy_keywords):
        return "positive", 0.0
    else:
        return "neutral", 0.1

def extract_datetime(text):
    """
    Attempts to extract a date/time from the text.
    Defaults to 'Now' if nothing specific is found.
    """
    try:
        # Quick heuristic for "tomorrow"
        if "tomorrow" in text.lower():
            dt = datetime.now() + timedelta(days=1)
            # Try to find a specific time like "at 5 pm"
            time_match = re.search(r'at (\d{1,2})(:(\d{2}))?\s*(am|pm)?', text.lower())
            if time_match:
                # Let dateutil handle the specific parsing of the time string
                # We combine the tomorrow date with the time string found
                return parser.parse(time_match.group(0), default=dt).isoformat()
            
            # Default to 9 AM tomorrow if no time specified
            return dt.replace(hour=9, minute=0, second=0).isoformat()
        
        # Heuristic for "today at..."
        if "at " in text.lower():
            return parser.parse(text, fuzzy=True).isoformat()
            
    except:
        pass
    
    # Fallback: Return current time
    return datetime.now().isoformat()

def extract_metadata(text):
    """
    Parses text to determine if it is a Memory, Event, or Reminder.
    """
    if not text: return {}
    text_lower = text.lower()
    
    response_data = {}
    
    # 1. Voice Meta (Emotion)
    emotion, stress = analyze_sentiment(text)
    response_data["voice_meta"] = {"emotion_label": emotion, "stress_level": stress}

    # 2. KEYWORD LISTS
    event_keywords = ["schedule", "meeting", "appointment", "go to", "plan", "remind me", "have a"]
    
    # CASE A: EVENT / REMINDER
    if any(x in text_lower for x in event_keywords):
        start_time = extract_datetime(text)
        
        # Clean title: Remove "Remind me to" or "I have a"
        clean_title = text
        for phrase in ["remind me to", "i have a", "schedule a", "plan a"]:
            if phrase in text_lower:
                clean_title = text_lower.split(phrase, 1)[1].strip()
        
        # Construct Event
        response_data["event"] = {
            "title": clean_title.capitalize(),
            "category": "Work" if "meeting" in text_lower else "Personal",
            "start_time": start_time,
            "location_name": "Office" if "meeting" in text_lower else "Home"
        }
        
        # Construct Reminder
        response_data["reminder"] = {
            "recurrence": None,
            "priority": "High" if "urgent" in text_lower else "Medium"
        }
        
    # CASE B: MEMORY (Fallback)
    else:
        response_data["memory"] = {
            "type": "diary",
            "content": text,
            "confidence": 0.5
        }

    return response_data

def detect_retrieval_intent(text):
    text = text.lower()
    # Check keywords
    if any(x in text for x in ["schedule", "plan", "events", "calendar"]):
        target_date = datetime.now()
        display = "today"
        
        if "tomorrow" in text:
            target_date = target_date + timedelta(days=1)
            display = "tomorrow"
        elif "yesterday" in text:
            target_date = target_date - timedelta(days=1)
            display = "yesterday"
            
        return {
            "intent": "get_schedule",
            "date_str": target_date.strftime("%Y-%m-%d"),
            "display_date": display
        }
    return None