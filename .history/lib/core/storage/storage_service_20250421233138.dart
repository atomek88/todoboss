import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A service that handles data persistence with fallback mechanism
class StorageService {
  static bool _initialized = false;

  /// Initialize Hive
  static Future<void> initialize() async {
    if (!_initialized) {
      await Hive.initFlutter();
      _initialized = true;
    }
  }

  /// Save data with SharedPreferences and Hive fallback
  Future<bool> saveData({
    required String prefKey,
    required String hiveBoxName,
    required String hiveKey,
    required String jsonData,
  }) async {
    try {
      // Ensure Hive is initialized
      await StorageService.initialize();

      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final prefResult = await prefs.setString(prefKey, jsonData);

      // Save to Hive as backup
      final box = await Hive.openBox(hiveBoxName);
      await box.put(hiveKey, jsonData);
      await box.close();

      return prefResult;
    } catch (e) {
      print('Error saving data: $e');
      return false;
    }
  }

  /// Load data with fallback mechanism
  Future<String?> loadData({
    required String prefKey,
    required String hiveBoxName,
    required String hiveKey,
  }) async {
    try {
      // Ensure Hive is initialized
      await StorageService.initialize();

      // Try SharedPreferences first
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(prefKey);

      if (jsonString != null) {
        return jsonString;
      }

      // If not in SharedPreferences, try Hive
      final box = await Hive.openBox(hiveBoxName);
      final backupJsonString = box.get(hiveKey) as String?;
      await box.close();

      if (backupJsonString != null) {
        // Also restore to SharedPreferences for next time
        await prefs.setString(prefKey, backupJsonString);
        return backupJsonString;
      }

      // Data not found anywhere
      return null;
    } catch (e) {
      print('Error loading data: $e');
      return null;
    }
  }

  /// Delete data from both storage systems
  Future<bool> deleteData({
    required String prefKey,
    required String hiveBoxName,
    required String hiveKey,
  }) async {
    try {
      // Ensure Hive is initialized
      await StorageService.initialize();

      // Delete from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final prefResult = await prefs.remove(prefKey);

      // Delete from Hive
      final box = await Hive.openBox(hiveBoxName);
      await box.delete(hiveKey);
      await box.close();

      return prefResult;
    } catch (e) {
      print('Error deleting data: $e');
      return false;
    }
  }
}

// Provider for StorageService
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});
