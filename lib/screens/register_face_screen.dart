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
          _status = 'Camera ready - Enter your name and capture photos';
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Camera initialization failed: $e';
      });
    }
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
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              color: Colors.black,
              child: _isInitialized
                  ? CameraPreview(_cameraController!)
                  : const Center(
                      child: CircularProgressIndicator(color: Colors.white),
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
                          onPressed: _isInitialized && !_isCapturing
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
