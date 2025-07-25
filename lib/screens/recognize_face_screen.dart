import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../main.dart';
import '../services/face_storage_service.dart';
import '../services/face_detection_service.dart';

class RecognizeFaceScreen extends StatefulWidget {
  const RecognizeFaceScreen({Key? key}) : super(key: key);

  @override
  State<RecognizeFaceScreen> createState() => _RecognizeFaceScreenState();
}

class _RecognizeFaceScreenState extends State<RecognizeFaceScreen> {
  CameraController? _cameraController;
  final FaceStorageService _storageService = FaceStorageService();
  final FaceDetectionService _faceDetectionService = FaceDetectionService();

  bool _isInitialized = false;
  bool _isRecognizing = false;
  String _recognizedUser = '';
  String _status = 'Initializing camera...';
  double _confidence = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    if (cameras.isEmpty) {
      setState(() {
        _status = 'No cameras available';
      });
      return;
    }

    _cameraController = CameraController(
      cameras.first,
      ResolutionPreset.medium,
    );

    try {
      await _cameraController!.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _status = 'Look at the camera for recognition';
        });
        _startContinuousRecognition();
      }
    } catch (e) {
      setState(() {
        _status = 'Camera initialization failed: $e';
      });
    }
  }

  Future<void> _startContinuousRecognition() async {
    while (mounted && _isInitialized) {
      await Future.delayed(const Duration(milliseconds: 1500));
      if (!_isRecognizing && mounted) {
        _performRecognition();
      }
    }
  }

  Future<void> _performRecognition() async {
    if (!_isInitialized || _isRecognizing) return;

    setState(() {
      _isRecognizing = true;
      _status = 'Analyzing face...';
    });

    try {
      final image = await _cameraController!.takePicture();

      // Simulate face recognition processing
      await Future.delayed(const Duration(milliseconds: 800));

      final users = await _storageService.getAllUsers();
      if (users.isNotEmpty) {
        // Simulate recognition result (in real app, compare face embeddings)
        final recognitionResult = await _faceDetectionService.recognizeFace(
          image.path,
          users,
        );

        if (mounted) {
          setState(() {
            if (recognitionResult['confidence'] > 0.6) {
              _recognizedUser = recognitionResult['name'];
              _confidence = recognitionResult['confidence'];
              _status = 'Face recognized!';
            } else {
              _recognizedUser = '';
              _confidence = 0.0;
              _status = 'Face not recognized. Try positioning better.';
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _status = 'Recognition failed: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRecognizing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Face Recognition'),
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              color: Colors.black,
              child: Stack(
                children: [
                  if (_isInitialized)
                    CameraPreview(_cameraController!)
                  else
                    const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),

                  // Face detection overlay
                  if (_recognizedUser.isNotEmpty)
                    Positioned(
                      top: 50,
                      left: 0,
                      right: 0,
                      child: Container(
                        margin: const EdgeInsets.all(20),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: Colors.white,
                              size: 30,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Welcome, $_recognizedUser!',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Confidence: ${(_confidence * 100).toStringAsFixed(1)}%',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Processing indicator
                  if (_isRecognizing)
                    const Positioned(
                      bottom: 50,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  _status,
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _performRecognition,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Scan Again'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.home),
                        label: const Text('Back to Home'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[600],
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
