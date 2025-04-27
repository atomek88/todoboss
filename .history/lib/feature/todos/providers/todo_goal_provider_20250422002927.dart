import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The key used to store the task goal in SharedPreferences
const String _taskGoalKey = 'task_goal';

/// Default task goal value
const int _defaultTaskGoal = 20;

/// Provider that manages the task goal counter
/// This represents the milestone number of completed tasks
final todoGoalProvider = StateNotifierProvider<TodoGoalNotifier, int>((ref) {
  return TodoGoalNotifier();
});

/// Notifier class for managing the task goal state
class TodoGoalNotifier extends StateNotifier<int> {
  TodoGoalNotifier() : super(_defaultTaskGoal) {
    _loadTaskGoal();
  }

  /// Load the task goal from SharedPreferences
  Future<void> _loadTaskGoal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final goal = prefs.getInt(_taskGoalKey);

      if (goal != null) {
        state = goal;
      } else {
        // If no goal is saved, save the default value
        await _saveTaskGoal(_defaultTaskGoal);
      }
    } catch (e) {
      print('Error loading task goal: $e');
    }
  }

  /// Save the task goal to SharedPreferences
  Future<bool> _saveTaskGoal(int goal) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setInt(_taskGoalKey, goal);
    } catch (e) {
      print('Error saving task goal: $e');
      return false;
    }
  }

  /// Update the task goal
  Future<bool> updateTaskGoal(int goal) async {
    if (goal < 0) return false;

    final success = await _saveTaskGoal(goal);
    if (success) {
      state = goal;
    }
    return success;
  }
}
