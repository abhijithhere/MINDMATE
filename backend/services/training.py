import pandas as pd
import numpy as np
import joblib
import os
import sqlite3
from sklearn.ensemble import RandomForestClassifier
from sklearn.preprocessing import LabelEncoder
from services.db import get_db
from models.features import FeatureExtractor

# Define paths for saving models
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__))) # backend/
MODEL_DIR = os.path.join(BASE_DIR, "models")

def fetch_all_logs(user_id):
    """Fetches all historical events for the user."""
    conn = get_db()
    # Convert rows to dicts for easy pandas creation
    conn.row_factory = sqlite3.Row 
    cur = conn.cursor()
    
    cur.execute("""
        SELECT title as activity, start_time, location_id 
        FROM events 
        WHERE user_id = ?
        ORDER BY start_time ASC
    """, (user_id,))
    
    rows = cur.fetchall()
    conn.close()
    
    # Transform into format FeatureExtractor expects
    data = []
    for row in rows:
        # We need end_time. For now, assume 1 hour duration if not set
        start_dt = pd.to_datetime(row['start_time'])
        end_dt = start_dt + pd.Timedelta(hours=1)
        
        data.append({
            'activity': row['activity'],
            'start': start_dt,
            'end': end_dt,
            'location': "Home", # Placeholder: You'd fetch location name via Join in real app
            'fatigue': "Low"    # Placeholder: You'd fetch from voice_analysis if available
        })
    
    return data

def train_model(user_id="test_user"):
    print(f"🧠 Starting Training Job for {user_id}...")
    
    # 1. Fetch Data
    raw_logs = fetch_all_logs(user_id)
    if not raw_logs:
        print("⚠️ No data found. Cannot train.")
        return False

    # 2. Feature Engineering
    # We group logs by day to create the timeline slots
    df_raw = pd.DataFrame(raw_logs)
    dates = df_raw['start'].dt.date.unique()
    
    extractor = FeatureExtractor()
    all_features = []
    all_targets = []
    
    print(f"📊 Processing {len(dates)} days of history...")
    
    for date_obj in dates:
        date_str = str(date_obj)
        # Filter logs for this specific day
        daily_logs = [log for log in raw_logs if log['start'].date() == date_obj]
        
        # Create slots
        df_slots = extractor.create_training_data(daily_logs, date_str)
        
        # Engineer features
        X, y = extractor.engineer_features(df_slots)
        
        all_features.append(X)
        all_targets.append(y)
    
    # Combine all days
    X_train = pd.concat(all_features)
    y_train = pd.concat(all_targets)
    
    # 3. Encode Labels (Prev Activity -> Code)
    # We need Encoders to map "Study" -> 1, "Gym" -> 2
    # Note: features.py uses a static map, but for the MODEL output, we want dynamic support
    
    # Flatten y_train for fitting
    y_flat = y_train.values.ravel()
    
    # 4. Train Random Forest
    print("🌲 Training Random Forest Classifier...")
    clf = RandomForestClassifier(n_estimators=100, random_state=42)
    clf.fit(X_train, y_flat)
    
    # 5. Save Artifacts
    if not os.path.exists(MODEL_DIR):
        os.makedirs(MODEL_DIR)
        
    joblib.dump(clf, os.path.join(MODEL_DIR, "habit_model.pkl"))
    
    # We save these just in case we switch to dynamic encoders later
    # For now, we rely on the static maps in features.py
    # joblib.dump(encoder, ...) 
    
    print("✅ Model Trained & Saved successfully.")
    return True

if __name__ == "__main__":
    train_model()