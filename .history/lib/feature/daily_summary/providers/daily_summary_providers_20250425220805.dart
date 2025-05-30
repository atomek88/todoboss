import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/daily_summary.dart';
import '../repositories/daily_summary_repository.dart';
import '../../todos/providers/todos_provider.dart';
import '../../todos/providers/todo_goal_provider.dart';
import '../../todos/models/todo.dart';

/// Repository provider
/// Provider for the DailySummaryRepository
final dailySummaryRepositoryProvider = Provider<DailySummaryRepository>((ref) {
  final repository = DailySummaryRepository();
  repository.initialize();
  return repository;
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

/// Provider for the last N weeks of summaries
final lastNWeeksSummariesProvider =
    FutureProvider.family<List<DailySummary>, ({int weeks})>(
        (ref, params) async {
  final repository = ref.watch(dailySummaryRepositoryProvider);
  return repository.getLastNWeeksSummaries(params.weeks);
});

/// Provider for a daily summary by date
final dailySummaryByDateProvider =
    FutureProvider.family<DailySummary?, DateTime>((ref, date) async {
  final repository = ref.watch(dailySummaryRepositoryProvider);
  return repository.getDailySummaryByDate(date);
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
}
