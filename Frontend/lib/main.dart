import 'dart:async';
import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  runApp(
    MaterialApp(
      theme: ThemeData.dark(),
      home: ASLClient(camera: cameras[0]),
    ),
  );
}

class ASLClient extends StatefulWidget {
  final CameraDescription camera;
  const ASLClient({super.key, required this.camera});

  @override
  State<ASLClient> createState() => _ASLClientState();
}

class _ASLClientState extends State<ASLClient> {
  late CameraController _controller;
  String _prediction = "Connecting to Backend...";
  String _confidence = "0%";
  bool _isSending = false;
  Timer? _timer;

  // CHANGE THIS TO YOUR UBUNTU IP ADDRESS
  final String baseUrl = "http://192.168.98.50:8000/predict";

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    _controller.initialize().then((_) {
      if (!mounted) return;
      setState(() {});
      // Start the loop: capture and send every 500ms
      _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
        _captureAndSend();
      });
    });
  }

  Future<void> _captureAndSend() async {
    // Prevent sending a new request if the previous one hasn't finished
    if (_isSending || !_controller.value.isInitialized) return;

    _isSending = true;

    try {
      // 1. Take a picture (fastest way to get a JPG)
      final XFile image = await _controller.takePicture();

      // 2. Create Multipart Request
      var request = http.MultipartRequest('POST', Uri.parse(baseUrl));

      // 3. Add the image file
      request.files.add(await http.MultipartFile.fromPath('file', image.path));

      // 4. Send to Python Backend
      var response = await request.send();

      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var json = jsonDecode(responseData);

        setState(() {
          _prediction = json['prediction'];
          _confidence = "${(json['confidence'] * 100).toStringAsFixed(1)}%";
        });
      } else {
        setState(() => _prediction = "Server Error: ${response.statusCode}");
      }
    } catch (e) {
      setState(() => _prediction = "Check Network/IP");
      debugPrint("Error: $e");
    } finally {
      _isSending = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("ASL Real-time Detector")),
      body: Stack(
        children: [
          // Camera View
          SizedBox.expand(child: CameraPreview(_controller)),

          // Prediction Overlay
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.blueAccent, width: 2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _prediction,
                    style: const TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    "Confidence: $_confidence",
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.blueAccent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }
}
