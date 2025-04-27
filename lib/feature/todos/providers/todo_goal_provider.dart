import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todoApp/core/globals.dart';

/// The key used to store the todo goal in SharedPreferences
const String _todoGoalKey = 'todo_goal';

/// Default todo goal value
const int _defaultTodoGoal = 20;

/// Provider that manages the todo goal counter
/// This represents the milestone number of completed tasks
final todoGoalProvider = StateNotifierProvider<TodoGoalNotifier, int>((ref) {
  return TodoGoalNotifier();
});

/// Notifier class for managing the task goal state
class TodoGoalNotifier extends StateNotifier<int> {
  TodoGoalNotifier() : super(_defaultTodoGoal) {
    _loadTodoGoal();
  }

  /// Load the todo goal from SharedPreferences
  Future<void> _loadTodoGoal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final goal = prefs.getInt(_todoGoalKey);

      if (goal != null) {
        state = goal;
      } else {
        // If no goal is saved, save the default value
        await _saveTodoGoal(_defaultTodoGoal);
      }
    } catch (e) {
      talker.error('[TodoGoalNotifier] Error loading todo goal', e);
    }
  }

  /// Save the todo goal to SharedPreferences
  Future<bool> _saveTodoGoal(int goal) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setInt(_todoGoalKey, goal);
    } catch (e) {
      talker.error('[TodoGoalNotifier] Error saving todo goal', e);
      return false;
    }
  }

  /// Update the todo goal
  Future<bool> updateTodoGoal(int goal) async {
    if (goal < 0) return false;

    final success = await _saveTodoGoal(goal);
    if (success) {
      state = goal;
    }
    return success;
  }
}
