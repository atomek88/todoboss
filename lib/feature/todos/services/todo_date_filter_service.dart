import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/todo.dart';

/// Service that provides filtering functionality for todos based on dates
class TodoDateFilterService {
  /// Get todos for a specific date based on the following criteria:
  /// 1. The TodoListItem created_at date is the same date as the selected day
  /// 2. The TodoListItem has rollover = true and the status property == isActive (0)
  /// 3. The TodoListItem is scheduled for that Day of Week derived from the selected day
  static List<Todo> getTodosForDate(
      List<Todo> allTodos, DateTime selectedDate) {
    debugPrint('===== Filtering todos for date: ${selectedDate.toString()} =====');
    debugPrint('Total todos in list: ${allTodos.length}');

    // Normalize the selected date to midnight for comparison
    final normalizedSelectedDate = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );

    // Get the day of week (1-7 where 1 = Monday, 7 = Sunday) for the selected date
    final dayOfWeek = selectedDate.weekday;
    debugPrint('Selected day of week: $dayOfWeek (1=Monday, 7=Sunday)');

    // First, let's log all todos with their scheduled days
    for (final todo in allTodos) {
      if (todo.status == 0) { // Only log active todos
        debugPrint('Todo: ${todo.title} - Created: ${todo.createdAt} - Rollover: ${todo.rollover} - Scheduled: ${todo.scheduled}');
      }
    }
    
    return allTodos.where((todo) {
      // Only consider active todos
      if (todo.status != 0) return false;

      // Normalize the todo creation date for comparison
      final todoCreationDate = DateTime(
        todo.createdAt.year,
        todo.createdAt.month,
        todo.createdAt.day,
      );

      // Condition 1: Todo was created on the selected date
      final createdOnSelectedDate =
          todoCreationDate.isAtSameMomentAs(normalizedSelectedDate);

      // Condition 2: Todo has rollover=true, is active, and was created on or before the selected date
      final isRolloverAndActive = todo.rollover && todo.status == 0;
      final createdOnOrBeforeSelectedDate =
          !todoCreationDate.isAfter(normalizedSelectedDate);
      final shouldRollover =
          isRolloverAndActive && createdOnOrBeforeSelectedDate;

      // Condition 3: Todo is scheduled for this day of week using the new scheduled Set<int>
      final isScheduledForToday = todo.scheduled.contains(dayOfWeek);
      
      // Debug the scheduled days
      if (todo.scheduled.isNotEmpty) {
        debugPrint('Todo ${todo.title} scheduled days: ${todo.scheduled}');
        debugPrint('Is scheduled for today ($dayOfWeek)? $isScheduledForToday');
      }

      // A todo should show if ANY of these conditions are true:
      // 1. It was created on the selected date
      // 2. It has rollover=true and was created on or before the selected date
      // 3. It is scheduled for this day of week
      final shouldShow = createdOnSelectedDate ||
          shouldRollover ||
          isScheduledForToday;

      if (shouldShow) {
        debugPrint(
            '✅ Including todo: ${todo.title} (created: ${todo.createdAt}, rollover: ${todo.rollover}, scheduled: ${todo.scheduled})');
      } else {
        debugPrint(
            '❌ Excluding todo: ${todo.title} (created: ${todo.createdAt}, rollover: ${todo.rollover}, scheduled: ${todo.scheduled})');
        debugPrint('   createdOnSelectedDate: $createdOnSelectedDate, shouldRollover: $shouldRollover, isScheduledForToday: $isScheduledForToday');
      }

      return shouldShow;
    }).toList();
  }
}

/// Provider for the TodoDateFilterService
final todoDateFilterServiceProvider = Provider<TodoDateFilterService>((ref) {
  return TodoDateFilterService();
});

/// Provider that filters todos based on the selected date
final filteredTodosProvider =
    Provider.family<List<Todo>, DateTime>((ref, selectedDate) {
  final allTodos = ref.watch(allTodosProvider);
  return TodoDateFilterService.getTodosForDate(allTodos, selectedDate);
});

/// Provider for all todos (to be implemented or replaced with your actual todos provider)
final allTodosProvider = Provider<List<Todo>>((ref) {
  // This should be replaced with your actual todos provider
  // For now, just returning an empty list as a placeholder
  return [];
});
