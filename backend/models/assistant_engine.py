import joblib
import numpy as np
import datetime
import pandas as pd

class AI_Assistant:
    def __init__(self, model_path):
        # 1. Load the Brain
        print(f"🧠 Loading AI Model from {model_path}...")
        self.model = joblib.load(model_path)
        
        # 2. Define the Maps (From your specific data)
        self.activity_map = {'Sleep': 0, 'Breakfast': 1, 'Study': 2, 'Work': 3, 'Rest': 4, 'Gym': 5}
        self.inv_activity_map = {v: k for k, v in self.activity_map.items()}
        
        # Default assumptions for simulation (since we can't predict these perfectly yet)
        self.default_location = 0  # e.g., Home
        self.default_fatigue = 1   # e.g., Medium

    def predict_activity(self, hour, day_of_week, month, prev_activity_id):
        """
        Asks the model: 'Given it is this Hour on this Day, what should I be doing?'
        """
        # ---------------------------------------------------------
        # CRITICAL: This list MUST match the 6 columns you trained on.
        # Assumption: [Hour, DayOfWeek, Month, Location, Fatigue, PrevActivity]
        # ---------------------------------------------------------
        features = np.array([[
            hour,
            day_of_week,
            month,
            self.default_location,
            self.default_fatigue,
            prev_activity_id
        ]])
        
        try:
            pred_id = int(self.model.predict(features)[0])
            return pred_id
        except Exception as e:
            print(f"⚠️ Prediction Error: {e}")
            return 4 # Default to 'Rest' on error

    def generate_day_schedule(self, date_str):
        current_activity_id = 0
        """
        Predicts the TIMETABLE for a specific future date.
        """
        target_date = pd.to_datetime(date_str)
        day_of_week = target_date.dayofweek
        month = target_date.month
        
        print(f"\n📅 Generating Schedule for: {target_date.date().strftime('%A, %B %d')}")
        print("-" * 50)
        
        schedule = []
        # Start the day assuming you were Sleeping (Activity 0)
        current_activity_id = 0 
        
        # Loop through 24 hours
        # Loop through 24 hours
        for hour in range(24):
            # Call the model ONCE and store it in next_id
            next_id = self.predict_activity(hour, day_of_week, month, current_activity_id)
            
            # Use next_id to get the name
            activity_name = self.inv_activity_map.get(next_id, "Unknown")
            
            # Format and save to schedule
            time_str = f"{hour:02d}:00"
            schedule.append((time_str, activity_name))
            
            # VERY IMPORTANT: Move next_id into current_activity_id for the next hour
            current_activity_id = next_id
            
        return schedule

    def generate_day_overview(self, notes_list):
        """
        Uses simple logic to summarize. 
        For 'Advanced' summarization, you would send this to Gemini API.
        """
        print(f"\n📝 Day Overview & Important Notes")
        print("-" * 50)
        if not notes_list:
            print("No notes recorded for this period.")
        else:
            for note in notes_list:
                print(f"• {note}")
        print("-" * 50)

# ==========================================
# MAIN EXECUTION BLOCK
# ==========================================
if __name__ == "__main__":
    # Path to your existing trained model
    path = r"C:\project\main_project\2\backend\models\habit_model.pkl"
    
    # Initialize System
    jarvis = AI_Assistant(path)
    
    # 1. PREDICT FUTURE TIMETABLE (For Tomorrow)
    tomorrow = (datetime.datetime.now() + datetime.timedelta(days=1)).strftime('%Y-%m-%d')
    timetable = jarvis.generate_day_schedule(tomorrow)
    
    # Print the Schedule nicely
    print(f"{'TIME':<10} | {'PREDICTED ACTIVITY'}")
    print("-" * 30)
    for time, activity in timetable:
        print(f"{time:<10} | {activity}")

    # 2. OVERVIEW (Mock Data)
    # In your real app, these would come from your Database
    daily_notes = [
        "Meeting with dev team regarding Voice Auth integration.",
        "Remember to buy groceries after Gym.",
        "Fix the STACK_GLOBAL error in the Python script."
    ]
    jarvis.generate_day_overview(daily_notes)