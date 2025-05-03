import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:todoApp/feature/daily_todos/providers/daily_todos_provider.dart';
import 'package:todoApp/feature/daily_todos/repository/daily_todos_repository.dart';
import 'package:todoApp/feature/daily_todos/models/daily_todo.dart';
import '../../todos/providers/todos_provider.dart';
import '../../todos/providers/todo_goal_provider.dart';
import 'package:todoApp/core/storage/storage_service.dart';
import 'package:collection/collection.dart';

/// Provider for getting the earliest date with a todo
final firstDailyTodoProvider = FutureProvider<DateTime>((ref) async {
  final allDailyTodos = await ref.watch(allDailyTodoSummariesProvider.future);

  if (allDailyTodos.isEmpty) {
    // Default to 30 days ago if no dailyTodos
    return DateTime.now().subtract(const Duration(days: 30));
  }

  // Sort by date (ascending) and return earliest date
  final sortedDailyTodos = allDailyTodos.toList()
    ..sort((a, b) => a.date.compareTo(b.date));

  return sortedDailyTodos.first.date;
});

/// Provider for all DailyTodos as summaries
final allDailyTodoSummariesProvider =
    FutureProvider<List<DailyTodo>>((ref) async {
  final repository = ref.watch(dailyTodoRepositoryProvider);
  return repository.getAllDailyTodos();
});

/// Provider for getting a DailyTodo by date
final dailyTodoByDateProvider =
    FutureProvider.family<DailyTodo?, DateTime>((ref, date) async {
  final repository = ref.watch(dailyTodoRepositoryProvider);
  try {
    // Use getDailyTodoForDate which returns a non-null value (creates if not exists)
    return await repository.getDailyTodoForDate(date);
  } catch (e) {
    // But we want to allow null in our provider for consistency
    return null;
  }
});

/// Provider for DailyTodos in a specific date range
final dailyTodoSummariesInRangeProvider = FutureProvider.family<List<DailyTodo>,
    ({DateTime startDate, DateTime endDate})>((ref, params) async {
  final repository = ref.watch(dailyTodoRepositoryProvider);
  final allDailyTodos = await repository.getAllDailyTodos();

  // Filter to the specified date range
  return allDailyTodos.where((dailyTodo) {
    return !dailyTodo.date.isBefore(params.startDate) &&
        !dailyTodo.date.isAfter(params.endDate);
  }).toList();
});

/// Provider for getting performance metrics mapped to dates
final dailyTodoPerformanceProvider =
    FutureProvider<Map<DateTime, Map<String, dynamic>>>((ref) async {
  final dailyTodos = await ref.watch(allDailyTodoSummariesProvider.future);
  final Map<DateTime, Map<String, dynamic>> result = {};

  for (final dailyTodo in dailyTodos) {
    result[dailyTodo.date] = {
      'completedCount': dailyTodo.completedTodosCount,
      'deletedCount': dailyTodo.deletedTodosCount,
      'goal': dailyTodo.taskGoal,
      'activeTodos': dailyTodo.activeTodos.length,
      'completionPercentage': dailyTodo.completionPercentage,
    };
  }

  return result;
});

/// Provider for getting filtered performance metrics (removes days with no activity)
final filteredDailyTodoPerformanceProvider =
    FutureProvider<Map<DateTime, Map<String, dynamic>>>((ref) async {
  final allMetrics = await ref.watch(dailyTodoPerformanceProvider.future);

  // Filter out days with no activity
  return Map.fromEntries(allMetrics.entries.where((entry) {
    final metrics = entry.value;
    return metrics['completedCount'] > 0 ||
        metrics['deletedCount'] > 0 ||
        metrics['activeTodos'] > 0;
  }));
});

/// Provider for getting streak metrics
final dailyTodoStreakProvider = FutureProvider<Map<String, int>>((ref) async {
  final dailyTodos = await ref.watch(allDailyTodoSummariesProvider.future);

  // Sort by date, latest first
  final sortedDailyTodos = dailyTodos.toList()
    ..sort((a, b) => b.date.compareTo(a.date));

  // Current streak
  int currentStreak = 0;
  // Longest streak ever recorded
  int longestStreak = 0;
  // Streak before current one (if there was a break)
  int previousStreak = 0;

  // Calculate current streak (consecutive days with completed todos)
  DateTime? lastDate;

  for (final dailyTodo in sortedDailyTodos) {
    // Skip future dates
    if (dailyTodo.date.isAfter(DateTime.now())) continue;

    if (dailyTodo.completedTodosCount > 0) {
      if (lastDate == null) {
        // First day with activity
        currentStreak = 1;
        lastDate = dailyTodo.date;
      } else {
        // Check if consecutive
        final difference = lastDate.difference(dailyTodo.date).inDays;
        if (difference == 1) {
          // Consecutive day
          currentStreak++;
          lastDate = dailyTodo.date;
        } else {
          // Streak broken
          break;
        }
      }
    } else {
      // No completed todos on this day, streak broken
      break;
    }
  }

  // Calculate longest streak
  int tempStreak = 0;
  lastDate = null;

  for (final dailyTodo in sortedDailyTodos) {
    if (dailyTodo.completedTodosCount > 0) {
      if (lastDate == null) {
        tempStreak = 1;
        lastDate = dailyTodo.date;
      } else {
        final difference = lastDate.difference(dailyTodo.date).inDays;
        if (difference == 1) {
          tempStreak++;
          lastDate = dailyTodo.date;
        } else {
          // Streak broken, check if it was the longest
          if (tempStreak > longestStreak) {
            longestStreak = tempStreak;
          }

          // If this is the first break after current streak, record it as previous
          if (previousStreak == 0 && tempStreak != currentStreak) {
            previousStreak = tempStreak;
          }

          // Start a new streak
          tempStreak = 1;
          lastDate = dailyTodo.date;
        }
      }
    } else {
      // Check if current tempStreak is longest before resetting
      if (tempStreak > longestStreak) {
        longestStreak = tempStreak;
      }

      // If this is the first break after current streak, record it as previous
      if (previousStreak == 0 && tempStreak != currentStreak) {
        previousStreak = tempStreak;
      }

      // Reset streak
      tempStreak = 0;
      lastDate = null;
    }
  }

  // Check one more time in case the longest streak was the last one processed
  if (tempStreak > longestStreak) {
    longestStreak = tempStreak;
  }

  return {
    'currentStreak': currentStreak,
    'longestStreak': longestStreak,
    'previousStreak': previousStreak,
  };
});

/// Notifier for generating daily todo summaries
class DailyTodoSummaryServiceNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  DailyTodoSummaryServiceNotifier(this._ref)
      : super(const AsyncValue.data(null));

  /// Generate a summary for today
  Future<void> generateTodaySummary() async {
    state = const AsyncValue.loading();

    try {
      final repository = _ref.read(dailyTodoRepositoryProvider);
      final todos = _ref.read(todoListProvider);
      final goal = _ref.read(todoGoalProvider);

      final today = DateTime.now();
      final result = await repository.updateDailyTodoCounters(
        today,
        todos,
        defaultGoal: goal,
      );

      if (result != null) {
        state = AsyncValue.data(null);
      } else {
        state = AsyncValue.error(
          'Failed to generate today\'s summary',
          StackTrace.current,
        );
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Generate summaries for the last N days
  Future<void> generateHistoricalSummaries(int days) async {
    state = const AsyncValue.loading();

    try {
      final repository = _ref.read(dailyTodoRepositoryProvider);
      final todos = _ref.read(todoListProvider);
      final goal = _ref.read(todoGoalProvider);

      final today = DateTime.now();
      final results = <DailyTodo>[];

      for (int i = 0; i < days; i++) {
        final date = today.subtract(Duration(days: i));
        final result = await repository.updateDailyTodoCounters(
          date,
          todos,
          defaultGoal: goal,
        );

        if (result != null) {
          results.add(result);
        }
      }

      state = AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

/// Provider for the daily todo summary service
final dailyTodoSummaryServiceProvider =
    StateNotifierProvider<DailyTodoSummaryServiceNotifier, AsyncValue<void>>(
  (ref) => DailyTodoSummaryServiceNotifier(ref),
);
