import os.path
import pickle
import base64
from email.mime.text import MIMEText
from google.auth.transport.requests import Request
from google_auth_oauthlib.flow import InstalledAppFlow
from googleapiclient.discovery import build

# 1. Setup Paths
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CREDENTIALS_FILE = os.path.join(BASE_DIR, 'credentials.json')
TOKEN_FILE = os.path.join(BASE_DIR, 'token.pickle')

# 2. Define Permissions (Read & Send)
SCOPES = [
    'https://www.googleapis.com/auth/gmail.readonly',
    'https://www.googleapis.com/auth/gmail.send'
]

def get_gmail_service():
    """Authenticates the user and returns the Gmail Service."""
    creds = None
    
    # Load token if it exists
    if os.path.exists(TOKEN_FILE):
        with open(TOKEN_FILE, 'rb') as token:
            creds = pickle.load(token)
    
    # If no token, log in
    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            try:
                creds.refresh(Request())
            except:
                if os.path.exists(TOKEN_FILE):
                    os.remove(TOKEN_FILE)
                return get_gmail_service()
        else:
            if not os.path.exists(CREDENTIALS_FILE):
                print(f"❌ Error: credentials.json not found at {CREDENTIALS_FILE}")
                return None
            
            flow = InstalledAppFlow.from_client_secrets_file(CREDENTIALS_FILE, SCOPES)
            creds = flow.run_local_server(port=0)
        
        # Save token for next time
        with open(TOKEN_FILE, 'wb') as token:
            pickle.dump(creds, token)

    return build('gmail', 'v1', credentials=creds)

def fetch_recent_emails(limit=5):
    """Fetches emails for the AI."""
    try:
        service = get_gmail_service()
        if not service: return "Error: credentials.json missing."

        results = service.users().messages().list(userId='me', maxResults=limit).execute()
        messages = results.get('messages', [])

        if not messages:
            return "No emails found."

        summary = []
        for message in messages:
            msg = service.users().messages().get(userId='me', id=message['id']).execute()
            headers = msg['payload']['headers']
            subject = next((h['value'] for h in headers if h['name'] == 'Subject'), "No Subject")
            sender = next((h['value'] for h in headers if h['name'] == 'From'), "Unknown")
            snippet = msg.get('snippet', '')
            summary.append(f"📩 From: {sender}\n   Subject: {subject}\n   Snippet: {snippet}\n")

        return "\n".join(summary)

    except Exception as e:
        return f"Error: {str(e)}"

def send_email(to_email, subject, body):
    """Sends an email."""
    try:
        service = get_gmail_service()
        message = MIMEText(body)
        message['to'] = to_email
        message['subject'] = subject
        
        raw = base64.urlsafe_b64encode(message.as_bytes()).decode('utf-8')
        body = {'raw': raw}
        
        service.users().messages().send(userId='me', body=body).execute()
        print(f"✅ Email sent to {to_email}")
        return True
    except Exception as e:
        print(f"❌ Send Error: {e}")
        return False