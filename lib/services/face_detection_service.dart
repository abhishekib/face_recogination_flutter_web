import 'dart:math';

class FaceDetectionService {
  // NEW: Simulate face detection - returns true if a face is detected in the image
  Future<bool> detectFace(String imagePath) async {
    // Simulate processing time
    await Future.delayed(const Duration(milliseconds: 300));

    // For MVP: Randomly simulate face detection with 85% success rate
    // In a real app, you'd use ML models like ML Kit or TensorFlow Lite
    final random = Random();
    return random.nextDouble() > 0.15; // 85% chance of detecting a face
  }

  // Simulate face embedding extraction
  Future<Map<String, dynamic>> extractFaceEmbeddings(
      List<String> imagePaths) async {
    // In a real app, this would process images and extract face features
    // For MVP, we'll create dummy embeddings
    await Future.delayed(const Duration(milliseconds: 1000));

    final random = Random();
    final embedding = List.generate(128, (index) => random.nextDouble());

    return {
      'embedding': embedding,
      'confidence': 0.95,
      'faceCount': imagePaths.length,
    };
  }

  // UPDATED: Simulate face recognition with proper face detection first
  Future<Map<String, dynamic>> recognizeFace(
    String imagePath,
    List<Map<String, dynamic>> registeredUsers,
  ) async {
    // In a real app, this would extract face embedding from the image
    // and compare it with stored embeddings
    await Future.delayed(const Duration(milliseconds: 500));

    // First check if a face is detected in the image
    final faceDetected = await detectFace(imagePath);
    if (!faceDetected) {
      return {
        'name': '',
        'confidence': 0.0,
        'userId': null,
      };
    }

    final random = Random();

    // Check if there are registered users
    if (registeredUsers.isEmpty) {
      return {
        'name': '',
        'confidence': 0.0,
        'userId': null,
      };
    }

    // Simulate more realistic recognition scenarios:
    // 60% chance: No match found (unknown person)
    // 30% chance: Good match found (registered user)
    // 10% chance: Weak match found (might be registered user but poor conditions)

    final scenario = random.nextDouble();

    if (scenario < 0.6) {
      // No match - unknown person detected
      return {
        'name': '',
        'confidence': random.nextDouble() * 0.4, // Low confidence (0.0-0.4)
        'userId': null,
      };
    } else if (scenario < 0.9) {
      // Good match - return a random registered user
      final recognizedUser =
          registeredUsers[random.nextInt(registeredUsers.length)];
      return {
        'name': recognizedUser['name'],
        'confidence':
            0.75 + random.nextDouble() * 0.25, // High confidence (0.75-1.0)
        'userId': recognizedUser['id'],
      };
    } else {
      // Weak match - might be a registered user but conditions are poor
      final recognizedUser =
          registeredUsers[random.nextInt(registeredUsers.length)];
      return {
        'name': recognizedUser['name'],
        'confidence':
            0.4 + random.nextDouble() * 0.35, // Medium confidence (0.4-0.75)
        'userId': recognizedUser['id'],
      };
    }
  }

  // Calculate similarity between face embeddings
  double _calculateSimilarity(
      List<double> embedding1, List<double> embedding2) {
    if (embedding1.length != embedding2.length) return 0.0;

    double dotProduct = 0.0;
    double norm1 = 0.0;
    double norm2 = 0.0;

    for (int i = 0; i < embedding1.length; i++) {
      dotProduct += embedding1[i] * embedding2[i];
      norm1 += embedding1[i] * embedding1[i];
      norm2 += embedding2[i] * embedding2[i];
    }

    norm1 = sqrt(norm1);
    norm2 = sqrt(norm2);

    if (norm1 == 0.0 || norm2 == 0.0) return 0.0;

    return dotProduct / (norm1 * norm2);
  }

  // NEW: Helper method for comparing face embeddings with threshold
  Future<Map<String, dynamic>> compareWithStoredEmbeddings(
      List<double> currentEmbedding, List<Map<String, dynamic>> registeredUsers,
      {double threshold = 0.75}) async {
    double bestSimilarity = 0.0;
    Map<String, dynamic>? bestMatch;

    for (final user in registeredUsers) {
      if (user['faceData'] != null && user['faceData']['embedding'] != null) {
        final storedEmbedding = user['faceData']['embedding'] as List<double>;
        final similarity =
            _calculateSimilarity(currentEmbedding, storedEmbedding);

        if (similarity > bestSimilarity) {
          bestSimilarity = similarity;
          bestMatch = user;
        }
      }
    }

    if (bestSimilarity >= threshold && bestMatch != null) {
      return {
        'name': bestMatch['name'],
        'confidence': bestSimilarity,
        'userId': bestMatch['id'],
      };
    }

    return {
      'name': '',
      'confidence': bestSimilarity,
      'userId': null,
    };
  }
}
