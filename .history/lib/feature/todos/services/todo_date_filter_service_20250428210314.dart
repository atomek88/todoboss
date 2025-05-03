import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:todoApp/core/providers/selected_date_provider.dart';
import 'package:todoApp/core/providers/date_provider.dart';
import '../models/todo.dart';
import '../providers/todos_provider.dart';

/// Service that provides filtering functionality for todos based on dates
class TodoDateFilterService {
  /// Get todos for a specific date based on the following criteria:
  /// 1. The TodoListItem created_at date is the same date as the selected day
  /// 2. The TodoListItem has rollover = true and the status property == isActive (0)
  /// 3. The TodoListItem is scheduled for that Day of Week derived from the selected day
  static List<Todo> getTodosForDate(
      List<Todo> allTodos, DateTime selectedDate) {
    // Clear logging header with emoji
    debugPrint(
        '🔍 ===== FILTERING TODOS FOR DATE: ${selectedDate.toString()} =====');
    debugPrint(
        '🔍 [TodoDateFilterService] Todos to filter: ${allTodos.length}');

    // Normalize the selected date to midnight for consistent date comparison across the app
    final normalizedSelectedDate = normalizeDate(selectedDate);

    // Log for debugging date synchronization
    final formattedDate =
        DateFormat('EEE, MMM d').format(normalizedSelectedDate);
    debugPrint(
        '🔄 [TodoDateFilterService] Using normalized date: $normalizedSelectedDate ($formattedDate)');
    debugPrint(
        '🔄 [TodoDateFilterService] Day of week: ${normalizedSelectedDate.weekday}');

    // Get the day of week (1-7 where 1 = Monday, 7 = Sunday) for the selected date
    final dayOfWeek = selectedDate.weekday;
    debugPrint(
        '🔍 [TodoDateFilterService] Selected day of week: $dayOfWeek (1=Monday, 7=Sunday)');

    // Count active todos for debugging
    final activeTodos = allTodos.where((todo) => todo.status == 0).toList();
    debugPrint(
        '🔍 [TodoDateFilterService] Active todos: ${activeTodos.length}');

    // First, let's log all todos with their scheduled days
    for (final todo in activeTodos) {
      debugPrint(
          '🔍 [TodoDateFilterService] Todo: ${todo.title} - Created: ${todo.createdAt} - Status: ${todo.status} - Rollover: ${todo.rollover} - Scheduled: ${todo.scheduled}');
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
      final shouldShow =
          createdOnSelectedDate || shouldRollover || isScheduledForToday;

      if (shouldShow) {
        debugPrint(
            '✅ Including todo: ${todo.title} (created: ${todo.createdAt}, rollover: ${todo.rollover}, scheduled: ${todo.scheduled})');
      } else {
        debugPrint(
            '❌ Excluding todo: ${todo.title} (created: ${todo.createdAt}, rollover: ${todo.rollover}, scheduled: ${todo.scheduled})');
        debugPrint(
            '   createdOnSelectedDate: $createdOnSelectedDate, shouldRollover: $shouldRollover, isScheduledForToday: $isScheduledForToday');
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
final filteredTodosProvider = Provider<List<Todo>>((ref) {
  // Using watch on both providers to ensure reactivity when either changes
  final allTodos = ref.watch(todoListProvider);
  final selectedDate = ref.watch(selectedDateProvider);

  // Ensure we're working with a normalized date for consistent behavior
  final normalizedDate = normalizeDate(selectedDate);

  // Enhanced logging with date formatting to track inconsistencies
  final formatted = DateFormat('EEE, MMM d yyyy').format(normalizedDate);
  debugPrint(
      '📍 [FilteredTodosProvider] REBUILDING with date: $normalizedDate | $formatted (weekday: ${normalizedDate.weekday})');
  debugPrint(
      '📍 [FilteredTodosProvider] Total todos available: ${allTodos.length}');

  // Force the TodoDateFilterService to run and filter the todos
  // Always pass a normalized date for consistency
  final filteredTodos =
      TodoDateFilterService.getTodosForDate(allTodos, normalizedDate);

  // Log the results of the filtering
  debugPrint(
      '📋 [FilteredTodosProvider] Filtered result: ${filteredTodos.length} todos');
  filteredTodos.forEach((todo) {
    debugPrint('📋 [FilteredTodosProvider] Included: ${todo.title}');
  });

  return filteredTodos;
});
