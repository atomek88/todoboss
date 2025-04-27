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
  /// Isar database instance
  late Isar _isar;

  /// Whether the service has been initialized
  bool _isInitialized = false;

  /// Whether initialization is in progress
  bool _initializing = false;

  /// The shared instance future
  static Future<Isar>? _isarInstanceFuture;

  StorageService();

  /// Get Isar instance - returns a Future to ensure it's initialized
  Future<Isar> getIsar() async {
    if (_isInitialized) return _isar;

    if (_isarInstanceFuture != null) {
      _isar = await _isarInstanceFuture!;
      _isInitialized = true;
      return _isar;
    }

    return await _initializeIsar();
  }

  /// Access the Isar instance synchronously AFTER initialization
  /// This should ONLY be used when you're sure initialize() has been called
  Isar get isar {
    if (!_isInitialized) {
      throw Exception(
          'StorageService is not initialized. Call initialize() or getIsar() first.');
    }
    return _isar;
  }

  /// Initialize the Isar database
  Future<Isar> _initializeIsar() async {
    if (_isInitialized) return _isar;

    if (_initializing) {
      // Wait for the existing initialization to complete
      return await _isarInstanceFuture!;
    }

    try {
      _initializing = true;
      talker.debug('[StorageService] Initializing Isar database...');

      _isarInstanceFuture = _openIsarInstance();
      _isar = await _isarInstanceFuture!;

      _isInitialized = true;
      _initializing = false;
      talker.debug('[StorageService] Successfully initialized Isar database');
      return _isar;
    } catch (e) {
      _initializing = false;
      talker.error('[StorageService] Error initializing Isar database', e);
      rethrow;
    }
  }

  /// Open the Isar database instance
  Future<Isar> _openIsarInstance() async {
    final dir = await getApplicationDocumentsDirectory();

    final isar = await Isar.open(
      [TodoIsarSchema, DailySummaryIsarSchema],
      directory: dir.path,
    );

    await _debugInspectIsarStorage(isar);
    return isar;
  }

  /// Public method to initialize the service
  static Future<void> initialize() async {
    final service = StorageService();
    await service._initializeIsar();
  }

  /// Helper to inspect Isar storage on startup (debug only)
  Future<void> _debugInspectIsarStorage(Isar isar) async {
    try {
      final todoCount = await isar.todoIsars.count();
      final summaryCount = await isar.dailySummaryIsars.count();

      talker.debug('''[StorageService] Isar DB Inspection ✅
- Todos: $todoCount
- Summaries: $summaryCount''');
    } catch (e) {
      talker.error('[StorageService] Error inspecting Isar storage', e);
    }
  }

  /// Public method to ensure initialization is complete
  static Future<void> ensureInitialized() async {
    await initialize();
  }

  /// Helper method to save custom JSON data to SharedPreferences
  Future<bool> saveData({
    required String prefKey,
    required String jsonData,
  }) async {
    try {
      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(prefKey, jsonData);
      return true;
    } catch (e) {
      talker.error(
          '[StorageService] Error saving data to SharedPreferences', e);
      return false;
    }
  }

  /// Get a SharedPreferences instance
  Future<SharedPreferences> getSharedPreferences() async {
    return SharedPreferences.getInstance();
  }

  /// Get JSON data from SharedPreferences
  Future<String?> loadData({
    required String prefKey,
  }) async {
    try {
      // Try SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final prefData = prefs.getString(prefKey);
      return prefData;
    } catch (e) {
      talker.error(
          '[StorageService] Error loading data from SharedPreferences', e);
      return null;
    }
  }

  /// Delete data from SharedPreferences
  Future<bool> deleteData({
    required String prefKey,
  }) async {
    try {
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

/// Provider for the storage service
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

/// Provider for the initialized Isar instance
final isarProvider = FutureProvider<Isar>((ref) async {
  final storageService = ref.watch(storageServiceProvider);
  return await storageService.getIsar();
});
