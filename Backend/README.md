# ASL Hand Gesture Recognition Backend

This backend service provides real-time American Sign Language (ASL) hand gesture recognition using computer vision and machine learning.

## Overview

The backend is a FastAPI-based server that processes images to detect hand gestures and classify them into ASL alphabet letters. It uses a combination of MediaPipe for hand landmark detection and a TensorFlow Lite model for gesture classification.

## Architecture

### Components

1. **FastAPI Server** (`main.py`)
   - REST API endpoint for image processing
   - Handles image uploads and returns predictions
   - Runs on port 8000

2. **Hand Landmark Detection** (MediaPipe)
   - Uses MediaPipe Hands to detect hand landmarks in images
   - Extracts 21 key points (x, y, z coordinates) from detected hands
   - Processes single hands per image

3. **Gesture Classification** (TensorFlow Lite)
   - Uses a pre-trained TensorFlow Lite model (`asl_landmark_model.tflite`)
   - Classifies hand landmarks into ASL alphabet letters
   - Supports 26 letters (A-Z) plus special gestures (del, space)

## Features

- **Real-time Processing**: Processes images in ~500ms intervals
- **Multi-platform**: Works with any device that can send HTTP requests
- **Robust Detection**: Handles various lighting conditions and hand positions
- **Error Handling**: Graceful handling of invalid images and detection failures

## Installation

### Prerequisites

- Python 3.8+
- pip package manager

### Setup

1. Clone the repository
2. Navigate to the Backend directory
3. Install dependencies:

```bash
pip install -r requirements.txt
```

### Required Files

Ensure these files are present in the Backend directory:

- `asl_landmark_model.tflite` - TensorFlow Lite model
- `labels.txt` - Class labels for the model
- `hand_landmarker.task` - MediaPipe hand detection model (optional)

## Usage

### Starting the Server

```bash
python main.py
```

The server will start on `http://localhost:8000`

### API Endpoint

**POST** `/predict`

Upload an image file to get ASL gesture predictions.

**Request:**

- Content-Type: multipart/form-data
- File parameter: `file` (image file)

**Response:**

```json
{
  "prediction": "A",
  "confidence": 0.95
}
```

**Error Responses:**

```json
{
  "prediction": "No hand detected",
  "confidence": 0.0
}
```

```json
{
  "prediction": "Error",
  "detail": "Invalid Image"
}
```

## Model Details

### Hand Landmark Model

- **Framework**: MediaPipe Hands
- **Input**: RGB images
- **Output**: 21 hand landmarks (x, y, z coordinates)
- **Configuration**: Single hand detection, 0.5 confidence threshold

### Classification Model

- **Framework**: TensorFlow Lite
- **Input**: 63 features (21 landmarks × 3 coordinates)
- **Output**: 29 classes (A-Z + del + space)
- **Architecture**: Custom neural network optimized for mobile deployment

## Supported Gestures

The system recognizes:

- **Letters**: A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T, U, V, W, X, Y, Z
- **Special**: del (delete), space

## Performance

- **Detection Speed**: ~100-200ms per image
- **Classification Speed**: ~50-100ms per image
- **Total Latency**: ~500ms end-to-end
- **Accuracy**: Depends on lighting, hand positioning, and model training

## Troubleshooting

### Common Issues

1. **No hand detected**
   - Ensure proper lighting
   - Position hand clearly in frame
   - Remove obstructions

2. **Low confidence predictions**
   - Check hand positioning
   - Ensure good lighting conditions
   - Verify hand is fully visible

3. **Server startup errors**
   - Verify all required files are present
   - Check Python dependencies
   - Ensure correct file permissions

### Dependencies

Key dependencies from `requirements.txt`:

- `fastapi` - Web framework
- `uvicorn` - ASGI server
- `opencv-python` - Image processing
- `numpy` - Numerical computations
- `mediapipe` - Hand detection
- `ai-edge-litert` - TensorFlow Lite inference

## Integration

This backend is designed to work with the Flutter frontend application, but can be integrated with any client that can send HTTP requests with image files.

### Example Integration (Python)

```python
import requests

def predict_gesture(image_path):
    with open(image_path, 'rb') as f:
        files = {'file': f}
        response = requests.post('http://localhost:8000/predict', files=files)
        return response.json()

result = predict_gesture('hand_image.jpg')
print(f"Gesture: {result['prediction']}, Confidence: {result['confidence']}")
```
