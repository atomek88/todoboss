import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todoApp/feature/users/models/user_model.dart';

class UserRepository {
  static const String _userKey = 'user_data';

  // Save user to SharedPreferences
  Future<bool> saveUser(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = jsonEncode(user.toJson());
      return await prefs.setString(_userKey, userJson);
    } catch (e) {
      print('Error saving user: $e');
      return false;
    }
  }

  // Get user from SharedPreferences
  Future<UserModel?> getUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userKey);
      
      if (userJson == null) {
        return null;
      }
      
      final Map<String, dynamic> userData = jsonDecode(userJson);
      return UserModel.fromJson(userData);
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }

  // Delete user from SharedPreferences
  Future<bool> deleteUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_userKey);
    } catch (e) {
      print('Error deleting user: $e');
      return false;
    }
  }
}
