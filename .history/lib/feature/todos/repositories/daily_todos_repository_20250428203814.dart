import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';

import 'package:todoApp/core/storage/storage_service.dart';
import 'package:todoApp/feature/todos/models/todo.dart';
import 'package:todoApp/feature/todos/models/todo_date.dart';
import 'package:todoApp/feature/todos/models/todo_date_isar.dart';

/// Repository for managing TodoDate objects
class TodoDateRepository {
  final StorageService _storageService;
  Isar? _isar;
  final _initCompleter = Completer<void>();
  bool _isInitialized = false;

  /// Constructor
  TodoDateRepository(this._storageService) {
    _initialize();
  }

  /// Initialize the repository
  Future<void> _initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('📅 [TodoDateRepository] Initializing...');
      _isar = await _storageService.getIsar();
      _isInitialized = true;
      _initCompleter.complete();
      debugPrint('📅 [TodoDateRepository] Initialized successfully');
    } catch (e) {
      debugPrint('📅 [TodoDateRepository] Error initializing: $e');
      _initCompleter.completeError(e);
      rethrow;
    }
  }

  /// Wait for initialization to complete
  Future<void> get initialized => _initCompleter.future;

  /// Get a TodoDate by ID (format: DDMMYYYY)
  Future<TodoDate?> getTodoDateById(String id) async {
    try {
      await initialized;

      // Simple query until we can run build_runner
      final todoDateIsars =
          await _isar!.collection<TodoDateIsar>().where().findAll();

      final todoDateIsar =
          todoDateIsars.where((td) => td.dateId == id).firstOrNull;

      if (todoDateIsar != null) {
        debugPrint(
            '📅 [TodoDateRepository] Found TodoDate: ${todoDateIsar.dateId}');
        return todoDateIsar.toDomain();
      }

      debugPrint('📅 [TodoDateRepository] TodoDate not found for ID: $id');
      return null;
    } catch (e) {
      debugPrint('📅 [TodoDateRepository] Error getting TodoDate by ID: $e');
      return null;
    }
  }

  /// Get a TodoDate for a specific date, creating if it doesn't exist
  Future<TodoDate> getTodoDateForDate(DateTime date,
      {int defaultGoal = 0}) async {
    try {
      await initialized;

      // Normalize date to midnight
      final normalizedDate = DateTime(date.year, date.month, date.day);

      // Format ID from date
      final dateId =
          '${normalizedDate.day.toString().padLeft(2, '0')}${normalizedDate.month.toString().padLeft(2, '0')}${normalizedDate.year}';

      // Try to get existing TodoDate
      var todoDate = await getTodoDateById(dateId);

      // If not found, create a new one
      if (todoDate == null) {
        todoDate = TodoDate.fromDate(normalizedDate, taskGoal: defaultGoal);
        await saveTodoDate(todoDate);
        debugPrint(
            '📅 [TodoDateRepository] Created new TodoDate for: $normalizedDate with goal: $defaultGoal');
      } else {
        // ALWAYS update the goal if the default goal is set and different from current
        if (defaultGoal > 0 && todoDate.taskGoal != defaultGoal) {
          todoDate = todoDate.copyWith(taskGoal: defaultGoal);
          await saveTodoDate(todoDate);
          debugPrint(
              '📅 [TodoDateRepository] Updated TodoDate with default goal: $defaultGoal (was: ${todoDate.taskGoal})');
        } else {
          debugPrint(
              '📅 [TodoDateRepository] Using existing TodoDate with goal: ${todoDate.taskGoal}');
        }
      }

      return todoDate;
    } catch (e) {
      debugPrint('📅 [TodoDateRepository] Error getting TodoDate for date: $e');
      // Return a default TodoDate if we couldn't get one
      return TodoDate.fromDate(date, taskGoal: defaultGoal);
    }
  }

  /// Get all TodoDates
  Future<List<TodoDate>> getAllTodoDates() async {
    try {
      await initialized;

      final todoDateIsars =
          await _isar!.collection<TodoDateIsar>().where().findAll();

      final todoDates =
          todoDateIsars.map((todoDateIsar) => todoDateIsar.toDomain()).toList();

      debugPrint('📅 [TodoDateRepository] Found ${todoDates.length} TodoDates');
      return todoDates;
    } catch (e) {
      debugPrint('📅 [TodoDateRepository] Error getting all TodoDates: $e');
      return [];
    }
  }

  /// Save a TodoDate
  Future<bool> saveTodoDate(TodoDate todoDate) async {
    try {
      await initialized;

      final todoDateIsar = TodoDateIsar.fromDomain(todoDate);

      // Find existing by ID
      // Simple query until we can run build_runner
      final todoDateIsars =
          await _isar!.collection<TodoDateIsar>().where().findAll();

      final existing =
          todoDateIsars.where((td) => td.dateId == todoDate.id).firstOrNull;

      if (existing != null) {
        todoDateIsar.id = existing.id;
      }

      await _isar!.writeTxn(() async {
        await _isar!.collection<TodoDateIsar>().put(todoDateIsar);
      });

      debugPrint('📅 [TodoDateRepository] Saved TodoDate: ${todoDate.id}');
      return true;
    } catch (e) {
      debugPrint('📅 [TodoDateRepository] Error saving TodoDate: $e');
      return false;
    }
  }

  /// Delete a TodoDate by ID
  Future<bool> deleteTodoDate(String id) async {
    try {
      await initialized;

      final todoDateIsars =
          await _isar!.collection<TodoDateIsar>().where().build().findAll();
      final existing = todoDateIsars.where((td) => td.dateId == id).firstOrNull;

      if (existing == null) {
        debugPrint(
            '📅 [TodoDateRepository] TodoDate not found for deletion: $id');
        return false;
      }

      await _isar!.writeTxn(() async {
        await _isar!.collection<TodoDateIsar>().delete(existing.id);
      });

      debugPrint('📅 [TodoDateRepository] Deleted TodoDate: $id');
      return true;
    } catch (e) {
      debugPrint('📅 [TodoDateRepository] Error deleting TodoDate: $e');
      return false;
    }
  }

  /// Add a todo ID to a specific date
  /// This is important for tracking which todos belong to which date
  Future<TodoDate?> addTodoToDate(DateTime date, String todoId) async {
    try {
      await initialized;

      // Normalize date to midnight
      final normalizedDate = DateTime(date.year, date.month, date.day);

      // Get or create the TodoDate for this date
      final todoDate = await getTodoDateForDate(normalizedDate);

      // Only add if the todo ID isn't already tracked by this date
      if (!todoDate.todoIds.contains(todoId)) {
        // Add the todo ID to the TodoDate
        final updatedTodoDate = todoDate.addTodoId(todoId);

        // Save the updated TodoDate
        await saveTodoDate(updatedTodoDate);

        debugPrint(
            '📅 [TodoDateRepository] Added todo $todoId to date ${todoDate.id}');
        return updatedTodoDate;
      } else {
        debugPrint(
            '📅 [TodoDateRepository] Todo $todoId already on date ${todoDate.id}');
        return todoDate;
      }
    } catch (e) {
      debugPrint('📅 [TodoDateRepository] Error adding todo to date: $e');
      return null;
    }
  }

  /// Remove a todo ID from a specific date
  Future<TodoDate?> removeTodoFromDate(DateTime date, String todoId) async {
    try {
      await initialized;

      // Normalize date to midnight
      final normalizedDate = DateTime(date.year, date.month, date.day);

      // Get the TodoDate for this date
      final todoDate = await getTodoDateForDate(normalizedDate);

      // Only remove if the todo ID is tracked by this date
      if (todoDate.todoIds.contains(todoId)) {
        // Remove the todo ID from the TodoDate
        final updatedTodoDate = todoDate.removeTodoId(todoId);

        // Save the updated TodoDate
        await saveTodoDate(updatedTodoDate);

        debugPrint(
            '📅 [TodoDateRepository] Removed todo $todoId from date ${todoDate.id}');
        return updatedTodoDate;
      } else {
        debugPrint(
            '📅 [TodoDateRepository] Todo $todoId not on date ${todoDate.id}');
        return todoDate;
      }
    } catch (e) {
      debugPrint('📅 [TodoDateRepository] Error removing todo from date: $e');
      return null;
    }
  }

  /// Update the TodoDate counters based on todos for a specific date
  Future<TodoDate?> updateTodoDateCounters(DateTime date, List<Todo> todos,
      {int defaultGoal = 0}) async {
    try {
      await initialized;

      // Use the provided goal or fallback to a reasonable default
      final goalToUse = defaultGoal > 0 ? defaultGoal : 20;

      // Get the TodoDate with the correct goal
      final todoDate = await getTodoDateForDate(date, defaultGoal: goalToUse);

      // Normalize the date for comparison
      final normalizedDate = DateTime(date.year, date.month, date.day);

      debugPrint(
          '📅 [TodoDateRepository] Calculating counters for date: ${normalizedDate.toString().split(' ')[0]}');

      // Filter todos to only include those for this specific date
      final todosForDate = todos.where((todo) {
        // For created todos, check if they were created on this date
        final createdOnThisDate = DateTime(todo.createdAt.year,
                todo.createdAt.month, todo.createdAt.day) ==
            normalizedDate;

        // For completed/deleted todos, check if they were ended on this date
        final endedOnThisDate = todo.endedOn != null &&
            DateTime(todo.endedOn!.year, todo.endedOn!.month,
                    todo.endedOn!.day) ==
                normalizedDate;

        final result = createdOnThisDate || endedOnThisDate;

        if (result) {
          debugPrint(
              '📅 [TodoDateRepository] Including todo: ${todo.title} (status: ${todo.status})');
        }

        return result;
      }).toList();

      // Calculate counters for this date only
      final completedCount =
          todosForDate.where((todo) => todo.status == 1).length;
      final deletedCount =
          todosForDate.where((todo) => todo.status == 2).length;

      // Get the list of todo IDs for this date
      final todoIds = todosForDate.map((todo) => todo.id).toList();

      // Preserve the task goal from the existing TodoDate
      final taskGoal = todoDate.taskGoal;

      debugPrint(
          '📅 [TodoDateRepository] Found ${todosForDate.length} todos for date: ${normalizedDate.toString().split(' ')[0]}');
      debugPrint(
          '📅 [TodoDateRepository] Completed: $completedCount, Deleted: $deletedCount, Goal: $taskGoal');

      // Update the TodoDate
      final updatedTodoDate = todoDate.copyWith(
        completedTodosCount: completedCount,
        deletedTodosCount: deletedCount,
        todoIds: todoIds,
        taskGoal: taskGoal, // Ensure goal is preserved
        // only generate summary is date is in past
        summary:
            todoDate.isPast ? todoDate.generateSummary(todosForDate) : null,
      );

      // Save it
      await saveTodoDate(updatedTodoDate);

      debugPrint(
          '📅 [TodoDateRepository] Updated TodoDate counters for ${todoDate.id}: completed=$completedCount, deleted=$deletedCount, goal=$taskGoal');
      return updatedTodoDate;
    } catch (e) {
      debugPrint(
          '📅 [TodoDateRepository] Error updating TodoDate counters: $e');
      return null;
    }
  }

  /// Get all past TodoDates
  Future<List<TodoDate>> getPastTodoDates() async {
    try {
      await initialized;

      final today = DateTime.now();
      final normalizedToday = DateTime(today.year, today.month, today.day);

      final allTodoDates = await getAllTodoDates();

      return allTodoDates
          .where((todoDate) => todoDate.date.isBefore(normalizedToday))
          .toList()
        // Sort by date, most recent first
        ..sort((a, b) => b.date.compareTo(a.date));
    } catch (e) {
      debugPrint('📅 [TodoDateRepository] Error getting past TodoDates: $e');
      return [];
    }
  }

  /// Get the TodoDate for today
  Future<TodoDate> getTodayTodoDate({int defaultGoal = 0}) async {
    final today = DateTime.now();
    return getTodoDateForDate(today, defaultGoal: defaultGoal);
  }

  /// Set the task goal for a specific date
  Future<TodoDate?> setTaskGoal(DateTime date, int goal) async {
    try {
      await initialized;

      final todoDate = await getTodoDateForDate(date);
      final updatedTodoDate = todoDate.copyWith(taskGoal: goal);

      await saveTodoDate(updatedTodoDate);

      debugPrint(
          '📅 [TodoDateRepository] Set task goal for ${todoDate.id} to $goal');
      return updatedTodoDate;
    } catch (e) {
      debugPrint('📅 [TodoDateRepository] Error setting task goal: $e');
      return null;
    }
  }
}
