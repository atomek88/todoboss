import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:todoApp/core/providers/date_provider.dart';
import 'package:todoApp/feature/daily_todos/models/daily_todo.dart';
import 'package:todoApp/feature/todos/models/todo.dart';
import 'daily_todo_filter_service.dart';

/// Service responsible for syncing DailyTodo objects with the correct filtered todos
class DailyTodoSyncService {
  /// Synchronizes a DailyTodo object with the relevant todos based on filtering rules
  /// Returns an updated DailyTodo with the correctly filtered todos
  static Future<DailyTodo> syncTodosForDate(
      DailyTodo dailyTodo, List<Todo> allTodos) async {
    final normalizedDate = normalizeDate(dailyTodo.date);
    final dayOfWeek = normalizedDate.weekday;
    final formattedDate = DateFormat('EEE, MMM d').format(normalizedDate);

    debugPrint('🔄 [DailyTodoSyncService] Syncing todos for $formattedDate (day $dayOfWeek)');
    
    // Use the existing filter service to get todos for this date
    final filteredTodos = DailyTodoFilterService.getTodosForDate(allTodos, normalizedDate);
    
    // Get scheduled todos for this day specifically
    final scheduledTodosToday = allTodos.where((todo) => 
      todo.scheduled.contains(dayOfWeek)).toList();
    
    // Get active scheduled todos for this day
    final activeScheduledTodosToday = scheduledTodosToday.where((todo) => todo.status == 0).toList();
    
    debugPrint('🔄 [DailyTodoSyncService] Found ${filteredTodos.length} todos for $formattedDate');
    debugPrint('📅 [DailyTodoSyncService] Scheduled specifically for day $dayOfWeek: ${activeScheduledTodosToday.length} active, ${scheduledTodosToday.length} total');
    
    // Check for any scheduled todos that weren't included in the filter
    final missingScheduledTodos = activeScheduledTodosToday.where(
      (todo) => !filteredTodos.any((t) => t.id == todo.id)).toList();
    
    if (missingScheduledTodos.isNotEmpty) {
      debugPrint('⚠️ [DailyTodoSyncService] WARNING: Found ${missingScheduledTodos.length} scheduled todos that were not included in filter:');
      for (final todo in missingScheduledTodos) {
        debugPrint('  - ${todo.title} (${todo.id.substring(0, 8)}) [${todo.scheduledText}]');
        // Add these missing scheduled todos to the filtered todos
        filteredTodos.add(todo);
      }
    }
    
    // Log all scheduled todos for debugging
    for (final todo in scheduledTodosToday) {
      final included = filteredTodos.any((t) => t.id == todo.id);
      debugPrint('  - ${todo.title} (${todo.id.substring(0, 8)}) [${todo.scheduledText}] - Included: $included - Status: ${todo.status}');
    }

    // Create a new DailyTodo with the filtered todos
    DailyTodo updatedDailyTodo = dailyTodo;
    
    // Clear existing todos and add filtered ones
    updatedDailyTodo = updatedDailyTodo.clearTodos();
    for (final todo in filteredTodos) {
      updatedDailyTodo = updatedDailyTodo.addTodo(todo);
    }
    
    // Update counters based on the filtered todos
    int completed = 0;
    int deleted = 0;
    
    for (final todo in filteredTodos) {
      if (todo.isCompleted) completed++;
      if (todo.isDeleted) deleted++;
    }
    
    updatedDailyTodo = updatedDailyTodo.copyWith(
      completedTodosCount: completed,
      deletedTodosCount: deleted,
    );
    
    debugPrint('🔄 [DailyTodoSyncService] Updated DailyTodo ${dailyTodo.id}: '
        'total=${updatedDailyTodo.todos.length}, '
        'completed=$completed, '
        'deleted=$deleted');
    
    return updatedDailyTodo;
  }
  
  /// Log details about todos being filtered for debugging
  static void logTodoFilterDetails(List<Todo> todos, DateTime date) {
    final normalizedDate = normalizeDate(date);
    final dayOfWeek = normalizedDate.weekday;
    
    // Get filtered todos using the filter service for reference
    final filteredTodos = DailyTodoFilterService.getTodosForDate(todos, normalizedDate);
    
    debugPrint('📋 [DailyTodoSyncService] === Todos by Filter Criteria ===');
    
    // Log todos created on this date
    final createdToday = todos.where((todo) {
      final todoCreationDate = normalizeDate(todo.createdAt);
      return todoCreationDate.isAtSameMomentAs(normalizedDate);
    }).toList();
    
    debugPrint('📅 [DailyTodoSyncService] Created on ${DateFormat('yyyy-MM-dd').format(normalizedDate)}: ${createdToday.length}');
    for (final todo in createdToday) {
      debugPrint('  - ${todo.title} (${todo.id.substring(0, 8)})');
    }
    
    // Log todos scheduled for this day of week
    final scheduledToday = todos.where((todo) => 
      todo.scheduled.contains(dayOfWeek) && todo.status == 0).toList();
    
    debugPrint('🗓️ [DailyTodoSyncService] Scheduled for day $dayOfWeek: ${scheduledToday.length}');
    for (final todo in scheduledToday) {
      debugPrint('  - ${todo.title} (${todo.id.substring(0, 8)}) [${todo.scheduledText}]');
    }
    
    // Log rollovers
    final rollovers = todos.where((todo) => 
      todo.rollover && 
      todo.status == 0 && 
      normalizeDate(todo.createdAt).isBefore(normalizedDate)).toList();
    
    debugPrint('🔄 [DailyTodoSyncService] Rollovers: ${rollovers.length}');
    for (final todo in rollovers) {
      final included = filteredTodos.any((t) => t.id == todo.id);
      debugPrint('  - ${todo.title} (${todo.id.substring(0, 8)}) [created: ${DateFormat('yyyy-MM-dd').format(todo.createdAt)}] - Included: $included');
      
      // If a rollover todo is not included but should be, add it
      if (!included) {
        debugPrint('    ⚠️ Adding missing rollover todo');
        filteredTodos.add(todo);
      }
    }
  }
}
