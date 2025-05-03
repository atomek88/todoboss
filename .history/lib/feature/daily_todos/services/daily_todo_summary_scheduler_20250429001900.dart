import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todoApp/feature/todos/providers/todo_goal_provider.dart';
import '../providers/daily_todo_summary_providers.dart';
import '../../todos/providers/todos_provider.dart';
import '../providers/daily_todos_provider.dart';

/// Service to schedule daily summary generation at midnight
class DailySummaryScheduler {
  // Singleton instance
  static final DailySummaryScheduler _instance =
      DailySummaryScheduler._internal();
  factory DailySummaryScheduler() => _instance;
  DailySummaryScheduler._internal();

  Timer? _midnightTimer;
  bool _isInitialized = false;

  /// Initialize the scheduler
  void initialize(WidgetRef ref) {
    if (_isInitialized) return;

    _isInitialized = true;
    _scheduleMidnightTask(ref);

    // Also run immediately if it's the first time today
    _checkAndRunDailySummary(ref);
  }

  /// Schedule the next midnight task
  void _scheduleMidnightTask(WidgetRef ref) {
    // Cancel any existing timer
    _midnightTimer?.cancel();

    // Calculate time until next midnight
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    final timeUntilMidnight = nextMidnight.difference(now);

    debugPrint(
        'Scheduling next daily summary in ${timeUntilMidnight.inHours} hours and ${timeUntilMidnight.inMinutes % 60} minutes');

    // Schedule the timer
    _midnightTimer = Timer(timeUntilMidnight, () {
      _generateDailySummary(ref);
      // Schedule the next midnight task
      _scheduleMidnightTask(ref);
    });
  }

  /// Check if we need to run a daily summary for today
  void _checkAndRunDailySummary(WidgetRef ref) async {
    try {
      final today = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
      );

      // Check if we already have a DailyTodo for today
      final existingDailyTodo =
          await ref.read(dailyTodoByDateProvider(today).future);

      if (existingDailyTodo == null) {
        // No DailyTodo exists for today, generate one
        _generateDailySummary(ref);
      }
    } catch (e) {
      debugPrint('Error checking for daily summary: $e');
    }
  }

  /// Generate a daily summary
  void _generateDailySummary(WidgetRef ref) async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      debugPrint('Generating daily summary at $now');

      // Get all todos
      final allTodos = ref.read(todoListProvider);

      // Process non-rollover todos that are still active
      final nonRolloverActiveTodos =
          allTodos.where((todo) => !todo.rollover && todo.status == 0).toList();

      // Mark these as deleted for the daily summary
      for (final todo in nonRolloverActiveTodos) {
        // Create a copy with status = 2 (deleted)
        final deletedTodo = todo.copyWith(
          status: 2,
          endedOn: now,
        );

        // Update the todo
        ref.read(todoListProvider.notifier).updateTodo(todo.id, deletedTodo);
      }

      // Use the repository directly to update DailyTodo
      final repository = ref.read(todoDateRepositoryProvider);

      // Get the updated todos after marking non-rollover todos as deleted
      final updatedTodos = ref.read(todoListProvider);

      // Get completed todos for today
      final completedToday = updatedTodos.where((todo) {
        if (todo.status != 1 || todo.endedOn == null) return false;
        final completedDate = DateTime(
            todo.endedOn!.year, todo.endedOn!.month, todo.endedOn!.day);
        return completedDate.year == today.year &&
            completedDate.month == today.month &&
            completedDate.day == today.day;
      }).toList();

      // Get deleted todos for today
      final deletedToday = updatedTodos.where((todo) {
        if (todo.status != 2 || todo.endedOn == null) return false;
        final deletedDate = DateTime(
            todo.endedOn!.year, todo.endedOn!.month, todo.endedOn!.day);
        return deletedDate.year == today.year &&
            deletedDate.month == today.month &&
            deletedDate.day == today.day;
      }).toList();

      // Get created todos for today
      final createdToday = updatedTodos.where((todo) {
        final createdDate = DateTime(
            todo.createdAt.year, todo.createdAt.month, todo.createdAt.day);
        return createdDate.year == today.year &&
            createdDate.month == today.month &&
            createdDate.day == today.day;
      }).toList();

      // Get the current todo goal
      final todoGoal = ref.read(todoGoalProvider);

      // Create or update the DailyTodo for today
      final allTodosForToday = [
        ...completedToday,
        ...deletedToday,
        ...createdToday
      ];

      // Get existing DailyTodo - we know this will always return a valid instance
      // since getDailyTodoForDate creates one if it doesn't exist
      final dailyTodo = await repository.getDailyTodoForDate(today);

      // Update the DailyTodo with all todos and the current goal
      final updatedDailyTodo = dailyTodo.copyWith(
        todos: allTodosForToday,
        taskGoal: todoGoal,
      );

      // Save the updated DailyTodo
      await repository.saveDailyTodo(updatedDailyTodo);

      debugPrint('Daily summary generated successfully');
    } catch (e) {
      debugPrint('Error generating daily summary: $e');
    }
  }

  /// Dispose the scheduler
  void dispose() {
    _midnightTimer?.cancel();
    _isInitialized = false;
  }
}

/// Provider for the DailySummaryScheduler
final dailySummarySchedulerProvider = Provider<DailySummaryScheduler>((ref) {
  final scheduler = DailySummaryScheduler();

  // We need to delay initialization until we have a WidgetRef
  // This will be done in the app's initState

  // Clean up on dispose
  ref.onDispose(() {
    scheduler.dispose();
  });

  return scheduler;
});
