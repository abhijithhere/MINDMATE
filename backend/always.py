import sqlite3
import os

# Connect to database
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DB_PATH = os.path.join(BASE_DIR, "db", "mindmate.db")

def check_data():
    if not os.path.exists(DB_PATH):
        print(f"❌ No database found at {DB_PATH}")
        return

    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    print("📊 checking event counts by User...")
    try:
        cursor.execute("SELECT user_id, COUNT(*) FROM events GROUP BY user_id")
        rows = cursor.fetchall()
        
        if not rows:
            print("⚠️ The 'events' table is empty!")
        else:
            for user, count in rows:
                print(f"✅ User: '{user}' has {count} event logs.")
    except Exception as e:
        print(f"Error reading DB: {e}")
        
    conn.close()

if __name__ == "__main__":
    check_data()