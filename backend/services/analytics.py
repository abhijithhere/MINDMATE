# services/analytics.py
from services.db import get_db
from datetime import datetime

def get_daily_summary(user_id: str):
    """
    Returns a calculated summary of today's activities and stats.
    """
    conn = get_db()
    conn.row_factory = None # Ensure we get tuples for this specific query if needed, or handle dicts
    cur = conn.cursor()
    
    today_str = datetime.now().strftime("%Y-%m-%d")
    
    # 1. Fetch today's completed events
    # We use LIKE 'YYYY-MM-DD%' to match the ISO format string in DB
    cur.execute("""
        SELECT title, category, start_time 
        FROM events 
        WHERE user_id = ? 
        AND start_time LIKE ? 
        ORDER BY start_time ASC
    """, (user_id, f"{today_str}%"))
    
    events = cur.fetchall()
    conn.close()

    if not events:
        return {
            "date": today_str,
            "message": "No activity recorded today.",
            "event_count": 0,
            "top_category": "None",
            "timeline": []
        }

    # 2. Calculate Stats
    categories = {}
    timeline = []
    
    for row in events:
        # If using row_factory, access by index or key depending on setup.
        # Assuming standard tuple here based on previous code style, 
        # but if row_factory is sqlite3.Row, we use keys.
        # Let's handle both safely:
        try:
            title = row['title']
            category = row['category']
            start_time = row['start_time']
        except TypeError:
            title = row[0]
            category = row[1]
            start_time = row[2]

        # Build Timeline (extract HH:MM from YYYY-MM-DD HH:MM:SS)
        time_str = start_time.split(' ')[1][:5] if ' ' in start_time else start_time
        timeline.append(f"{time_str} - {title}")
        
        # Count Categories
        cat = category or "Uncategorized"
        categories[cat] = categories.get(cat, 0) + 1

    # Find Top Category
    top_cat = max(categories, key=categories.get) if categories else "None"
    
    return {
        "date": today_str,
        "event_count": len(events),
        "top_category": top_cat,
        "category_breakdown": categories,
        "timeline": timeline
    }