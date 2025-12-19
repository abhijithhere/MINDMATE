import joblib
import os
import numpy as np

# Adjust path to find the models folder relative to this file
BASE_DIR = os.path.dirname(os.path.abspath(__file__))

# Load the trained models (Ensure you have run training first!)
try:
    model = joblib.load(os.path.join(BASE_DIR, "habit_model.pkl"))
    prev_enc = joblib.load(os.path.join(BASE_DIR, "prev_encoder.pkl"))
    next_enc = joblib.load(os.path.join(BASE_DIR, "next_encoder.pkl"))
    print("✅ ML Models loaded successfully.")
except FileNotFoundError:
    print("⚠️ Warning: ML models not found. Run training script first.")
    model = None

class MindMateModel:
    def __init__(self, model_path=None):
        # We load global models above, but you can initialize specific paths here if needed
        pass

    def predict_next_slot(self, previous_activity, current_location, current_fatigue, custom_time):
        """
        Predicts the likely activity for the given context.
        """
        if not model:
            return []

        # 1. Feature Engineering on the fly
        hour = custom_time.hour + (custom_time.minute / 60)
        hour_sin = np.sin(2 * np.pi * hour / 24)
        hour_cos = np.cos(2 * np.pi * hour / 24)
        day_of_week = custom_time.weekday()
        
        # Mappings (Must match features.py)
        location_map = {'Home': 0, 'Office': 1, 'Library': 2, 'Transit': 3}
        fatigue_map = {'Low': 0, 'Medium': 1, 'High': 2}
        activity_map = {'Sleep': 0, 'Breakfast': 1, 'Study': 2, 'Work': 3, 'Rest': 4, 'Gym': 5}

        # Encode Inputs
        loc_code = location_map.get(current_location, 0)
        fat_code = fatigue_map.get(current_fatigue, 0)
        prev_code = activity_map.get(previous_activity, 4) # Default to Rest

        # Prepare Input Vector [hour_sin, hour_cos, day, prev, loc, fat]
        X_input = [[hour_sin, hour_cos, day_of_week, prev_code, loc_code, fat_code]]

        # 2. Predict Probabilities
        probs = model.predict_proba(X_input)[0]
        
        # 3. Format Output
        predictions = []
        for i, prob in enumerate(probs):
            if prob > 0.05: # Only show relevant ones
                act_name = [k for k, v in activity_map.items() if v == i][0]
                predictions.append({'activity': act_name, 'probability': prob})
        
        # Sort by highest probability
        predictions.sort(key=lambda x: x['probability'], reverse=True)
        return predictions

    def train(self, logs, user_id):
        # This would call the logic from training.py
        # For now, we assume training happens separately
        pass