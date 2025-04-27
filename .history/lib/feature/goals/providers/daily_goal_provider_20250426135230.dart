import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todoApp/feature/goals/models/daily_goal.dart';
import 'package:todoApp/feature/todos/providers/todo_goal_provider.dart';
import 'package:todoApp/shared/providers/selected_date_provider.dart';

/// Provider for the current day's goal
final currentDailyGoalProvider = Provider<DailyGoal>((ref) {
  final selectedDate = ref.watch(selectedDateProvider);
  final targetCount = ref.watch(todoGoalProvider);
  
  return DailyGoal.forDate(selectedDate, targetCount);
});

/// Provider to track daily goal achievements
final dailyGoalAchievementProvider = StateNotifierProvider<DailyGoalAchievementNotifier, Map<String, DailyGoal>>((ref) {
  return DailyGoalAchievementNotifier(ref);
});

/// Notifier for managing daily goal achievements
class DailyGoalAchievementNotifier extends StateNotifier<Map<String, DailyGoal>> {
  final Ref _ref;
  
  DailyGoalAchievementNotifier(this._ref) : super({});
  
  
  /// Get a key for storing the goal by date
  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month}-${date.day}';
  }
  
  /// Get the goal for a specific date
  DailyGoal getGoalForDate(DateTime date) {
    final key = _getDateKey(date);
    return state[key] ?? DailyGoal.forDate(date, _ref.read(todoGoalProvider));
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
final goalCelebrationProvider = Provider<bool>((ref) {
  final selectedDate = ref.watch(selectedDateProvider);
  final goalAchievements = ref.watch(dailyGoalAchievementProvider);
  
  // Get the key for the selected date
  final key = '${selectedDate.year}-${selectedDate.month}-${selectedDate.day}';
  final goal = goalAchievements[key];
  
  // Show celebration if the goal is achieved but celebration not yet shown
  return goal != null && goal.achieved && !goal.celebrationShown;
});
