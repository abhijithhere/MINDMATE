import pandas as pd
import numpy as np
from datetime import datetime, timedelta

class FeatureExtractor:
    def __init__(self, slot_minutes=30):
        self.slot_minutes = slot_minutes
        # Mappings: 'Idle' is not here, so we must handle it in logic below
        self.activity_map = {'Sleep': 0, 'Breakfast': 1, 'Study': 2, 'Work': 3, 'Rest': 4, 'Gym': 5}
        self.location_map = {'Home': 0, 'Office': 1, 'Library': 2, 'Transit': 3}
        self.fatigue_map = {'Low': 0, 'Medium': 1, 'High': 2}

    def _get_dominant_activity(self, slot_start, slot_end, raw_logs):
        """
        Implements DOMINANT ACTIVITY RULE.
        """
        # Default to "Rest" (4) instead of "Idle" so we never have unknown activities
        best_activity = "Rest" 
        max_overlap = 0
        slot_duration = (slot_end - slot_start).total_seconds()

        for log in raw_logs:
            overlap_start = max(slot_start, log['start'])
            overlap_end = min(slot_end, log['end'])
            
            if overlap_start < overlap_end:
                overlap_seconds = (overlap_end - overlap_start).total_seconds()
                
                # If an activity takes up >50% of the slot, it wins immediately
                if overlap_seconds > (slot_duration * 0.5):
                    return log['activity'], log['location'], log['fatigue']
                
                if overlap_seconds > max_overlap:
                    max_overlap = overlap_seconds
                    best_activity = log['activity'] 
                    
        return best_activity, "Home", "Low"

    def create_training_data(self, raw_logs, date_str):
        start_of_day = datetime.strptime(date_str, "%Y-%m-%d")
        slots = []
        
        # Create 48 slots for the day (24 hours * 2)
        for i in range(int(24 * 60 / self.slot_minutes)):
            slot_start = start_of_day + timedelta(minutes=i * self.slot_minutes)
            slot_end = slot_start + timedelta(minutes=self.slot_minutes)
            
            act, loc, fat = self._get_dominant_activity(slot_start, slot_end, raw_logs)
            
            slots.append({
                'timestamp': slot_start,
                'raw_activity': act,
                'raw_location': loc,
                'raw_fatigue': fat
            })
            
        return pd.DataFrame(slots)

    def engineer_features(self, df):
        # A. Temporal Features
        df['hour'] = df['timestamp'].dt.hour + (df['timestamp'].dt.minute / 60)
        df['day_of_week'] = df['timestamp'].dt.dayofweek
        
        df['hour_sin'] = np.sin(2 * np.pi * df['hour'] / 24)
        df['hour_cos'] = np.cos(2 * np.pi * df['hour'] / 24)
        
        # B. Contextual Sequence
        # fillna(4) ensures if activity is unknown, it defaults to Rest (4)
        df['target_activity_code'] = df['raw_activity'].map(self.activity_map).fillna(4)
        
        # Shift target to get previous activity
        df['prev_activity_code'] = df['target_activity_code'].shift(1).fillna(self.activity_map['Sleep'])
        
        # C. Encode other contexts
        df['location_code'] = df['raw_location'].map(self.location_map).fillna(0)
        df['fatigue_code'] = df['raw_fatigue'].map(self.fatigue_map).fillna(0)
        
        features = ['hour_sin', 'hour_cos', 'day_of_week', 'prev_activity_code', 'location_code', 'fatigue_code']
        target = ['target_activity_code']
        
        return df[features], df[target]