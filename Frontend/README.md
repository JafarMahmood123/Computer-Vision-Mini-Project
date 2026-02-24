# ASL Hand Gesture Recognition Frontend

A real-time American Sign Language (ASL) hand gesture recognition mobile application built with Flutter. This frontend application captures live video from the device camera, sends frames to the backend server for processing, and displays real-time gesture predictions.

## Overview

The frontend is a Flutter mobile application that provides a user-friendly interface for ASL gesture recognition. It captures camera frames, sends them to the backend server for analysis, and displays the recognized gestures with confidence scores in real-time.

## Features

- **Real-time Camera Capture**: Live video feed from device camera
- **Gesture Recognition**: Real-time ASL alphabet detection
- **Confidence Display**: Shows prediction confidence percentage
- **Network Communication**: HTTP-based communication with backend
- **Cross-platform**: Works on iOS and Android devices
- **User-friendly Interface**: Clean, intuitive design with real-time feedback

## Architecture

### Core Components

1. **Camera Integration** (`camera` package)
   - Real-time video capture from device camera
   - Automatic camera initialization and management
   - Image capture for processing

2. **Network Communication** (`http` package)
   - HTTP POST requests to backend server
   - Multipart form data for image uploads
   - Error handling for network issues

3. **UI Components**
   - Live camera preview
   - Real-time prediction overlay
   - Confidence score display
   - Error status indicators

## Installation

### Prerequisites

- Flutter SDK (version 3.10.4 or later)
- Android Studio or Xcode (for platform-specific development)
- Physical device or emulator with camera support

### Setup

1. Clone the repository
2. Navigate to the Frontend directory
3. Install dependencies:

```bash
flutter pub get
```

4. Connect your device or start an emulator
5. Run the application:

```bash
flutter run
```

## Configuration

### Backend Server Configuration

The application needs to connect to the backend server. Update the `baseUrl` in `lib/main.dart`:

```dart
// CHANGE THIS TO YOUR UBUNTU IP ADDRESS
final String baseUrl = "http://192.168.98.50:8000/predict";
```

**Important Notes:**

- Replace the IP address with your backend server's IP
- Ensure both devices are on the same network
- Verify the backend server is running and accessible

### Camera Permissions

The app requires camera permissions. These are automatically handled by the Flutter camera package, but you may need to grant permissions manually on some devices.

## Usage

### Starting the Application

1. Ensure the backend server is running
2. Launch the Flutter application on your device
3. Grant camera permissions when prompted
4. The camera preview will appear with real-time gesture detection

### Interface Elements

- **Camera Preview**: Live video feed from device camera
- **Prediction Text**: Large display of recognized gesture (A-Z, del, space)
- **Confidence Score**: Percentage indicating prediction confidence
- **Error Messages**: Network or processing error indicators

### Real-time Processing

The application automatically:

1. Captures camera frames every 500ms
2. Sends images to the backend server
3. Displays predictions with confidence scores
4. Handles errors gracefully

## Performance

### Processing Speed

- **Frame Capture**: Every 500ms
- **Network Latency**: Depends on network conditions
- **Backend Processing**: ~500ms per frame
- **Total Response Time**: ~1-2 seconds

### Optimization Features

- **Frame Rate Control**: 500ms intervals prevent overwhelming the backend
- **Error Prevention**: Prevents duplicate requests during processing
- **Memory Management**: Proper camera controller disposal

## Supported Gestures

The application recognizes the same gestures as the backend:

- **Letters**: A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T, U, V, W, X, Y, Z
- **Special**: del (delete), space

## Troubleshooting

### Common Issues

1. **Camera Not Working**
   - Check camera permissions
   - Ensure camera hardware is functional
   - Restart the application

2. **Network Connection Errors**
   - Verify backend server is running
   - Check IP address configuration
   - Ensure both devices are on same network
   - Test network connectivity

3. **Low Recognition Accuracy**
   - Ensure good lighting conditions
   - Position hand clearly in camera frame
   - Remove background obstructions
   - Check camera focus

4. **Application Crashes**
   - Update Flutter SDK
   - Check device compatibility
   - Review error logs in console

### Debug Information

The application includes debug logging for:

- Network request/response details
- Camera initialization status
- Error conditions and stack traces

## Dependencies

### Core Dependencies

- `flutter` - Flutter framework
- `camera` (^0.10.5+9) - Camera integration
- `http` (^1.2.0) - HTTP client for backend communication

### Platform Support

- **Android**: Full camera and network support
- **iOS**: Full camera and network support
- **Web**: Limited camera support (not recommended)
- **Desktop**: Limited camera support (not recommended)

## Development

### Adding Features

1. **New UI Elements**: Modify the build method in `_ASLClientState`
2. **Processing Logic**: Update the `_captureAndSend` method
3. **Error Handling**: Enhance try-catch blocks and error responses
4. **Configuration**: Add settings screen for backend URL configuration

### Code Structure

```
lib/
├── main.dart          # Main application and ASLClient widget
└── [additional files] # Future feature implementations
```

### Testing

1. **Unit Tests**: Located in `test/` directory
2. **Integration Tests**: Manual testing with backend server
3. **Device Testing**: Test on multiple devices and OS versions

## Integration with Backend

### Communication Protocol

- **Method**: HTTP POST
- **Content-Type**: multipart/form-data
- **File Parameter**: `file` (image data)
- **Response Format**: JSON with prediction and confidence

### Example Request

```http
POST /predict HTTP/1.1
Content-Type: multipart/form-data; boundary=----WebKitFormBoundary7MA4YWxkTrZu0gW

------WebKitFormBoundary7MA4YWxkTrZu0gW
Content-Disposition: form-data; name="file"; filename="image.jpg"
Content-Type: image/jpeg

[Binary image data]
------WebKitFormBoundary7MA4YWxkTrZu0gW--
```

### Example Response

```json
{
  "prediction": "A",
  "confidence": 0.95
}
```

## Deployment

### Android

1. Generate signed APK or App Bundle
2. Configure signing keys
3. Update version numbers in `pubspec.yaml`
4. Build for release:

```bash
flutter build apk --release
# or
flutter build appbundle --release
```

### iOS

1. Configure code signing in Xcode
2. Set up App Store Connect
3. Build for release:

```bash
flutter build ios --release
```
