# Computer Vision Mini Project: Real-time ASL Hand Gesture Recognition

A complete computer vision application that recognizes American Sign Language (ASL) hand gestures in real-time using machine learning. The project consists of a Python FastAPI backend for model inference and a Flutter mobile frontend for real-time camera capture and prediction display.

## 🎯 Project Overview

This application detects and classifies ASL hand gestures from live camera feed, providing real-time predictions with confidence scores. The system uses a combination of MediaPipe for hand landmark detection and a custom TensorFlow Lite model for gesture classification.

## 🚀 Features

- **Real-time Hand Gesture Recognition**: Live camera feed processing with continuous predictions
- **26 ASL Letters + Special Commands**: Recognizes all letters A-Z plus 'del' and 'space' gestures
- **High Accuracy**: Uses MediaPipe for robust hand detection and a custom-trained model for classification
- **Cross-platform Mobile App**: Flutter-based frontend that works on both iOS and Android
- **RESTful API Backend**: FastAPI server for model inference and prediction endpoints
- **Confidence Scoring**: Displays prediction confidence for better user feedback

## 🏗️ Architecture

```
┌─────────────────┐    HTTP POST    ┌─────────────────┐
│   Flutter App   │ ───────────────▶│   FastAPI       │
│   (Frontend)    │                 │   (Backend)     │
│                 │ ◀───────────────│                 │
│  Camera Feed    │    JSON Response │  Model Inference│
│  Live Preview   │                 │  Hand Detection │
│  Predictions    │                 │  Classification  │
└─────────────────┘                 └─────────────────┘
```

### Model Training Pipeline

The gesture recognition model is trained using a comprehensive pipeline:

1. **Data Collection**: ASL alphabet images from Kaggle dataset
2. **Landmark Extraction**: MediaPipe extracts 21 hand landmarks (63 coordinates)
3. **Model Training**: Neural network trained on landmark coordinates
4. **Model Conversion**: Converted to TensorFlow Lite for mobile deployment
5. **Evaluation**: Comprehensive metrics including F1-score and confusion matrix

### Backend Components

- **FastAPI Server**: REST API for handling image uploads and predictions
- **MediaPipe**: Hand landmark detection and tracking
- **TensorFlow Lite**: Lightweight model inference for gesture classification
- **OpenCV**: Image processing and manipulation
- **Model Training**: Jupyter notebook (`Backend/ASL.ipynb`) for training the gesture recognition model

### Model Training Details

The gesture recognition model is trained using the following process:

- **Dataset**: ASL alphabet images from Kaggle
- **Landmark Extraction**: MediaPipe extracts 21 hand landmarks (63 coordinates: x, y, z)
- **Model Architecture**: 3-layer neural network with BatchNormalization and Dropout
- **Training**: 100 epochs with early stopping and checkpointing
- **Evaluation**: Comprehensive metrics including F1-score, precision, and recall
- **Conversion**: Model converted to TensorFlow Lite format for mobile deployment

### Frontend Components

- **Flutter Framework**: Cross-platform mobile application
- **Camera Plugin**: Real-time camera capture and preview
- **HTTP Client**: Communication with backend API
- **Material Design**: Clean, intuitive user interface

## 📋 Supported Gestures

The system recognizes the following ASL gestures:

**Letters (A-Z):**

- A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T, U, V, W, X, Y, Z

**Special Commands:**

- `del` - Delete/backspace command
- `space` - Space character

## 🛠️ Installation & Setup

### Prerequisites

- **Python 3.8+** (for backend)
- **Flutter SDK** (for frontend)
- **Android Studio/Xcode** (for mobile development)
- **Camera access** on mobile device

### Model Training (Optional)

If you want to train or retrain the gesture recognition model:

1. **Install Jupyter and required packages:**

   ```bash
   pip install jupyter matplotlib seaborn
   ```

2. **Open the training notebook:**

   ```bash
   jupyter notebook Backend/ASL.ipynb
   ```

3. **Follow the notebook steps:**
   - Data collection from Kaggle ASL dataset
   - Landmark extraction using MediaPipe
   - Model training with TensorFlow
   - Model evaluation and conversion to TensorFlow Lite

4. **Download required files:**
   - You'll need a Kaggle API token (`kaggle.json`) for dataset access
   - The notebook will automatically download and process the ASL alphabet dataset

### Backend Setup

1. **Clone the repository:**

   ```bash
   git clone https://github.com/JafarMahmood123/computer-vision-mini-project.git
   cd computer-vision-mini-project/Backend
   ```

2. **Create virtual environment:**

   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

3. **Install dependencies:**

   ```bash
   pip install -r requirements.txt
   ```

4. **Download required models:**
   - Ensure `asl_landmark_model.tflite` is in the Backend directory
   - Ensure `labels.txt` contains the gesture labels
   - Download `hand_landmarker.task` from MediaPipe (optional, fallback available)

5. **Run the server:**

   ```bash
   python main.py
   ```

   The server will start on `http://0.0.0.0:8000`

### Frontend Setup

1. **Navigate to frontend directory:**

   ```bash
   cd ../Frontend
   ```

2. **Install dependencies:**

   ```bash
   flutter pub get
   ```

3. **Configure backend connection:**
   - Open `lib/main.dart`
   - Update the `baseUrl` variable with your backend server IP address:

   ```dart
   final String baseUrl = "http://YOUR_IP_ADDRESS:8000/predict";
   ```

4. **Run the application:**
   ```bash
   flutter run
   ```

## 📱 Usage

### Starting the Application

1. **Start the backend server:**

   ```bash
   cd Backend
   python main.py
   ```

2. **Connect your mobile device** to the same network as your backend server

3. **Update the IP address** in `Frontend/lib/main.dart` to match your backend server's IP

4. **Build and run the Flutter app:**
   ```bash
   cd Frontend
   flutter run
   ```

### Using the Application

1. **Grant camera permissions** when prompted
2. **Position your hand** within the camera frame
3. **Make ASL gestures** with your hand
4. **View predictions** in real-time at the bottom of the screen
5. **Check confidence scores** to see prediction reliability

### Troubleshooting

**Common Issues:**

- **"Check Network/IP"**: Verify backend server is running and IP address is correct
- **"No hand detected"**: Ensure good lighting and hand is clearly visible
- **Low confidence scores**: Make sure gestures are clear and well-formed
- **Camera not working**: Check device permissions and camera availability

**Network Configuration:**

- Ensure mobile device and backend server are on the same network
- Check firewall settings if connection fails
- Use your machine's local IP address (not localhost)

## 🔧 Technical Details

### Model Architecture

The system uses a two-stage approach:

1. **Hand Detection (MediaPipe):**
   - Detects hands in the camera frame
   - Extracts 21 hand landmarks (63 coordinates: x, y, z)
   - Provides robust hand tracking across different lighting conditions

2. **Gesture Classification (TensorFlow Lite):**
   - Takes normalized landmark coordinates as input
   - Uses a lightweight neural network for classification
   - Outputs probabilities for each gesture class

### Performance Optimizations

- **TensorFlow Lite**: Optimized for mobile inference
- **500ms capture interval**: Balances responsiveness with processing time
- **Async processing**: Non-blocking camera capture and API calls
- **Error handling**: Graceful degradation for network issues

### File Structure

```
Computer-Vision-Mini-Project/
├── Backend/
│   ├── main.py              # FastAPI server implementation
│   ├── requirements.txt     # Python dependencies
│   ├── asl_landmark_model.tflite  # TensorFlow Lite model
│   └── labels.txt           # Gesture class labels
└── Frontend/
    ├── lib/
    │   └── main.dart        # Flutter application entry point
    ├── pubspec.yaml         # Flutter dependencies
    ├── assets/              # Model files for mobile
    └── android/             # Android-specific configuration
```
