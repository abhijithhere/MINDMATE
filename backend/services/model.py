import joblib
import os
import numpy as np
from datetime import datetime

# 🟢 FIX: Look in sibling folder 'models'
CURRENT_DIR = os.path.dirname(os.path.abspath(__file__)) # backend/services/
BACKEND_DIR = os.path.dirname(CURRENT_DIR)               # backend/
MODEL_DIR = os.path.join(BACKEND_DIR, "models")          # backend/models/

class MindMateModel:
    def __init__(self):
        self.model = None
        # Static Maps (Must match features.py!)
        self.activity_map = {'Sleep': 0, 'Breakfast': 1, 'Study': 2, 'Work': 3, 'Rest': 4, 'Gym': 5}
        self.location_map = {'Home': 0, 'Office': 1, 'Library': 2, 'Transit': 3}
        self.fatigue_map = {'Low': 0, 'Medium': 1, 'High': 2}
        self.reverse_activity_map = {v: k for k, v in self.activity_map.items()}
        
        self._load_models()

    def _load_models(self):
        try:
            model_path = os.path.join(MODEL_DIR, "habit_model.pkl")
            if os.path.exists(model_path):
                self.model = joblib.load(model_path)
                print(f"✅ ML Brain loaded from: {model_path}")
            else:
                print(f"⚠️ ML Model not found at: {model_path}")
        except Exception as e:
            print(f"❌ Error loading ML model: {e}")

    def predict_single(self, hour, day_of_week, prev_activity, location="Home", fatigue="Low"):
        if not self.model: return "Rest"

        hour_sin = np.sin(2 * np.pi * hour / 24)
        hour_cos = np.cos(2 * np.pi * hour / 24)
        
        prev_code = self.activity_map.get(prev_activity, 4)
        loc_code = self.location_map.get(location, 0)
        fat_code = self.fatigue_map.get(fatigue, 0)

        X_input = [[hour_sin, hour_cos, day_of_week, prev_code, loc_code, fat_code]]
        
        try:
            pred_idx = self.model.predict(X_input)[0]
            return self.reverse_activity_map.get(pred_idx, "Rest")
        except:
            return "Rest"

    def suggest_daily_schedule(self, target_date_str):
        # ... (Keep existing simulation logic) ...
        # (This part doesn't need path changes)AC
        try:
            target_date = datetime.strptime(target_date_str, "%Y-%m-%d")
        except ValueError:
            target_date = datetime.now()

        day_of_week = target_date.weekday()
        schedule = []
        current_activity = "Sleep" 
        
        for hour in range(7, 24):
            location = "Home"
            if current_activity in ["Work", "Study"]: location = "Office"
            if current_activity == "Gym": location = "Gym"
            
            fatigue = "Low"
            if hour > 18: fatigue = "Medium"
            if hour > 21: fatigue = "High"

            next_activity = self.predict_single(hour, day_of_week, current_activity, location, fatigue)
            
            schedule.append({
                "time": f"{hour:02d}:00",
                "activity": next_activity,
                "location": location
            })
            current_activity = next_activity
            
        return schedule