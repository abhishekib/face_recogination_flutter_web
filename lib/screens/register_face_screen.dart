import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../main.dart';
import '../services/face_storage_service.dart';
import '../services/face_detection_service.dart';

class RegisterFaceScreen extends StatefulWidget {
  const RegisterFaceScreen({Key? key}) : super(key: key);

  @override
  State<RegisterFaceScreen> createState() => _RegisterFaceScreenState();
}

class _RegisterFaceScreenState extends State<RegisterFaceScreen> {
  CameraController? _cameraController;
  final TextEditingController _nameController = TextEditingController();
  final FaceStorageService _storageService = FaceStorageService();
  final FaceDetectionService _faceDetectionService = FaceDetectionService();

  bool _isInitialized = false;
  bool _isCapturing = false;
  List<String> _capturedImages = [];
  String _status = 'Position your face in the camera';

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

    // Try to find front camera first (better for face registration)
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
          _status = 'Camera ready - Enter your name and capture photos';
        });
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
    });

    // Switch to the next camera
    _currentCameraIndex = (_currentCameraIndex + 1) % _availableCameras.length;
    await _setupCamera(_currentCameraIndex);
  }

  Future<void> _capturePhoto() async {
    if (!_isInitialized || _isCapturing) return;

    setState(() {
      _isCapturing = true;
      _status = 'Capturing photo...';
    });

    try {
      final image = await _cameraController!.takePicture();

      // Simulate face detection (in real app, you'd process the image)
      await Future.delayed(const Duration(milliseconds: 500));

      setState(() {
        _capturedImages.add(image.path);
        _status =
            'Photo ${_capturedImages.length} captured! ${_capturedImages.length < 3 ? 'Capture ${3 - _capturedImages.length} more' : 'Ready to register'}';
      });
    } catch (e) {
      setState(() {
        _status = 'Failed to capture photo: $e';
      });
    } finally {
      setState(() {
        _isCapturing = false;
      });
    }
  }

  Future<void> _registerUser() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name')),
      );
      return;
    }

    if (_capturedImages.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please capture at least 3 photos')),
      );
      return;
    }

    setState(() {
      _status = 'Processing and saving face data...';
    });

    try {
      // In a real app, you'd process the images to extract face embeddings
      // For MVP, we'll simulate this with dummy data
      final faceData =
          await _faceDetectionService.extractFaceEmbeddings(_capturedImages);

      await _storageService.saveUser(
        name: _nameController.text.trim(),
        faceData: faceData,
        imagePaths: _capturedImages,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Face registered successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _status = 'Registration failed: $e';
      });
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
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register Face'),
        backgroundColor: Colors.blue[600],
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
                ],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Your Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _status,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text('Photos: ${_capturedImages.length}/3'),
                      const SizedBox(width: 10),
                      ...List.generate(
                          3,
                          (index) => Container(
                                margin: const EdgeInsets.only(right: 4),
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: index < _capturedImages.length
                                      ? Colors.green
                                      : Colors.grey[300],
                                ),
                              )),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isInitialized &&
                                  !_isCapturing &&
                                  !_isSwitchingCamera
                              ? _capturePhoto
                              : null,
                          icon: _isCapturing
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.camera_alt),
                          label: Text(
                              _isCapturing ? 'Capturing...' : 'Capture Photo'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _capturedImages.length >= 3
                              ? _registerUser
                              : null,
                          icon: const Icon(Icons.save),
                          label: const Text('Register'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[600],
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
