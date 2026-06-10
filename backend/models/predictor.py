# models/predictor.py
"""
HabitEngine: loads per-user model and predicts hourly activity for a given date.
"""

import os
import numpy as np
import pandas as pd
import joblib


class HabitEngine:
    def __init__(self, user_id: str):
        self.model    = None
        self.encoder  = None
        self.features = ["Hour", "DayOfWeek", "Month",
                         "hour_sin", "hour_cos", "day_sin", "day_cos",
                         "duration_min"]

        model_path = os.path.join(
            os.path.dirname(os.path.abspath(__file__)),
            "users", f"{user_id}.pkl"
        )

        if os.path.exists(model_path):
            try:
                data = joblib.load(model_path)
                if isinstance(data, dict):
                    self.model    = data.get("model")
                    self.encoder  = data.get("encoder")
                    self.features = data.get("features", self.features)
                else:
                    self.model = data
                print(f"🧠 [HabitEngine] Loaded model for {user_id}")
            except Exception as e:
                print(f"❌ [HabitEngine] Load error: {e}")
        else:
            print(f"⚠️  [HabitEngine] No model for {user_id}. Using static fallback.")

    def predict(self, hour: int, day: int, month: int) -> str:
        if not self.model:
            return self._fallback(hour, day)

        try:
            h_sin = np.sin(2 * np.pi * hour / 24)
            h_cos = np.cos(2 * np.pi * hour / 24)
            d_sin = np.sin(2 * np.pi * day  / 7)
            d_cos = np.cos(2 * np.pi * day  / 7)

            row  = [hour, day, month, h_sin, h_cos, d_sin, d_cos, 30]
            df   = pd.DataFrame([row], columns=self.features)
            pred = self.model.predict(df)[0]

            if self.encoder:
                return self.encoder.inverse_transform([pred])[0]
            return str(pred)
        except Exception as e:
            print(f"⚠️  Predict error: {e}")
            return self._fallback(hour, day)

    @staticmethod
    def _fallback(hour: int, day: int) -> str:
        weekend = day >= 5
        if hour < 6:                    return "Sleep"
        if hour < 7:                    return "Wake Up"
        if hour < 9:                    return "Breakfast"
        if weekend:
            if 9  <= hour < 12:         return "Leisure"
            if 12 <= hour < 14:         return "Lunch"
            if 14 <= hour < 18:         return "Rest & Relax"
            if 18 <= hour < 20:         return "Dinner"
            return "Evening Wind-down"
        else:
            if 9  <= hour < 12:         return "Work / Study"
            if 12 <= hour < 13:         return "Lunch"
            if 13 <= hour < 18:         return "Work / Study"
            if 18 <= hour < 20:         return "Dinner"
            if 20 <= hour < 22:         return "Personal Time"
            return "Sleep Prep"