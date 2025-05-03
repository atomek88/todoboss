import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'dart:collection';
import 'package:todoApp/feature/todos/providers/daily_todos_provider.dart';
import '../models/daily_summary.dart';
import '../repositories/daily_summary_repository.dart';
import '../../todos/providers/todos_provider.dart';
import '../../todos/providers/todo_goal_provider.dart';
import '../../todos/repositories/daily_todos_repository.dart';
import '../../todos/models/daily_todos.dart';
import 'package:todoApp/core/storage/storage_service.dart';
import 'package:collection/collection.dart';

/// Repository provider
/// Provider for the DailySummaryRepository
final dailySummaryRepositoryProvider = Provider<DailySummaryRepository>((ref) {
  // Get the storage service from its provider
  final storageService = ref.watch(storageServiceProvider);
  return DailySummaryRepository(storageService);
});

/// Provider for all daily summaries
final allDailySummariesProvider =
    FutureProvider<List<DailySummary>>((ref) async {
  final repository = ref.watch(dailySummaryRepositoryProvider);
  return repository.getAllDailySummaries();
});

/// Provider for daily summaries in a specific date range
final dailySummariesInRangeProvider = FutureProvider.family<List<DailySummary>,
    ({DateTime startDate, DateTime endDate})>((ref, params) async {
  final repository = ref.watch(dailySummaryRepositoryProvider);
  return repository.getDailySummariesInRange(params.startDate, params.endDate);
});

/// Cache for storing converted summary objects to avoid redundant processing
final _summaryCache = HashMap<String, DailySummary>();

/// Key generator for caching - combines date and counts
String _getSummaryCacheKey(DailyTodo todoDate) {
  return '${todoDate.id}_${todoDate.completedTodosCount}_${todoDate.deletedTodosCount}_${todoDate.taskGoal}';
}

/// Provider for getting daily summaries from DailyTodo objects with caching
final todoDatesAsSummariesProvider =
    FutureProvider<List<DailySummary>>((ref) async {
  final stopwatch = Stopwatch()..start();

  // Listen to changes in the todo list to invalidate cache when needed
  ref.listen(todoListProvider, (previous, current) {
    if (previous != null && previous.length != current.length) {
      debugPrint(
          '🔄 [todoDatesAsSummariesProvider] Clearing cache due to todo list changes');
      _summaryCache.clear();
    }
  });

  // Get all DailyTodos using optimized batch loading
  final todoDateRepo = ref.watch(todoDateRepositoryProvider);
  final todoDates = await todoDateRepo.getAllDailyTodos();

  // Convert DailyTodos to DailySummary objects with cache utilization
  final summaries = todoDates.map((todoDate) {
    final cacheKey = _getSummaryCacheKey(todoDate);

    // Return cached value if available
    if (_summaryCache.containsKey(cacheKey)) {
      return _summaryCache[cacheKey]!;
    }

    // Create new summary and cache it
    final summary = createDailySummary(
      date: todoDate.date,
      todoCompletedCount: todoDate.completedTodosCount,
      todoDeletedCount: todoDate.deletedTodosCount,
      todoCreatedCount: todoDate.todoIds.length,
      todoGoal: todoDate.taskGoal,
      completedTodoIds: todoDate.todoIds
          .where((_) => todoDate.completedTodosCount > 0)
          .toList(),
      deletedTodoIds: todoDate.todoIds
          .where((_) => todoDate.deletedTodosCount > 0)
          .toList(),
    );

    // Store in cache
    _summaryCache[cacheKey] = summary;
    return summary;
  }).toList();

  // Sort by date (newest first) - use efficient sorting
  summaries.sort((a, b) => b.date.compareTo(a.date));

  stopwatch.stop();
  debugPrint(
      '⚡ [todoDatesAsSummariesProvider] Converted ${summaries.length} DailyTodos in ${stopwatch.elapsedMilliseconds}ms (cache: ${_summaryCache.length} items)');
  return summaries;
});

/// Provider for getting the first date with any todos
final firstDailyTodoProvider = FutureProvider<DateTime>((ref) async {
  // Get all DailyTodos
  final todoDateRepo = ref.watch(todoDateRepositoryProvider);
  final todoDates = await todoDateRepo.getAllDailyTodos();

  if (todoDates.isEmpty) {
    // If no data, return 8 weeks ago
    return DateTime.now().subtract(const Duration(days: 56));
  }

  // Find the earliest date
  final earliestDate =
      todoDates.map((td) => td.date).reduce((a, b) => a.isBefore(b) ? a : b);
  debugPrint(
      '📅 [firstDailyTodoProvider] Earliest date with todos: $earliestDate');
  return earliestDate;
});

/// Efficiently filtered provider for all summaries up to today
final allTodoSummariesProvider =
    FutureProvider<List<DailySummary>>((ref) async {
  final stopwatch = Stopwatch()..start();
  final summaries = await ref.watch(todoDatesAsSummariesProvider.future);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  // Use efficient where + toList for minimal copying
  final result = summaries.where((summary) {
    // Don't show future dates
    return !summary.date.isAfter(today);
  }).toList();

  stopwatch.stop();
  debugPrint(
      '⚡ [allTodoSummariesProvider] Filtered to ${result.length} items in ${stopwatch.elapsedMilliseconds}ms');
  return result;
});

/// Provider for grouping summaries by month for efficient rendering
final summariesByMonthProvider =
    FutureProvider<Map<String, List<DailySummary>>>((ref) async {
  final allSummaries = await ref.watch(allTodoSummariesProvider.future);

  // Group summaries by month using efficient groupBy function
  return groupBy(
      allSummaries,
      (DailySummary s) =>
          '${s.date.year}-${s.date.month.toString().padLeft(2, '0')}');
});

/// Legacy provider for compatibility - getting daily summaries for the last N weeks
final lastNWeeksSummariesProvider =
    FutureProvider.family<List<DailySummary>, int>(
  (ref, weeks) async {
    // Use the new provider for real data
    final allSummaries = await ref.watch(allTodoSummariesProvider.future);
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: weeks * 7));

    return allSummaries
        .where((summary) =>
            !summary.date.isBefore(startDate) && !summary.date.isAfter(now))
        .toList();
  },
);

/// Provider for a daily summary by date
final dailySummaryByDateProvider =
    FutureProvider.family<DailySummary?, DateTime>((ref, date) async {
  final repository = ref.watch(dailySummaryRepositoryProvider);
  return repository.getDailySummaryForDate(date);
});

/// Notifier for generating daily summaries
class DailySummaryServiceNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref ref;

  DailySummaryServiceNotifier(this.ref) : super(const AsyncValue.data(null));

  /// Generate a summary for today
  Future<DailySummary> generateTodaySummary() async {
    state = const AsyncValue.loading();

    try {
      final repository = ref.read(dailySummaryRepositoryProvider);
      final todos = ref.read(todoListProvider);
      final todoGoal = ref.read(todoGoalProvider);

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Get completed todos for today
      final completedToday = todos.where((todo) {
        if (todo.status != 1 || todo.endedOn == null) return false;
        final completedDate = DateTime(
            todo.endedOn!.year, todo.endedOn!.month, todo.endedOn!.day);
        return completedDate.year == today.year &&
            completedDate.month == today.month &&
            completedDate.day == today.day;
      }).toList();

      // Get deleted todos for today
      final deletedToday = todos.where((todo) {
        if (todo.status != 2 || todo.endedOn == null) return false;
        final deletedDate = DateTime(
            todo.endedOn!.year, todo.endedOn!.month, todo.endedOn!.day);
        return deletedDate.year == today.year &&
            deletedDate.month == today.month &&
            deletedDate.day == today.day;
      }).toList();

      // Get created todos for today
      final createdToday = todos.where((todo) {
        final createdDate = DateTime(
            todo.createdAt.year, todo.createdAt.month, todo.createdAt.day);
        return createdDate.year == today.year &&
            createdDate.month == today.month &&
            createdDate.day == today.day;
      }).toList();

      // Generate and save the summary
      final summary = await repository.generateDailySummaryForDate(
        today,
        completedToday.map((todo) => todo.id).toList(),
        deletedToday.map((todo) => todo.id).toList(),
        createdToday.map((todo) => todo.id).toList(),
        todoGoal,
      );

      state = const AsyncValue.data(null);
      return summary;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  /// Generate summaries for the last N days
  Future<List<DailySummary>> generateHistoricalSummaries(int days) async {
    state = const AsyncValue.loading();

    try {
      final repository = ref.read(dailySummaryRepositoryProvider);
      final todos = ref.read(todoListProvider);
      final todoGoal = ref.read(todoGoalProvider);
      final now = DateTime.now();

      final summaries = <DailySummary>[];

      for (int i = 0; i < days; i++) {
        final date = now.subtract(Duration(days: i));
        final dayStart = DateTime(date.year, date.month, date.day);

        // Get completed todos for this day
        final completedOnDay = todos.where((todo) {
          if (todo.status != 1 || todo.endedOn == null) return false;
          final completedDate = DateTime(
              todo.endedOn!.year, todo.endedOn!.month, todo.endedOn!.day);
          return completedDate.year == dayStart.year &&
              completedDate.month == dayStart.month &&
              completedDate.day == dayStart.day;
        }).toList();

        // Get deleted todos for this day
        final deletedOnDay = todos.where((todo) {
          if (todo.status != 2 || todo.endedOn == null) return false;
          final deletedDate = DateTime(
              todo.endedOn!.year, todo.endedOn!.month, todo.endedOn!.day);
          return deletedDate.year == dayStart.year &&
              deletedDate.month == dayStart.month &&
              deletedDate.day == dayStart.day;
        }).toList();

        // Get created todos for this day
        final createdOnDay = todos.where((todo) {
          final createdDate = DateTime(
              todo.createdAt.year, todo.createdAt.month, todo.createdAt.day);
          return createdDate.year == dayStart.year &&
              createdDate.month == dayStart.month &&
              createdDate.day == dayStart.day;
        }).toList();

        // Only generate a summary if there's activity
        if (completedOnDay.isNotEmpty ||
            deletedOnDay.isNotEmpty ||
            createdOnDay.isNotEmpty) {
          final summary = await repository.generateDailySummaryForDate(
            dayStart,
            completedOnDay.map((todo) => todo.id).toList(),
            deletedOnDay.map((todo) => todo.id).toList(),
            createdOnDay.map((todo) => todo.id).toList(),
            todoGoal,
          );

          summaries.add(summary);
        }
      }

      state = const AsyncValue.data(null);
      return summaries;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
}
