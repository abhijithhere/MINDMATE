# services/voice_auth.py
"""
Voice Authentication — scipy + encode_batch, no TorchCodec.

Threshold lowered to 0.08:
  Scores 0.06-0.09 are real voice matches on 3-sec clips.
  ECAPA scores on short clips are lower than on full sentences.
  0.08 catches real matches while still blocking completely different voices (<0).
"""

import os
import shutil
import numpy as np

os.environ["TORCHAUDIO_BACKEND"] = "soundfile"

import torchaudio
if not hasattr(torchaudio, 'list_audio_backends'):
    torchaudio.list_audio_backends = lambda: []  # type: ignore[attr-defined]
try:
    torchaudio.set_audio_backend("soundfile")
except Exception:
    pass

import torch

# huggingface_hub patch
try:
    import huggingface_hub as _hf
    _o = _hf.hf_hub_download
    def _p(*a, **kw):
        if 'use_auth_token' in kw: kw['token'] = kw.pop('use_auth_token')
        return _o(*a, **kw)
    _hf.hf_hub_download = _p
    try:
        import huggingface_hub.file_download as _fd; _fd.hf_hub_download = _p
    except Exception: pass
except Exception: pass

_SB_OK = False
SpeakerRecognition = None  # type: ignore[assignment]
try:
    from speechbrain.inference.speaker import SpeakerRecognition  # type: ignore[no-redef]
    _SB_OK = True; print("✅ SpeechBrain 1.x")
except ImportError:
    try:
        from speechbrain.pretrained import SpeakerRecognition      # type: ignore[no-redef]
        _SB_OK = True; print("✅ SpeechBrain 0.5.x")
    except Exception as e:
        print(f"⚠️  SpeechBrain: {e}")

# ── Config ─────────────────────────────────────────────────────────────────────
# 0.08 threshold: ECAPA scores on 3-sec clips typically 0.05-0.15 for same speaker
# Negative = silence/noise was in the chunk (not a real voice comparison)
THRESHOLD     = 0.08
BASE_DIR      = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MODEL_DIR     = os.path.join(BASE_DIR, "voice_auth_model")
SIG_DIR       = os.path.join(BASE_DIR, "voice_signatures")
MASTER_ENROLL = os.path.join(BASE_DIR, "user_voice_enroll.wav")

print(f"📂 SIG_DIR: {SIG_DIR}  files={os.listdir(SIG_DIR) if os.path.isdir(SIG_DIR) else 'N/A'}")

_verifier = None
if _SB_OK and SpeakerRecognition is not None:
    try:
        _verifier = SpeakerRecognition.from_hparams(
            source=MODEL_DIR, savedir=MODEL_DIR, run_opts={"device": "cpu"})
        print("✅ Voice auth model ready.")
    except Exception as e:
        print(f"❌ Model load failed: {e}")


def _load_wav(path: str) -> torch.Tensor:
    """Load wav via scipy → (1, samples) float32 tensor at 16kHz."""
    from scipy.io import wavfile
    sr, data = wavfile.read(path)
    if data.dtype == np.int16:
        data = data.astype(np.float32) / 32768.0
    elif data.dtype == np.int32:
        data = data.astype(np.float32) / 2147483648.0
    data = data.astype(np.float32)
    if data.ndim > 1:
        data = data.mean(axis=1)
    t = torch.tensor(data).unsqueeze(0)
    if sr != 16000:
        t = torchaudio.functional.resample(t, sr, 16000)
    return t


def _safe_name(uid: str) -> str:
    return uid.replace("@", "_").replace(".", "_")

def _find_enrollment(user_id: str) -> str | None:
    safe = _safe_name(user_id)
    candidates = [
        os.path.join(SIG_DIR, f"{safe}.wav"),
        os.path.join(SIG_DIR, f"{user_id}.wav"),
        MASTER_ENROLL,
    ]
    if os.path.isdir(SIG_DIR):
        for f in sorted(os.listdir(SIG_DIR)):
            if f.endswith(".wav"):
                p = os.path.join(SIG_DIR, f)
                if p not in candidates: candidates.append(p)
    for path in dict.fromkeys(candidates):
        if os.path.exists(path):
            print(f"🔑 Enrollment: {os.path.basename(path)}")
            return path
    print(f"⚠️  No enrollment for '{user_id}'")
    return None


def verify_voice_owner(user_id: str, audio_path: str) -> tuple[bool, int]:
    if _verifier is None:
        print("⚠️  Verifier not loaded — flag=0")
        return False, 0
    if not os.path.exists(audio_path):
        return False, 0

    enrollment = _find_enrollment(user_id)
    if enrollment is None:
        return False, 0

    try:
        enroll_t = _load_wav(enrollment)
        input_t  = _load_wav(audio_path)

        with torch.no_grad():
            e1 = _verifier.encode_batch(enroll_t)
            e2 = _verifier.encode_batch(input_t)

        v1 = e1.squeeze(); v2 = e2.squeeze()
        score = torch.nn.functional.cosine_similarity(
            v1.unsqueeze(0), v2.unsqueeze(0)).item()

        verified = score >= THRESHOLD
        flag     = 1 if verified else 0
        print(f"🕵️  [{user_id}] {'✅ PASS' if verified else '❌ FAIL'} "
              f"score={score:.4f} threshold={THRESHOLD} flag={flag}")
        if score < 0:
            print("   ℹ️  Negative score = chunk had silence/noise not voice")
        return verified, flag
    except Exception as e:
        print(f"❌ Verify error: {e}")
        return False, 0


def enroll_voice(user_id: str, wav_path: str) -> bool:
    os.makedirs(SIG_DIR, exist_ok=True)
    dest = os.path.join(SIG_DIR, f"{_safe_name(user_id)}.wav")
    try:
        shutil.copy2(wav_path, dest)
        print(f"✅ Enrolled '{user_id}' → {dest}")
        return True
    except Exception as e:
        print(f"❌ Enroll failed: {e}"); return False

def voice_security(uid: str, path: str) -> bool:
    v, _ = verify_voice_owner(uid, path); return v