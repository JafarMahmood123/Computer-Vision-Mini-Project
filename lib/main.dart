import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

// Top-level functions for background processing
Uint8List _convertYUV420ToUint8RGB(CameraImage image) {
  final width = image.width;
  final height = image.height;
  final totalPixels = width * height;
  
  // Create flat buffer for RGB values in 0-255 range
  final buffer = Uint8List(totalPixels * 3);
  int bufferIndex = 0;

  final yBuffer = image.planes[0].bytes;
  final uBuffer = image.planes[1].bytes;
  final vBuffer = image.planes[2].bytes;

  for (var h = 0; h < height; h++) {
    for (var w = 0; w < width; w++) {
      final yIndex = h * width + w;
      final y = yBuffer[yIndex];

      final uvRowStart = (h ~/ 2) * width;
      final uvColStart = (w ~/ 2) * 2;
      final u = uBuffer[uvRowStart + uvColStart];
      final v = vBuffer[uvRowStart + uvColStart + 1];

      // YUV to RGB conversion
      final r = (y + 1.402 * (v - 128)).clamp(0, 255);
      final g = (y - 0.344 * (u - 128) - 0.714 * (v - 128)).clamp(0, 255);
      final b = (y + 1.772 * (u - 128)).clamp(0, 255);

      // Store in 0-255 range (not normalized yet)
      buffer[bufferIndex++] = r.toInt();
      buffer[bufferIndex++] = g.toInt();
      buffer[bufferIndex++] = b.toInt();
    }
  }

  return buffer;
}

Float32List _preprocessImageForInference(CameraImage image) {
  // Convert YUV420 to Uint8 RGB buffer
  final rgbBuffer = _convertYUV420ToUint8RGB(image);
  
  // Create image from buffer using Image 4.0+ API
  final decodedImage = img.Image.fromBytes(
    width: image.width,
    height: image.height,
    bytes: rgbBuffer.buffer,
    numChannels: 3,
  );
  
  // Resize image to model input size
  final resizedImage = img.copyResize(decodedImage, width: 224, height: 224);
  
  // Convert to normalized Float32List tensor format [224 * 224 * 3]
  return _imageToFloat32Tensor(resizedImage);
}

Float32List _imageToFloat32Tensor(img.Image image) {
  final totalPixels = image.width * image.height;
  
  // Create flat buffer for normalized RGB values
  final buffer = Float32List(totalPixels * 3);
  int bufferIndex = 0;

  // Use modern Image 4.0 iterator for cleaner, faster processing
  for (final pixel in image) {
    // Normalize to [0.0, 1.0] range for MobileNet and store in flat buffer
    buffer[bufferIndex++] = pixel.r / 255.0;
    buffer[bufferIndex++] = pixel.g / 255.0;
    buffer[bufferIndex++] = pixel.b / 255.0;
  }

  return buffer;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Get available cameras
  final cameras = await availableCameras();
  final firstCamera = cameras.first;
  
  runApp(ASLApp(camera: firstCamera));
}

class ASLApp extends StatelessWidget {
  final CameraDescription camera;
  
  const ASLApp({super.key, required this.camera});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ASL Detection',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: ASLDetectionScreen(camera: camera),
    );
  }
}

class ASLDetectionScreen extends StatefulWidget {
  final CameraDescription camera;
  
  const ASLDetectionScreen({super.key, required this.camera});

  @override
  State<ASLDetectionScreen> createState() => _ASLDetectionScreenState();
}

class _ASLDetectionScreenState extends State<ASLDetectionScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _isProcessing = false;
  String _predictedLabel = '';
  double _confidence = 0.0;
  DateTime _lastInferenceTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _loadModel();
    _loadLabels();
  }

  Future<void> _initializeCamera() async {
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.medium, // Changed from .high to .medium for better performance
    );

    _initializeControllerFuture = _controller.initialize();
    
    // Start listening for camera frames
    _controller.startImageStream((image) {
      _processCameraImage(image);
    });
  }

  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/asl_model.tflite');
      print("Model loaded successfully");
    } catch (e) {
      print("Error loading model: $e");
    }
  }

  Future<void> _loadLabels() async {
    try {
      final labelString = await DefaultAssetBundle.of(context)
          .loadString('assets/labels.txt');
      _labels = labelString.trim().split('\n');
      print("Loaded ${_labels.length} labels");
    } catch (e) {
      print("Error loading labels: $e");
    }
  }

  void _processCameraImage(CameraImage image) {
    // Throttle inference to every 500ms to maintain performance
    final now = DateTime.now();
    if (now.difference(_lastInferenceTime).inMilliseconds < 500) {
      return;
    }
    _lastInferenceTime = now;

    if (_isProcessing || _interpreter == null || _labels.isEmpty) {
      return;
    }

    _isProcessing = true;
    
    // Process image in a background isolate to avoid blocking UI
    compute(_preprocessImageForInference, image).then((inputBuffer) {
      _runInferenceWithFlatBuffer(inputBuffer).then((result) {
        // Only update UI if widget is still mounted
        if (mounted && result != null) {
          setState(() {
            _predictedLabel = result['label'];
            _confidence = result['confidence'];
          });
        }
      }).catchError((error) {
        print("Error during inference: $error");
      }).whenComplete(() {
        // Always reset processing flag
        _isProcessing = false;
      });
    }).catchError((error) {
      print("Error preprocessing image: $error");
      _isProcessing = false;
    });
  }

  Future<Map<String, dynamic>?> _runInferenceWithFlatBuffer(Float32List inputBuffer) async {
    try {
      // Create output tensor with proper shape for MobileNet
      final outputShape = _interpreter!.getOutputTensor(0).shape;
      final numClasses = outputShape[outputShape.length - 1];
      final output = List<List<double>>.generate(
        1,
        (batchIndex) => List<double>.generate(numClasses, (classIndex) => 0.0),
      );

      // Run inference with flat buffer
      _interpreter!.run(inputBuffer, output);

      // Find the class with highest probability
      double maxProb = 0.0;
      int maxIndex = 0;
      
      for (int i = 0; i < numClasses; i++) {
        if (output[0][i] > maxProb) {
          maxProb = output[0][i];
          maxIndex = i;
        }
      }

      // Map to label
      final label = maxIndex < _labels.length ? _labels[maxIndex] : 'Unknown';
      
      return {
        'label': label,
        'confidence': maxProb
      };
    } catch (e) {
      print("Error during inference: $e");
      return null;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _interpreter?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ASL Detection'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Stack(
        children: [
          FutureBuilder<void>(
            future: _initializeControllerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return CameraPreview(_controller);
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            },
          ),
          // Overlay for prediction results
          Positioned(
            bottom: 50,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Predicted Sign:',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _predictedLabel.isNotEmpty ? _predictedLabel : 'Waiting...',
                    style: TextStyle(
                      color: _predictedLabel.isNotEmpty ? Colors.white : Colors.white54,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_confidence > 0)
                    LinearProgressIndicator(
                      value: _confidence,
                      backgroundColor: Colors.white10,
                      color: Colors.green,
                    ),
                  if (_confidence > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Confidence: ${( _confidence * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Instructions
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white70,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Show your hand sign in the camera frame. Make sure your hand is well-lit and clearly visible.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}