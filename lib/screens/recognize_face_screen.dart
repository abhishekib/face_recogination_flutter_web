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

  // Camera switching variables
  int _currentCameraIndex = 0;
  List<CameraDescription> _availableCameras = [];
  bool _isSwitchingCamera = false;

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

    _availableCameras = cameras;

    // Try to find front camera first (better for face recognition)
    _currentCameraIndex = _availableCameras.indexWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
    );

    // If no front camera found, use the first available camera
    if (_currentCameraIndex == -1) {
      _currentCameraIndex = 0;
    }

    await _setupCamera(_currentCameraIndex);
  }

  Future<void> _setupCamera(int cameraIndex) async {
    // Dispose of the previous controller
    await _cameraController?.dispose();

    _cameraController = CameraController(
      _availableCameras[cameraIndex],
      ResolutionPreset.medium,
    );

    try {
      await _cameraController!.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _isSwitchingCamera = false;
          _status = 'Look at the camera for recognition';
        });
        _startContinuousRecognition();
      }
    } catch (e) {
      setState(() {
        _status = 'Camera initialization failed: $e';
        _isInitialized = false;
        _isSwitchingCamera = false;
      });
    }
  }

  Future<void> _switchCamera() async {
    if (_availableCameras.length <= 1 || _isSwitchingCamera) return;

    setState(() {
      _isSwitchingCamera = true;
      _isInitialized = false;
      _status = 'Switching camera...';
      _recognizedUser = ''; // Clear previous recognition
      _confidence = 0.0;
    });

    // Switch to the next camera
    _currentCameraIndex = (_currentCameraIndex + 1) % _availableCameras.length;
    await _setupCamera(_currentCameraIndex);
  }

  Future<void> _startContinuousRecognition() async {
    while (mounted && _isInitialized && !_isSwitchingCamera) {
      await Future.delayed(const Duration(milliseconds: 1500));
      if (!_isRecognizing && mounted && !_isSwitchingCamera) {
        _performRecognition();
      }
    }
  }

  Future<void> _performRecognition() async {
    if (!_isInitialized || _isRecognizing || _isSwitchingCamera) return;

    setState(() {
      _isRecognizing = true;
      _status = 'Analyzing face...';
    });

    try {
      final image = await _cameraController!.takePicture();

      // Simulate face recognition processing
      await Future.delayed(const Duration(milliseconds: 800));

      // Check if still mounted and not switching camera
      if (!mounted || _isSwitchingCamera) return;

      final users = await _storageService.getAllUsers();
      if (users.isNotEmpty) {
        // Simulate recognition result (in real app, compare face embeddings)
        final recognitionResult = await _faceDetectionService.recognizeFace(
          image.path,
          users,
        );

        if (mounted && !_isSwitchingCamera) {
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
      if (mounted && !_isSwitchingCamera) {
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

  String _getCameraInfo() {
    if (_availableCameras.isEmpty ||
        _currentCameraIndex >= _availableCameras.length) {
      return '';
    }

    final camera = _availableCameras[_currentCameraIndex];
    return camera.lensDirection == CameraLensDirection.front
        ? 'Front Camera'
        : 'Back Camera';
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
        actions: [
          // Camera info
          if (_availableCameras.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Text(
                  _getCameraInfo(),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
        ],
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
                  // Camera preview
                  if (_isInitialized && !_isSwitchingCamera)
                    CameraPreview(_cameraController!)
                  else
                    const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),

                  // Camera switch button (positioned over the camera preview)
                  if (_availableCameras.length > 1)
                    Positioned(
                      top: 16,
                      right: 16,
                      child: FloatingActionButton(
                        mini: true,
                        onPressed: _isSwitchingCamera ? null : _switchCamera,
                        backgroundColor: Colors.black.withOpacity(0.6),
                        child: _isSwitchingCamera
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.flip_camera_ios,
                                color: Colors.white,
                              ),
                      ),
                    ),

                  // Face detection overlay
                  if (_recognizedUser.isNotEmpty && !_isSwitchingCamera)
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
                        onPressed: _isInitialized && !_isSwitchingCamera
                            ? _performRecognition
                            : null,
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
