import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:todoApp/feature/goals/models/daily_goal.dart';
import 'package:todoApp/feature/todos/providers/todo_goal_provider.dart';
import 'package:todoApp/core/providers/selected_date_provider.dart';

part 'daily_goal_provider.g.dart';

/// Provider for the current day's goal
@riverpod
DailyGoal currentDailyGoal(CurrentDailyGoalRef ref) {
  final selectedDate = ref.watch(selectedDateProvider);
  final targetCount = ref.watch(todoGoalProvider);

  return DailyGoal.forDate(selectedDate, targetCount);
}

/// Provider to track daily goal achievements
@riverpod
class DailyGoalAchievement extends _$DailyGoalAchievement {
  @override
  Map<String, DailyGoal> build() {
    return {};
  }

  /// Get a key for storing the goal by date
  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month}-${date.day}';
  }

  /// Get the goal for a specific date
  DailyGoal getGoalForDate(DateTime date) {
    final key = _getDateKey(date);
    return state[key] ?? DailyGoal.forDate(date, ref.read(todoGoalProvider));
  }

  /// Update the completed count for a date
  void updateCompletedCount(DateTime date, int completedCount) {
    final key = _getDateKey(date);
    final currentGoal = getGoalForDate(date);
    final updatedGoal = currentGoal.updateCompletedCount(completedCount);

    // Only update if there's a change
    if (updatedGoal != currentGoal) {
      state = {...state, key: updatedGoal};
    }
  }

  /// Mark the celebration as shown for a date
  void markCelebrationShown(DateTime date) {
    final key = _getDateKey(date);
    final currentGoal = getGoalForDate(date);

    if (currentGoal.achieved && !currentGoal.celebrationShown) {
      state = {...state, key: currentGoal.markCelebrationShown()};
    }
  }

  /// Check if a celebration should be shown for a date
  bool shouldShowCelebration(DateTime date) {
    final goal = getGoalForDate(date);
    return goal.achieved && !goal.celebrationShown;
  }
}

/// Provider for tracking if a celebration should be shown
@riverpod
bool goalCelebration(GoalCelebrationRef ref) {
  final selectedDate = ref.watch(selectedDateProvider);
  final goalAchievements = ref.watch(dailyGoalAchievementProvider);

  // Get the key for the selected date
  final key = '${selectedDate.year}-${selectedDate.month}-${selectedDate.day}';
  final goal = goalAchievements[key];

  // Show celebration if the goal is achieved but celebration not yet shown
  return goal != null && goal.achieved && !goal.celebrationShown;
}
