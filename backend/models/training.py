import pandas as pd
import numpy as np
from sklearn.ensemble import RandomForestClassifier
import joblib
import random
import os

# Preserve your existing maps
activity_map = {'Sleep': 0, 'Breakfast': 1, 'Study': 2, 'Work': 3, 'Rest': 4, 'Gym': 5}
location_map = {'Home': 0, 'Office': 1, 'Library': 2, 'Transit': 3}
fatigue_map  = {'Low': 0, 'Medium': 1, 'High': 2}

def generate_mock_data(days=90):
    data = []
    for day in range(days):
        day_of_week = day % 7
        is_weekend = day_of_week >= 5
        prev_activity = activity_map['Sleep'] 
        
        for hour in range(24):
            # --- YOUR EXISTING LOGIC (PRESERVED) ---
            activity = activity_map['Sleep']
            location = location_map['Home']
            fatigue = fatigue_map['Low']
            
            if 7 <= hour < 9:
                activity = activity_map['Breakfast']
            elif 9 <= hour < 17:
                if is_weekend:
                    activity, location = activity_map['Rest'], location_map['Home']
                else:
                    activity, location, fatigue = activity_map['Work'], location_map['Office'], fatigue_map['Medium']
            elif 18 <= hour < 20:
                activity = activity_map['Gym'] if random.random() > 0.2 else activity_map['Rest']
                fatigue = fatigue_map['High']
            elif 20 <= hour < 23:
                activity, fatigue = activity_map['Rest'], fatigue_map['High']

            # 🟢 FIX: Use Capitalized Column Names to match nlp.py
            month = 1 
            data.append([hour, day_of_week, month, location, fatigue, prev_activity, activity])
            prev_activity = activity

    columns = ['Hour', 'DayOfWeek', 'Month', 'Location', 'Fatigue', 'PrevActivity', 'target_activity']
    return pd.DataFrame(data, columns=columns)

# Training logic (PRESERVED)
df = generate_mock_data()
X = df[['Hour', 'DayOfWeek', 'Month', 'Location', 'Fatigue', 'PrevActivity']]
y = df['target_activity']

clf = RandomForestClassifier(n_estimators=100, random_state=42)
clf.fit(X, y)

# Save Path (PRESERVED)
save_path = r"C:\project\main_project\2\backend\models\habit_model.pkl"
os.makedirs(os.path.dirname(save_path), exist_ok=True)
joblib.dump(clf, save_path)
print(f"✅ Training Complete. Model Accuracy: {clf.score(X, y)*100:.2f}%")