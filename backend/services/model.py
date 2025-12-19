import joblib
import os
import numpy as np
from datetime import datetime, timedelta

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MODEL_DIR = os.path.join(BASE_DIR, "models")

class MindMateModel:
    def __init__(self):
        self.model = None
        self._load_models()
        
        # Static Maps (Must match training!)
        self.activity_map = {'Sleep': 0, 'Breakfast': 1, 'Study': 2, 'Work': 3, 'Rest': 4, 'Gym': 5}
        self.location_map = {'Home': 0, 'Office': 1, 'Library': 2, 'Transit': 3}
        self.fatigue_map = {'Low': 0, 'Medium': 1, 'High': 2}
        self.reverse_activity_map = {v: k for k, v in self.activity_map.items()}

    def _load_models(self):
        try:
            model_path = os.path.join(MODEL_DIR, "habit_model.pkl")
            self.model = joblib.load(model_path)
            print("✅ ML Brain loaded successfully.")
        except FileNotFoundError:
            print("⚠️ ML Model not found. Run training first.")

    def predict_single(self, hour, day_of_week, prev_activity, location="Home", fatigue="Low"):
        if not self.model: return None

        # Feature Engineering
        hour_sin = np.sin(2 * np.pi * hour / 24)
        hour_cos = np.cos(2 * np.pi * hour / 24)
        
        # Encode Inputs
        prev_code = self.activity_map.get(prev_activity, 4) # Default Rest
        loc_code = self.location_map.get(location, 0)       # Default Home
        fat_code = self.fatigue_map.get(fatigue, 0)         # Default Low

        X_input = [[hour_sin, hour_cos, day_of_week, prev_code, loc_code, fat_code]]
        
        try:
            pred_idx = self.model.predict(X_input)[0]
            return self.reverse_activity_map.get(pred_idx, "Rest")
        except:
            return "Rest"

    def suggest_daily_schedule(self, target_date_str):
        """Simulates a full day schedule based on previous habits"""
        target_date = datetime.strptime(target_date_str, "%Y-%m-%d")
        day_of_week = target_date.weekday()
        
        schedule = []
        
        # Start the simulation at 7:00 AM assuming user was Sleeping
        current_activity = "Sleep" 
        
        # Loop from 07:00 to 23:00 (11 PM)
        for hour in range(7, 24):
            # Dynamic Context Rules (Simple Heuristics for realism)
            location = "Home"
            if current_activity in ["Work", "Study"]: location = "Office"
            if current_activity == "Gym": location = "Gym"
            
            fatigue = "Low"
            if hour > 18: fatigue = "Medium"
            if hour > 21: fatigue = "High"

            # Predict THIS hour based on PREVIOUS hour
            next_activity = self.predict_single(hour, day_of_week, current_activity, location, fatigue)
            
            # Add to schedule
            schedule.append({
                "time": f"{hour:02d}:00",
                "activity": next_activity,
                "location": location
            })
            
            # Update context for next loop
            current_activity = next_activity
            
        return schedule