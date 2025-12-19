import sqlite3
import os

# 1. Define the path to the database file
# This points to backend/db/mindmate.db
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__))) 
DB_PATH = os.path.join(BASE_DIR, "db", "mindmate.db")

def get_db():
    """Establishes a connection to the SQLite database."""
    # 2. Ensure the db/ folder exists
    os.makedirs(os.path.dirname(DB_PATH), exist_ok=True)
    
    # 3. Connect
    conn = sqlite3.connect(DB_PATH, check_same_thread=False)
    
    # 4. Return rows as dictionary-like objects (allows row['column_name'])
    conn.row_factory = sqlite3.Row 
    return conn