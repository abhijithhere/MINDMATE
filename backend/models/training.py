import pandas as pd
import numpy as np
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score
import joblib
import random

# ==========================================
# 1. SETUP MAPS (Must match your app logic)
# ==========================================
# The AI needs to know what these numbers mean.
activity_map = {'Sleep': 0, 'Breakfast': 1, 'Study': 2, 'Work': 3, 'Rest': 4, 'Gym': 5}
location_map = {'Home': 0, 'Office': 1, 'Library': 2, 'Transit': 3}
fatigue_map  = {'Low': 0, 'Medium': 1, 'High': 2}

# ==========================================
# 2. DATA GENERATOR (Simulating a Human Life)
# ==========================================
# In the real app, you will replace this with: df = pd.read_sql("SELECT * FROM history")
def generate_mock_data(days=60):
    data = []
    
    for day in range(days):
        # Determine if it's a weekday (0-4) or weekend (5-6)
        day_of_week = day % 7
        is_weekend = day_of_week >= 5
        
        # Start the day fresh
        prev_activity = activity_map['Sleep'] 
        
        for hour in range(24):
            # --- LOGIC: DEFINE "NORMAL" HUMAN BEHAVIOR ---
            
            # Default state
            activity = activity_map['Sleep']
            location = location_map['Home']
            fatigue = fatigue_map['Low']
            
            # Morning Routine (7 AM - 8 AM)
            if 7 <= hour < 9:
                activity = activity_map['Breakfast']
                fatigue = fatigue_map['Low']
                
            # Work/Study Hours (9 AM - 5 PM)
            elif 9 <= hour < 17:
                if is_weekend:
                    activity = activity_map['Rest'] # Relax on weekends
                    location = location_map['Home']
                else:
                    activity = activity_map['Work'] # Work on weekdays
                    location = location_map['Office']
                    fatigue = fatigue_map['Medium']
                    
            # Evening Gym (6 PM - 8 PM)
            elif 18 <= hour < 20:
                # We skip Gym sometimes to make it realistic
                if random.random() > 0.2: 
                    activity = activity_map['Gym']
                    location = location_map['Home'] # Or gym location
                    fatigue = fatigue_map['High']
                else:
                    activity = activity_map['Rest']
            
            # Night Relaxation
            elif 20 <= hour < 23:
                activity = activity_map['Rest']
                location = location_map['Home']
                fatigue = fatigue_map['High']

            # -------------------------------------------------
            # APPEND DATA ROW (The "Features")
            # Must match the 6 inputs the engine expects!
            # -------------------------------------------------
            # [Hour, DayOfWeek, Month, Location, Fatigue, PrevActivity]
            month = 1 # Assuming January for mock data
            
            data.append([hour, day_of_week, month, location, fatigue, prev_activity, activity])
            
            # Update previous activity for the next loop
            prev_activity = activity

    # Convert to DataFrame
    columns = ['hour', 'day_of_week', 'month', 'location', 'fatigue', 'prev_activity', 'target_activity']
    return pd.DataFrame(data, columns=columns)

# ==========================================
# 3. TRAINING THE BRAIN
# ==========================================
print("🔄 Generating synthetic life data...")
df = generate_mock_data(days=90) # Simulate 3 months of data
print(f"📊 Dataset Created: {len(df)} recorded hours.")

# Features (Inputs) vs Target (Output)
X = df[['hour', 'day_of_week', 'month', 'location', 'fatigue', 'prev_activity']]
y = df['target_activity']

# Split data to test accuracy
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

# Initialize the Random Forest
print("🧠 Training Random Forest Model...")
clf = RandomForestClassifier(n_estimators=100, random_state=42)
clf.fit(X_train, y_train)

# Test Accuracy
y_pred = clf.predict(X_test)
acc = accuracy_score(y_test, y_pred)
print(f"✅ Training Complete! Model Accuracy: {acc * 100:.2f}%")

# ==========================================
# 4. SAVE THE MODEL
# ==========================================
save_path = r"C:\project\main_project\2\backend\models\habit_model.pkl"
joblib.dump(clf, save_path)
print(f"💾 Model saved to: {save_path}")

# Optional: Verify it loaded back
print("🔍 Verifying file...")
loaded_model = joblib.load(save_path)
print(f"   Model expects {loaded_model.n_features_in_} features. (Should be 6)")