import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Enum to define the different types of todos
enum TodoType {
  default_todo,  // Regular todo (may have rollover enabled)
  scheduled   // Todo that is scheduled for specific days of the week
}

/// Provider to track the rollover state for todos
final todoRolloverProvider = StateProvider.autoDispose<bool>((ref) => false);

/// Provider to track the selected days for scheduled todos
final todoScheduledDaysProvider = StateProvider<Set<int>>((ref) => {});

/// Provider to track the type of todo being created/edited
final todoTypeProvider = StateProvider<TodoType>((ref) => TodoType.default_todo);

// Provider to store the current form values for creating a new todo when dismissed
final todoFormValuesProvider = StateProvider<Map<String, dynamic>>((ref) => {
  'title': '',
  'description': '',
  'priority': 0,
  'type': TodoType.default_todo,
});
