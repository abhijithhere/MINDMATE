from services.db import get_db
from datetime import datetime, timedelta

def get_daily_summary(user_id: str):
    """
    Returns a calculated summary of today's activities and stats.
    """
    conn = get_db()
    cur = conn.cursor()
    
    today_str = datetime.now().strftime("%Y-%m-%d")
    
    # 1. Fetch today's completed events
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
            "message": "No activity recorded today.",
            "event_count": 0,
            "top_category": "None"
        }

    # 2. Calculate Stats
    categories = {}
    timeline = []
    
    for row in events:
        # Build Timeline
        timeline.append(f"{row['start_time'].split(' ')[1]} - {row['title']}")
        
        # Count Categories
        cat = row['category'] or "Uncategorized"
        categories[cat] = categories.get(cat, 0) + 1

    # Find Top Category
    top_cat = max(categories, key=categories.get)
    
    return {
        "date": today_str,
        "event_count": len(events),
        "top_category": top_cat,
        "category_breakdown": categories,
        "timeline": timeline
    }

def get_weekly_pattern(user_id: str):
    """
    Returns the most frequent activity for each hour of the day (Heatmap data).
    """
    from services.patterns import daily_overview
    # We reuse the logic we already wrote in patterns.py
    return daily_overview(user_id)