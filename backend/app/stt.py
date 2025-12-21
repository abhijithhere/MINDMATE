import speech_recognition as sr
import os

def transcribe_file(audio_file_path):
    """
    Takes a path to an audio file (WAV/FLAC) and returns the transcribed text.
    """
    recognizer = sr.Recognizer()

    # check if file exists
    if not os.path.exists(audio_file_path):
        print(f"❌ Error: Audio file not found at {audio_file_path}")
        return None

    try:
        # Load audio file
        with sr.AudioFile(audio_file_path) as source:
            # record the audio data from the file
            audio_data = recognizer.record(source)
            
            # Recognize using Google Web Speech API (Free, requires internet)
            # You can swap this for 'recognize_whisper' if you install OpenAI Whisper
            text = recognizer.recognize_google(audio_data)
            print(f"🗣️ Transcript: {text}")
            return text

    except sr.UnknownValueError:
        print("❌ STT Error: Could not understand audio")
        return None
    except sr.RequestError as e:
        print(f"❌ STT Error: API unavailable; {e}")
        return None
    except Exception as e:
        print(f"❌ STT Error: {e}")
        return None