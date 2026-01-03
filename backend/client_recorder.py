import asyncio
import websockets
import sounddevice as sd
import numpy as np
import json
import sys

# --- CONFIGURATION ---
SERVER_URL = "ws://localhost:8000/ws/listen/test_user"
SAMPLE_RATE = 16000
DEVICE_INDEX = 1  # <--- TRY 1 FIRST. If silent, try 15 or 16.
BUFFER_SECONDS = 3.0 # Send audio every 3 seconds

async def microphone_client():
    print(f"🎤 Connecting to MindMate via Device #{DEVICE_INDEX}...")
    
    async with websockets.connect(SERVER_URL) as websocket:
        print("✅ Connected! Recording...")
        
        loop = asyncio.get_event_loop()
        queue = asyncio.Queue()

        def audio_callback(indata, frames, time, status):
            if status:
                print(f"⚠️ Mic Status: {status}")
            loop.call_soon_threadsafe(queue.put_nowait, indata.copy())

        # Start Recording with SPECIFIC DEVICE
        stream = sd.InputStream(
            device=DEVICE_INDEX, # <--- Forces the correct mic
            samplerate=SAMPLE_RATE,
            channels=1,
            dtype="float32",
            callback=audio_callback
        )
        
        buffer = []
        max_samples = int(SAMPLE_RATE * BUFFER_SECONDS)

        print(f"🔴 SPEAK NOW! (Filling buffer {max_samples} samples)")

        with stream:
            while True:
                # 1. Get audio chunk
                data = await queue.get()
                buffer.append(data)
                
                # 2. Check size
                current_samples = sum(len(x) for x in buffer)
                
                # Visual Feedback: Print a dot for every chunk received
                # If you don't see dots, your mic is dead.
                if len(buffer) % 10 == 0:
                    print(".", end="", flush=True)

                if current_samples >= max_samples:
                    print(f"\n📤 Sending {current_samples} samples...", end=" ")
                    
                    # 3. Combine & Send
                    audio_np = np.concatenate(buffer)
                    audio_bytes = audio_np.tobytes()
                    
                    try:
                        await websocket.send(audio_bytes)
                        print("✅ Sent!")
                        
                        # 4. Wait for AI Response
                        response = await asyncio.wait_for(websocket.recv(), timeout=0.2)
                        data = json.loads(response)
                        
                        if data.get("transcript"):
                            print(f"🧠 YOU: {data['transcript']}")
                        if data.get("ai_response"):
                            print(f"🤖 AI:  {data['ai_response']}")
                            
                    except asyncio.TimeoutError:
                        print(" (No reply yet)")
                    except Exception as e:
                        print(f"❌ Error: {e}")

                    # 5. Reset Buffer
                    buffer = []

if __name__ == "__main__":
    try:
        asyncio.run(microphone_client())
    except KeyboardInterrupt:
        print("\n🛑 Stopped.")
    except Exception as e:
        print(f"\n❌ CRASH: {e}")
        print("Try changing DEVICE_INDEX at the top of the script!")