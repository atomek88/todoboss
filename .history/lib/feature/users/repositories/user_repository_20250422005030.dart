import 'dart:convert';
import 'package:todoApp/core/globals.dart';
import 'package:todoApp/core/storage/storage_service.dart';
import 'package:todoApp/feature/users/models/user_model.dart';

class UserRepository {
  static const String _prefKey = 'user_data';
  static const String _hiveBoxName = 'users_box';
  static const String _hiveKey = 'user_data';

  final StorageService _storageService;

  UserRepository(this._storageService);

  // Save user to both SharedPreferences and Hive
  Future<bool> saveUser(UserModel user) async {
    try {
      final userJson = jsonEncode(user.toJson());
      return await _storageService.saveData(
        prefKey: _prefKey,
        hiveBoxName: _hiveBoxName,
        hiveKey: _hiveKey,
        jsonData: userJson,
      );
    } catch (e) {
      talker.error('[UserRepository] Error saving user', e);
      return false;
    }
  }

  // Get user with fallback mechanism
  Future<UserModel?> getUser() async {
    try {
      final jsonString = await _storageService.loadData(
        prefKey: _prefKey,
        hiveBoxName: _hiveBoxName,
        hiveKey: _hiveKey,
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

  // Delete user from both storage systems
  Future<bool> deleteUser() async {
    try {
      return await _storageService.deleteData(
        prefKey: _prefKey,
        hiveBoxName: _hiveBoxName,
        hiveKey: _hiveKey,
      );
    } catch (e) {
      talker.error('[UserRepository] Error deleting user', e);
      return false;
    }
  }
}
