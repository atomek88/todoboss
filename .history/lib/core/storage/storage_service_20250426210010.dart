import 'dart:convert';

import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todoApp/core/globals.dart';
import 'package:todoApp/feature/daily_summary/models/daily_summary_isar.dart';
import 'package:todoApp/feature/todos/models/todo_isar.dart';

/// A service that handles data persistence with Isar database
class StorageService {
  static bool _initialized = false;
  static late Isar _isar;

  /// Get the Isar instance
  static Isar get isar {
    if (!_initialized) {
      throw Exception(
          'StorageService is not initialized. Call StorageService.initialize() first.');
    }
    return _isar;
  }

  /// Initialize Isar database
  static Future<void> initialize() async {
    if (!_initialized) {
      final dir = await getApplicationDocumentsDirectory();

      // Open Isar database with its collections
      _isar = await Isar.open(
        [TodoIsarSchema, DailySummaryIsarSchema],
        directory: dir.path,
      );
      _initialized = true;

      // Debug: Inspect Isar storage on app startup
      await debugInspectIsarStorage();
    }
  }

  /// Debug utility to inspect Isar database collections
  static Future<void> debugInspectIsarStorage() async {
    try {
      talker.info('===== ISAR STORAGE DEBUG INSPECTION =====');

      // Inspect Todos collection
      final todosCount = await _isar.collection<TodoIsar>().count();
      talker.info('Todos collection: $todosCount items');

      if (todosCount > 0) {
        // Show some sample todos
        final sampleTodos =
            await _isar.collection<TodoIsar>().where().limit(3).findAll();
        for (final todo in sampleTodos) {
          talker.debug(
              '  Todo: ${todo.title} (ID: ${todo.id}, UUID: ${todo.uuid}, Status: ${todo.status})');
        }
      }

      // Inspect DailySummary collection
      final summariesCount = await _isar.collection<DailySummaryIsar>().count();
      talker.info('Daily Summaries collection: $summariesCount items');

      if (summariesCount > 0) {
        // Show some sample summaries
        final sampleSummaries = await _isar
            .collection<DailySummaryIsar>()
            .where()
            .limit(3)
            .findAll();
        for (final summary in sampleSummaries) {
          talker.debug(
              '  Summary for ${summary.date}: ${summary.todoCompletedCount} completed, ${summary.todoDeletedCount} deleted');
        }
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

  /// Helper method to save custom JSON data
  /// This is a generic method for legacy support
  Future<bool> saveData({
    required String prefKey,
    required String jsonData,
  }) async {
    try {
      // Ensure Isar is initialized
      await StorageService.initialize();

      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(prefKey, jsonData);
    } catch (e) {
      talker.error('Error saving data: $e');
      return false;
    }
  }

  /// Load data with from SharedPreferences
  /// This is a generic method for legacy support
  Future<String?> loadData({
    required String prefKey,
  }) async {
    try {
      // Ensure Isar is initialized
      await StorageService.initialize();

      // Get from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(prefKey);
    } catch (e) {
      talker.error('Error loading data: $e');
      return null;
    }
  }

  /// Delete data from SharedPreferences
  /// This is a generic method for legacy support
  Future<bool> deleteData({
    required String prefKey,
  }) async {
    try {
      // Ensure Isar is initialized
      await StorageService.initialize();

      // Delete from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(prefKey);
    } catch (e) {
      talker.error('[StorageService] Error deleting data', e);
      return false;
    }
  }

  /// Put an object in SharedPreferences
  Future<bool> putObject(String key, Map<String, dynamic> value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(key, json.encode(value));
    } catch (e) {
      talker.error('Error storing object in SharedPreferences: $e');
      return false;
    }
  }

  /// Get an object from SharedPreferences
  Future<Map<String, dynamic>?> getObject(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getString(key);
      if (value != null) {
        return json.decode(value) as Map<String, dynamic>;
      }
    } catch (e) {
      talker.error('Error retrieving object from SharedPreferences: $e');
    }
    return null;
  }

  /// Remove an object from SharedPreferences
  Future<bool> removeObject(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(key);
    } catch (e) {
      talker.error('Error removing object from SharedPreferences: $e');
      return false;
    }
  }
}

// Provider for StorageService
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});
