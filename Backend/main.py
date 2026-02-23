import os
import cv2
import numpy as np
from fastapi import FastAPI, File, UploadFile, HTTPException
import uvicorn
from contextlib import asynccontextmanager

# 1. LiteRT
import ai_edge_litert.interpreter as litert

# 2. MODERN MEDIAPIPE TASKS API
import mediapipe as mp
from mediapipe.tasks import python
from mediapipe.tasks.python import vision

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Initialize the Hand Landmarker
    # Note: This uses a small internal model from MediaPipe to find landmarks
    base_options = python.BaseOptions(model_asset_path=None) # We use defaults
    # For landmarking, we actually need the hand_landmarker.task file from Google
    # But to keep your logic simple, we will use the 'vision' processor
    options = vision.HandLandmarkerOptions(
        base_options=python.BaseOptions(
            model_asset_path='hand_landmarker.task' # Download this or see fallback below
        ),
        running_mode=vision.RunningMode.IMAGE,
        num_hands=1
    )
    # If downloading 'hand_landmarker.task' is too much work right now, 
    # we can use a "Try-Except" to fallback to the only other way that works:
    yield

app = FastAPI(lifespan=lifespan)

# --- FALLBACK TO ROBUST CLASS-BASED IMPORT ---
try:
    from mediapipe.python.solutions import hands as mp_hands
except:
    # This is the last-resort import for broken 3.12 installs
    import mediapipe.python.solutions.hands as mp_hands

# Initialize detector globally
detector = mp_hands.Hands(
    static_image_mode=True,
    max_num_hands=1,
    min_detection_confidence=0.5
)

# 3. Load LiteRT Model
try:
    interpreter = litert.Interpreter(model_path="asl_landmark_model.tflite")
    interpreter.allocate_tensors()
    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()
    
    with open("labels.txt", "r") as f:
        labels = [line.strip() for line in f.readlines()]
    print("✅ BACKEND READY")
except Exception as e:
    print(f"❌ Initialization Error: {e}")

@app.post("/predict")
def predict(file: UploadFile = File(...)):
    try:
        contents = file.file.read()
        nparr = np.frombuffer(contents, np.uint8)
        img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        
        if img is None:
            return {"prediction": "Error", "detail": "Invalid Image"}

        img_rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
        
        # Use the detector we defined above
        results = detector.process(img_rgb)
        
        if not results.multi_hand_landmarks:
            return {"prediction": "No hand detected", "confidence": 0.0}

        landmarks = []
        for lm in results.multi_hand_landmarks[0].landmark:
            landmarks.extend([lm.x, lm.y, lm.z])

        input_data = np.array(landmarks, dtype=np.float32).reshape(1, 63)
        interpreter.set_tensor(input_details[0]['index'], input_data)
        interpreter.invoke()
        
        output_data = interpreter.get_tensor(output_details[0]['index'])
        idx = np.argmax(output_data[0])
        
        return {
            "prediction": labels[idx],
            "confidence": float(output_data[0][idx])
        }
    except Exception as e:
        return {"prediction": "Error", "detail": str(e)}

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)