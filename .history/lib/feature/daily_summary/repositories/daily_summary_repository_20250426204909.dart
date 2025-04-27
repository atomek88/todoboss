import 'package:flutter/foundation.dart';
import 'package:todoApp/feature/daily_summary/models/daily_summary.dart';
import 'dart:async';

/// Repository for managing DailySummary data with Hive local storage
class DailySummaryRepository {
  static const String _boxName = 'daily_summaries';
  Box<Map<dynamic, dynamic>>? _box;
  final Completer<void> _initCompleter = Completer<void>();

  DailySummaryRepository() {
    _initializeBox();
  }

  /// Initialize Hive and register adapters
  Future<void> _initializeBox() async {
    try {
      await Hive.initFlutter();
      _box = await Hive.openBox<Map<dynamic, dynamic>>(_boxName);
      _initCompleter.complete();
    } catch (e) {
      debugPrint('Error initializing Hive box: $e');
      _initCompleter.completeError(e);
    }
  }

  /// Get the box, ensuring it's initialized
  Future<Map<dynamic, dynamic>> _getBox() async {
    if (_box != null) {
      return _box!;
    }

    await _initCompleter.future;
    if (_box == null) {
      throw Exception('Box initialization failed');
    }
    return _box!;
  }

  /// Get all daily summaries
  Future<List<DailySummary>> getAllDailySummaries() async {
    try {
      final box = await _getBox();
      final maps = box.values.toList();
      return maps
          .map((map) => DailySummary.fromJson(Map<String, dynamic>.from(map)))
          .toList();
    } catch (e) {
      debugPrint('Error getting all daily summaries: $e');
      return [];
    }
  }

  /// Get daily summaries for a specific date range
  Future<List<DailySummary>> getDailySummariesInRange(
      DateTime startDate, DateTime endDate) async {
    try {
      // Normalize dates to midnight
      final normalizedStartDate =
          DateTime(startDate.year, startDate.month, startDate.day);
      final normalizedEndDate =
          DateTime(endDate.year, endDate.month, endDate.day);

      final allSummaries = await getAllDailySummaries();
      return allSummaries.where((summary) {
        final summaryDate =
            DateTime(summary.date.year, summary.date.month, summary.date.day);
        return summaryDate.isAtSameMomentAs(normalizedStartDate) ||
            summaryDate.isAtSameMomentAs(normalizedEndDate) ||
            (summaryDate.isAfter(normalizedStartDate) &&
                summaryDate.isBefore(normalizedEndDate));
      }).toList();
    } catch (e) {
      debugPrint('Error getting daily summaries in range: $e');
      return [];
    }
  }

  /// Get daily summaries for the last N weeks
  Future<List<DailySummary>> getLastNWeeksSummaries(int weeks) async {
    try {
      final today = DateTime.now();
      final startDate = today.subtract(Duration(days: weeks * 7));
      return getDailySummariesInRange(startDate, today);
    } catch (e) {
      debugPrint('Error getting last N weeks summaries: $e');
      return [];
    }
  }

  /// Get a daily summary by date
  Future<DailySummary?> getDailySummaryByDate(DateTime date) async {
    try {
      final box = await _getBox();

      // Normalize date to midnight
      final normalizedDate = DateTime(date.year, date.month, date.day);

      // Find summary with matching date
      final summaries = box.values.cast<Map<dynamic, dynamic>>();
      final matchingSummary = summaries.where((summary) {
        final summaryDate = DateTime.parse(summary['date'] as String);
        return summaryDate.year == normalizedDate.year &&
            summaryDate.month == normalizedDate.month &&
            summaryDate.day == normalizedDate.day;
      }).toList();

      if (matchingSummary.isNotEmpty) {
        return DailySummary.fromJson(
            Map<String, dynamic>.from(matchingSummary.first));
      }

      return null;
    } catch (e) {
      debugPrint('Error getting daily summary by date: $e');
      return null;
    }
  }

  /// Save a daily summary
  Future<void> saveDailySummary(DailySummary summary) async {
    try {
      final box = await _getBox();
      await box.put(summary.id, summary.toJson());
    } catch (e) {
      debugPrint('Error saving daily summary: $e');
    }
  }

  /// Delete a daily summary
  Future<void> deleteDailySummary(String id) async {
    try {
      final box = await _getBox();
      await box.delete(id);
    } catch (e) {
      debugPrint('Error deleting daily summary: $e');
    }
  }

  /// Generate daily summary for a specific date
  Future<DailySummary> generateDailySummaryForDate(
    DateTime date,
    List<String> completedTodoIds,
    List<String> deletedTodoIds,
    List<String> createdTodoIds,
    int todoGoal,
  ) async {
    // Check if a summary already exists for this date
    final existingSummary = await getDailySummaryByDate(date);

    // If it exists, update it with new values
    if (existingSummary != null) {
      final updatedSummary = existingSummary.copyWith(
        todoCompletedCount: completedTodoIds.length,
        todoDeletedCount: deletedTodoIds.length,
        todoCreatedCount: createdTodoIds.length,
        todoGoal: todoGoal,
        completedTodoIds: completedTodoIds,
        deletedTodoIds: deletedTodoIds,
        createdTodoIds: createdTodoIds,
      );
      await saveDailySummary(updatedSummary);
      return updatedSummary;
    }

    // Create a new summary if it doesn't exist
    final newSummary = createDailySummary(
      date: date,
      todoCompletedCount: completedTodoIds.length,
      todoDeletedCount: deletedTodoIds.length,
      todoCreatedCount: createdTodoIds.length,
      todoGoal: todoGoal,
      completedTodoIds: completedTodoIds,
      deletedTodoIds: deletedTodoIds,
      createdTodoIds: createdTodoIds,
    );

    // Save the summary
    await saveDailySummary(newSummary);

    return newSummary;
  }
}
