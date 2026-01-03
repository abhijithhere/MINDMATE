import os
import shutil
import torch
import torchaudio
import soundfile as sf
import numpy as np

# --- 🛠️ CRITICAL FIX: APPLY PATCH FIRST! ---
# We MUST define this BEFORE importing speechbrain.
# SpeechBrain checks torchaudio immediately upon loading.
if not hasattr(torchaudio, "list_audio_backends"):
    torchaudio.list_audio_backends = lambda: ["soundfile"]
# -------------------------------------------

# NOW it is safe to import SpeechBrain
from speechbrain.inference.speaker import SpeakerRecognition

# --- CONFIG ---
VOICE_DB_DIR = "voice_signatures"
MODEL_SOURCE = "speechbrain/spkrec-ecapa-voxceleb"
SAVED_MODEL_DIR = "voice_auth_model"

os.makedirs(VOICE_DB_DIR, exist_ok=True)

class VoiceAuthenticator:
    def __init__(self):
        print("🔒 Loading Voice Security Model (SpeechBrain)...")
        # Detect GPU or CPU
        self.device = "cuda" if torch.cuda.is_available() else "cpu"
        run_opts = {"device": self.device}
        
        self.verification_model = SpeakerRecognition.from_hparams(
            source=MODEL_SOURCE, 
            savedir=SAVED_MODEL_DIR, 
            run_opts=run_opts
        )
        print("✅ Voice Security Model Loaded.")

    def enroll_user(self, user_id: str, audio_path: str):
        """
        Saves the uploaded audio as the 'Master Reference'.
        """
        user_signature_path = os.path.join(VOICE_DB_DIR, f"{user_id}.wav")
        shutil.copy(audio_path, user_signature_path)
        return True

    def _manual_load(self, path):
        """
        Loads audio using SoundFile (Bypassing Torchaudio completely).
        """
        # 1. Read file directly with SoundFile
        data, samplerate = sf.read(path)

        # 2. Convert to PyTorch Tensor
        tensor = torch.from_numpy(data).float()

        # 3. Handle Channels
        if len(tensor.shape) > 1:
            tensor = tensor[:, 0]
        
        # 4. Add Batch Dimension
        tensor = tensor.unsqueeze(0)

        # 5. Move to Device
        return tensor.to(self.device)

    def verify_user(self, user_id: str, input_audio_path: str):
        """
        Compares input audio vs. Master Reference manually.
        """
        reference_path = os.path.join(VOICE_DB_DIR, f"{user_id}.wav")
        
        if not os.path.exists(reference_path):
            print("❌ User not found.")
            return False, 0.0 

        try:
            # A. Load files manually
            ref_wav = self._manual_load(reference_path)
            in_wav = self._manual_load(input_audio_path)

            # B. Verify Raw Tensors
            score, prediction = self.verification_model.verify_batch(ref_wav, in_wav)
            
            # C. Output
            return bool(prediction[0]), float(score[0])

        except Exception as e:
            print(f"❌ Verification Error: {e}")
            import traceback
            traceback.print_exc()
            return False, 0.0

voice_security = VoiceAuthenticator()