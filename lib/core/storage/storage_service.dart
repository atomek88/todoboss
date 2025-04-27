import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todoApp/core/globals.dart';

/// A service that handles data persistence with fallback mechanism
class StorageService {
  static bool _initialized = false;

  /// Initialize Hive
  static Future<void> initialize() async {
    if (!_initialized) {
      await Hive.initFlutter();
      _initialized = true;
      
      // Debug: Inspect Hive storage on app startup
      await debugInspectHiveStorage();
    }
  }
  
  /// Debug utility to inspect all Hive boxes and their contents
  static Future<void> debugInspectHiveStorage() async {
    try {
      talker.info('===== HIVE STORAGE DEBUG INSPECTION =====');
      
      // List all boxes by trying to open common box names
      final commonBoxNames = ['todos_box', 'users_box'];
      final availableBoxes = <String>[];
      
      for (final boxName in commonBoxNames) {
        try {
          if (await Hive.boxExists(boxName)) {
            availableBoxes.add(boxName);
          }
        } catch (e) {
          // Ignore errors when checking box existence
        }
      }
      
      talker.info('Available Hive boxes: ${availableBoxes.isEmpty ? "No boxes found" : availableBoxes.join(', ')}');
      
      // Inspect each box
      for (final boxName in availableBoxes) {
        final box = await Hive.openBox(boxName);
        talker.info('Box: $boxName - Contains ${box.keys.length} keys');
        
        // Log all keys and values in the box
        for (final key in box.keys) {
          final value = box.get(key);
          if (value is String) {
            // Try to parse as JSON for better display
            try {
              if (value.startsWith('[') && value.endsWith(']')) {
                // Handle JSON arrays
                final jsonArray = jsonDecode(value) as List;
                talker.debug('  Key: $key - JSON Array with ${jsonArray.length} items');
                
                // Show a sample of the array (first item if available)
                if (jsonArray.isNotEmpty) {
                  talker.debug('    Sample item: ${jsonArray.first}');
                  
                  // For todos, try to extract more meaningful information
                  if (boxName.contains('todo') && jsonArray.first is Map) {
                    final Map<String, dynamic> todoItem = jsonArray.first;
                    if (todoItem.containsKey('title')) {
                      talker.debug('    Todo title: ${todoItem['title']}');
                    }
                    if (todoItem.containsKey('status')) {
                      talker.debug('    Status: ${todoItem['status']}');
                    }
                  }
                }
              } else if (value.startsWith('{') && value.endsWith('}')) {
                // Handle JSON objects
                final jsonObject = jsonDecode(value) as Map<String, dynamic>;
                talker.debug('  Key: $key - JSON Object with ${jsonObject.keys.length} fields');
                
                // For user data, show more details
                if (boxName.contains('user') && jsonObject.containsKey('firstName')) {
                  talker.debug('    User: ${jsonObject['firstName']} ${jsonObject['lastName'] ?? ""}');
                }
              } else {
                talker.debug('  Key: $key - Value: $value');
              }
            } catch (e) {
              talker.debug('  Key: $key - Value: $value (Not valid JSON)');
            }
          } else {
            talker.debug('  Key: $key - Value: $value (Type: ${value?.runtimeType})'); 
          }
        }
        
        // Close the box when done
        await box.close();
      }
      
      // Also check SharedPreferences
      talker.info('Checking SharedPreferences...');
      final prefs = await SharedPreferences.getInstance();
      final prefKeys = prefs.getKeys();
      talker.info('SharedPreferences contains ${prefKeys.length} keys');
      
      for (final key in prefKeys) {
        if (prefs.containsKey(key)) {
          dynamic value;
          if (prefs.getString(key) != null) {
            value = prefs.getString(key);
            // Try to parse JSON
            try {
              final jsonData = jsonDecode(value);
              talker.debug('  Pref Key: $key - JSON Value: $jsonData');
              continue;
            } catch (_) {}
          } else if (prefs.getBool(key) != null) {
            value = prefs.getBool(key);
          } else if (prefs.getInt(key) != null) {
            value = prefs.getInt(key);
          } else if (prefs.getDouble(key) != null) {
            value = prefs.getDouble(key);
          } else if (prefs.getStringList(key) != null) {
            value = prefs.getStringList(key);
          }
          talker.debug('  Pref Key: $key - Value: $value');
        }
      }
      
      talker.info('===== END HIVE STORAGE INSPECTION =====');
    } catch (e, stack) {
      talker.error('Error inspecting Hive storage', e, stack);
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
      talker.error('[StorageService] Error saving data', e);
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
      talker.error('[StorageService] Error loading data', e);
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
      talker.error('[StorageService] Error deleting data', e);
      return false;
    }
  }
}

// Provider for StorageService
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});
