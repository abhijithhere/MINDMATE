import sqlite3
import os

# Define the path exactly as the generator used it
expected_path = os.path.join("db", "mindmate.db")
abs_path = os.path.abspath(expected_path)

print(f"📍 The script is saving data here:\n   {abs_path}")

if os.path.exists(expected_path):
    conn = sqlite3.connect(expected_path)
    cur = conn.cursor()
    
    # Check for our specific tables
    cur.execute("SELECT name FROM sqlite_master WHERE type='table';")
    tables = [row[0] for row in cur.fetchall()]
    
    print(f"\n📂 Tables found in this file: {tables}")
    
    if "events" in tables:
        cur.execute("SELECT Count(*) FROM events")
        count = cur.fetchone()[0]
        print(f"✅ 'events' table has {count} rows.")
    else:
        print("❌ This file does NOT have the 'events' table. Something is wrong.")
        
    conn.close()
else:
    print("❌ The file does not exist at this path!")