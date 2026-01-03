import joblib
import numpy as np

# 1. Load model
model_path = r"C:\project\main_project\2\backend\models\habit_model.pkl"
clf = joblib.load(model_path)

# 2. Define your mapping (copied from your code)
# We reverse it so we can look up by Number -> Name
activity_map = {'Sleep': 0, 'Breakfast': 1, 'Study': 2, 'Work': 3, 'Rest': 4, 'Gym': 5}
# Create a reverse map: {0: 'Sleep', 1: 'Breakfast', ...}
id_to_activity = {v: k for k, v in activity_map.items()}

# 3. Predict
dummy_input = [[10, 1, 5, 0, 10, 0]] 
prediction = clf.predict(np.array(dummy_input))
predicted_id = int(prediction[0])

# 4. Get the name
habit_name = id_to_activity.get(predicted_id, "Unknown")

print("-" * 30)
print(f"🔮 Prediction: {predicted_id}")
print(f"📖 Habit Name: {habit_name}")
print("-" * 30)