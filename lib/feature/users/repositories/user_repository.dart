import 'dart:convert';
import 'package:todoApp/core/globals.dart';
import 'package:todoApp/core/storage/storage_service.dart';
import 'package:todoApp/feature/users/models/user_model.dart';

class UserRepository {
  static const String _prefKey = 'user_data';

  final StorageService _storageService;

  UserRepository(this._storageService);

  /// Save user to SharedPreferences
  Future<bool> saveUser(UserModel user) async {
    try {
      final userJson = jsonEncode(user.toJson());
      return await _storageService.saveData(
        prefKey: _prefKey,
        jsonData: userJson,
      );
    } catch (e) {
      talker.error('[UserRepository] Error saving user', e);
      return false;
    }
  }

  /// Get user from SharedPreferences
  Future<UserModel?> getUser() async {
    try {
      final jsonString = await _storageService.loadData(
        prefKey: _prefKey,
      );

      if (jsonString == null) {
        return null;
      }

      final Map<String, dynamic> userData = jsonDecode(jsonString);
      return UserModel.fromJson(userData);
    } catch (e) {
      talker.error('[UserRepository] Error getting user', e);
      return null;
    }
  }

  /// Clear user data from storage
  Future<bool> clearUser() async {
    try {
      await _storageService.deleteData(
        prefKey: _prefKey,
      );
      return true;
    } catch (e) {
      talker.error('[UserRepository] Error clearing user data', e);
      return false;
    }
  }
}
