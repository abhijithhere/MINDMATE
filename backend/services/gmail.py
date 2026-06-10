# services/gmail.py
import os
import json
import base64
import pickle
import re
from datetime import datetime
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow
from google.auth.transport.requests import Request
from googleapiclient.discovery import build
from email.mime.text import MIMEText
import requests

from services.db_helper import save_to_appropriate_table

SCOPES = [
    'https://www.googleapis.com/auth/gmail.readonly',
    'https://www.googleapis.com/auth/gmail.send'
]

OLLAMA_URL = "http://localhost:11434/api/generate"


# ── Auth ───────────────────────────────────────────────────────────────────────
def get_gmail_service(user_id):
    """Authenticates based on specific user_id to prevent data leakage."""
    creds      = None
    token_dir  = 'tokens'
    token_path = os.path.join(token_dir, f'token_{user_id}.pickle')

    if not os.path.exists(token_dir):
        os.makedirs(token_dir)

    if os.path.exists(token_path):
        with open(token_path, 'rb') as token:
            creds = pickle.load(token)

    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            creds.refresh(Request())
        else:
            flow  = InstalledAppFlow.from_client_secrets_file('credentials.json', SCOPES)
            creds = flow.run_local_server(port=0)
        with open(token_path, 'wb') as token:
            pickle.dump(creds, token)

    return build('gmail', 'v1', credentials=creds)


# ── LLM helper ─────────────────────────────────────────────────────────────────
def call_llm_json(prompt):
    """Forces Ollama into JSON mode and cleans output."""
    try:
        r = requests.post(
            OLLAMA_URL,
            json={"model": "phi3", "prompt": prompt, "format": "json", "stream": False},
            timeout=45
        )
        response_text = r.json().get("response", "").strip()
        match = re.search(r'\{.*\}', response_text, re.DOTALL)
        if match:
            cleaned = re.sub(r',\s*\}', '}', match.group(0))
            return json.loads(cleaned)
        return {"has_data": False}
    except Exception as e:
        print(f"⚠️  JSON Parse Fail: {e}")
        return {"has_data": False}


# ── Deep sync ──────────────────────────────────────────────────────────────────
def deep_sync_gmail(user_id, count=50):
    """Scans emails and populates DB with strict date enforcement."""
    print(f"📬 Gmail sync: {user_id} ({count} emails)...")
    try:
        service  = get_gmail_service(user_id)
        results  = service.users().messages().list(userId='me', maxResults=count).execute()
        messages = results.get('messages', [])
        now_str  = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

        stored = 0
        for message in messages:
            msg     = service.users().messages().get(userId='me', id=message['id']).execute()
            snippet = msg.get('snippet', '').replace('"', "'").strip()
            if not snippet:
                continue

            prompt = f"""
            Extract info from email: "{snippet}"
            Reference Time: {now_str}

            Rules:
            1. Return JSON ONLY.
            2. If an event is found, "date" MUST be in 'YYYY-MM-DD HH:MM:00' format.
            3. NEVER use placeholders like 'current_date'. If unknown, use '{now_str}'.
            4. "priority": "High" for deadlines/meetings/medicine, "Low" otherwise.
            5. "priority_int": 1 for High, 0 for Low.

            Schema:
            {{
              "has_data":     true,
              "type":         "event" | "note" | "task" | "reminder",
              "category":     "event" | "reminder" | "note",
              "decision":     "STORE",
              "priority":     "High" | "Low",
              "priority_int": 1 | 0,
              "summary":      "Short summary",
              "is_long":      false,
              "data": {{
                "title":    "Short Heading",
                "content":  "Description",
                "date":     "{now_str}",
                "location": ""
              }}
            }}
            """
            analysis = call_llm_json(prompt)
            if analysis and analysis.get("has_data"):
                analysis["decision"] = "STORE"
                save_to_appropriate_table(
                    user_id         = user_id,
                    analysis        = analysis,
                    text            = snippet,
                    source          = "Gmail",
                    flag            = 0,
                    origin_location = "Gmail",
                )
                stored += 1

        print(f"✅ Gmail sync complete: {stored}/{len(messages)} stored for {user_id}.")
    except Exception as e:
        print(f"❌ Gmail sync failed [{user_id}]: {e}")


# ── Send email ──────────────────────────────────────────────────────────────────
def send_gmail_message(user_id, recipient_email, subject, body):
    """Sends an email using the specific user's credentials."""
    try:
        service = get_gmail_service(user_id)
        message = MIMEText(body)
        message['to']      = recipient_email
        message['subject'] = subject
        raw = base64.urlsafe_b64encode(message.as_bytes()).decode()
        service.users().messages().send(userId='me', body={'raw': raw}).execute()
        print(f"✅ Email sent to {recipient_email}")
        return f"Email sent to {recipient_email}."
    except Exception as e:
        print(f"❌ Send email failed: {e}")
        return f"Failed to send email: {e}"


# ── Voice email command ────────────────────────────────────────────────────────
def handle_voice_email_command(user_id: str, transcript: str) -> str:
    """
    Parses a voice command like:
      "Send an email to john@example.com about the project deadline"
    Extracts recipient, subject, body via LLM then calls send_gmail_message.
    Returns a confirmation string for TTS.
    """
    prompt = f"""
Extract email details from this voice command.
Command: "{transcript}"

Return ONLY valid JSON:
{{
  "recipient": "<email address>",
  "subject":   "<short subject line>",
  "body":      "<email body text>"
}}
If you cannot find a valid recipient email, set "recipient": "unknown".
"""
    try:
        r    = requests.post(
            OLLAMA_URL,
            json={"model": "phi3", "prompt": prompt, "format": "json", "stream": False},
            timeout=30,
        )
        raw  = r.json().get("response", "{}").strip()
        # Strip markdown fences if present
        raw  = re.sub(r'```json|```', '', raw).strip()
        data = json.loads(raw)

        recipient = data.get("recipient", "unknown")
        subject   = data.get("subject",   "MindMate Message")
        body      = data.get("body",      transcript)

        if recipient == "unknown" or "@" not in str(recipient):
            return "I couldn't find a valid email address in your command."

        return send_gmail_message(user_id, recipient, subject, body)

    except Exception as e:
        print(f"❌ Voice email command error: {e}")
        return "I had trouble sending that email."