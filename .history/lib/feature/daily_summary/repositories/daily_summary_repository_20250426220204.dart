import 'package:flutter/foundation.dart';
import 'package:todoApp/core/globals.dart';
import 'package:todoApp/core/storage/storage_service.dart';
import 'package:todoApp/feature/daily_summary/models/daily_summary.dart';
import 'package:todoApp/feature/daily_summary/models/daily_summary_isar.dart';
import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';

/// Repository for managing DailySummary data with Isar local storage
class DailySummaryRepository {
  late final Isar _isar;
  final StorageService _storageService;
  final _initCompleter = Completer<void>();
  bool _isInitialized = false;

  DailySummaryRepository(this._storageService) {
    _initialize();
  }

  /// Initialize Isar and ensure the instance is ready for access
  Future<void> _initialize() async {
    try {
      if (_isInitialized) return;
      // Get the Isar instance from StorageService
      _isar = await _storageService.getIsar();
      _isInitialized = true;
      _initCompleter.complete();
    } catch (e) {
      talker.error('[DailySummaryRepository] Error initializing: $e');
      _initCompleter.completeError(e);
    }
  }

  /// Wait for initialization to complete
  Future<void> get initialized => _initCompleter.future;

  /// Ensures the repository is initialized before performing operations
  Future<void> _ensureInitialized() async {
    await initialized;
  }

  /// Get all daily summaries
  Future<List<DailySummary>> getAllDailySummaries() async {
    await initialized;

    try {
      // Query all from Isar
      final summaryIsars =
          await _isar.collection<DailySummaryIsar>().where().findAll();

      return summaryIsars
          .map((summary) => summary.toDomain())
          .toList()
          .cast<DailySummary>();
    } catch (e) {
      talker.error('[DailySummaryRepository] Error getting all summaries', e);
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

  /// Get summary by date, with ability to create if non-existent
  Future<DailySummary?> getDailySummaryForDate(DateTime date,
      {bool createIfNotExists = false}) async {
    await initialized;

    try {
      final normalizedDate = DateTime(date.year, date.month, date.day);

      // Query for the summary with this date
      final summaryIsar = await _isar
          .collection<DailySummaryIsar>()
          .filter()
          .dateEqualTo(normalizedDate)
          .findFirst();

      if (summaryIsar != null) {
        return summaryIsar.toDomain();
      }

      // If we're here, summary doesn't exist
      if (createIfNotExists) {
        final newSummary = DailySummary(
          id: const Uuid().v4(),
          date: normalizedDate,
          todoCompletedCount: 0,
          todoDeletedCount: 0,
          todoCreatedCount: 0,
          todoGoal: 0,
          completedTodoIds: [],
          deletedTodoIds: [],
          createdTodoIds: [],
        );

        await saveDailySummary(newSummary);
        return newSummary;
      }

      return null;
    } catch (e) {
      talker.error(
          '[DailySummaryRepository] Error getting daily summary by date: $e');
      return null;
    }
  }

  /// Save a daily summary
  Future<bool> saveDailySummary(DailySummary summary) async {
    await initialized;

    try {
      final summaryIsar = DailySummaryIsar.fromDomain(summary);

      // Check if summary exists for this date
      final existingSummary = await _isar
          .collection<DailySummaryIsar>()
          .filter()
          .dateEqualTo(summary.date)
          .findFirst();

      if (existingSummary != null) {
        // If exists, preserve the Isar ID
        summaryIsar.id = existingSummary.id;
      }

      // Use a transaction to save the summary
      await _isar.writeTxn(() async {
        await _isar.collection<DailySummaryIsar>().put(summaryIsar);
      });

      return true;
    } catch (e) {
      talker.error(
          '[DailySummaryRepository] Error saving summary for date ${summary.date.toIso8601String()}',
          e);
      return false;
    }
  }

  /// Delete a daily summary
  Future<bool> deleteDailySummary(String id) async {
    await initialized;

    try {
      // Find by UUID first to get the Isar ID
      final summaryIsar = await _isar
          .collection<DailySummaryIsar>()
          .filter()
          .uuidEqualTo(id)
          .findFirst();

      if (summaryIsar != null) {
        await _isar.writeTxn(() async {
          await _isar.collection<DailySummaryIsar>().delete(summaryIsar.id);
        });
        return true;
      }
      return false;
    } catch (e) {
      talker.error('[DailySummaryRepository] Error deleting daily summary: $e');
      return false;
    }
  }

  /// Save multiple daily summaries
  Future<bool> saveDailySummaries(List<DailySummary> summaries) async {
    await initialized;

    await _ensureInitialized();
    try {
      final summaryIsars = summaries.map(DailySummaryIsar.fromDomain).toList();

      await _isar.writeTxn(() async {
        await _isar.collection<DailySummaryIsar>().putAll(summaryIsars);
      });

      return true;
    } catch (e) {
      talker.error(
          '[DailySummaryRepository] Error saving multiple daily summaries: $e');
      return false;
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
    final existingSummary = await getDailySummaryForDate(date);

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
