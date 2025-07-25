import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class FaceStorageService {
  static const String _usersKey = 'registered_users';

  Future<void> saveUser({
    required String name,
    required Map<String, dynamic> faceData,
    required List<String> imagePaths,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final users = await getAllUsers();

    final newUser = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'name': name,
      'faceData': faceData,
      'imagePaths': imagePaths,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    users.add(newUser);
    await prefs.setString(_usersKey, jsonEncode(users));
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_usersKey);

    if (usersJson == null) return [];

    final usersList = jsonDecode(usersJson) as List;
    return usersList.cast<Map<String, dynamic>>();
  }

  Future<void> deleteUser(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final users = await getAllUsers();

    users.removeWhere((user) => user['id'] == userId);
    await prefs.setString(_usersKey, jsonEncode(users));
  }

  Future<void> clearAllUsers() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_usersKey);
  }
}
