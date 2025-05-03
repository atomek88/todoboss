import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';

import 'package:todoApp/core/storage/storage_service.dart';
import 'package:todoApp/feature/todos/models/todo.dart';
import 'package:todoApp/feature/todos/models/todo_isar.dart';
import 'package:todoApp/feature/todos/models/daily_todo.dart';
import 'package:todoApp/feature/todos/models/daily_todo_isar.dart';

/// Repository for managing DailyTodo objects
class DailyTodoRepository {
  final StorageService _storageService;
  Isar? _isar;
  final _initCompleter = Completer<void>();
  bool _isInitialized = false;

  /// Constructor
  DailyTodoRepository(this._storageService) {
    _initialize();
  }

  /// Initialize the repository
  Future<void> _initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('📅 [DailyTodoRepository] Initializing...');
      _isar = await _storageService.getIsar();
      _isInitialized = true;
      _initCompleter.complete();
      debugPrint('📅 [DailyTodoRepository] Initialized successfully');
    } catch (e) {
      debugPrint('📅 [DailyTodoRepository] Error initializing: $e');
      _initCompleter.completeError(e);
      rethrow;
    }
  }

  /// Wait for initialization to complete
  Future<void> get initialized => _initCompleter.future;

  /// Get a DailyTodo by ID (format: DDMMYYYY)
  Future<DailyTodo?> getDailyTodoById(String id) async {
    try {
      await initialized;

      // Simple query until we can run build_runner
      final dailyTodoIsars =
          await _isar!.collection<DailyTodoIsar>().where().findAll();

      final dailyTodoIsar =
          dailyTodoIsars.where((td) => td.dateId == id).firstOrNull;

      if (dailyTodoIsar != null) {
        // Load associated todos by the stored todoIds
        final todoIds = dailyTodoIsar.todoIds;
        List<Todo> todos = [];

        if (todoIds.isNotEmpty) {
          // Get all todos from Isar
          final todoIsars =
              await _isar!.collection<TodoIsar>().where().findAll();

          // Filter to get only the todos associated with this DailyTodo
          todos = todoIsars
              .where((todoIsar) => todoIds.contains(todoIsar.uuid))
              .map((todoIsar) => todoIsar.toDomain())
              .toList();

          debugPrint(
              '📅 [DailyTodoRepository] Loaded ${todos.length} todos for DailyTodo ${dailyTodoIsar.dateId}');
        }

        // Set the todos on the Isar object before converting to domain
        dailyTodoIsar.todos = todos;

        debugPrint(
            '📅 [DailyTodoRepository] Found DailyTodo: ${dailyTodoIsar.dateId}');
        return dailyTodoIsar.toDomain();
      }

      debugPrint('📅 [DailyTodoRepository] DailyTodo not found for ID: $id');
      return null;
    } catch (e) {
      debugPrint('📅 [DailyTodoRepository] Error getting DailyTodo by ID: $e');
      return null;
    }
  }

  /// Get a DailyTodo for a specific date, creating if it doesn't exist
  Future<DailyTodo> getDailyTodoForDate(DateTime date,
      {int defaultGoal = 0}) async {
    try {
      await initialized;

      // Normalize date to midnight
      final normalizedDate = DateTime(date.year, date.month, date.day);

      // Format ID from date
      final dateId =
          '${normalizedDate.day.toString().padLeft(2, '0')}${normalizedDate.month.toString().padLeft(2, '0')}${normalizedDate.year}';

      // Try to get existing DailyTodo
      var dailyTodo = await getDailyTodoById(dateId);

      // If not found, create a new one
      if (dailyTodo == null) {
        dailyTodo = DailyTodo.fromDate(normalizedDate, taskGoal: defaultGoal);
        await saveDailyTodo(dailyTodo);
        debugPrint(
            '📅 [DailyTodoRepository] Created new DailyTodo for: $normalizedDate with goal: $defaultGoal');
      } else {
        // ALWAYS update the goal if the default goal is set and different from current
        if (defaultGoal > 0 && dailyTodo.taskGoal != defaultGoal) {
          dailyTodo = dailyTodo.copyWith(taskGoal: defaultGoal);
          await saveDailyTodo(dailyTodo);
          debugPrint(
              '📅 [DailyTodoRepository] Updated DailyTodo with default goal: $defaultGoal (was: ${dailyTodo.taskGoal})');
        } else {
          debugPrint(
              '📅 [DailyTodoRepository] Using existing DailyTodo with goal: ${dailyTodo.taskGoal}');
        }
      }

      return dailyTodo;
    } catch (e) {
      debugPrint(
          '📅 [DailyTodoRepository] Error getting DailyTodo for date: $e');
      // Return a default DailyTodo if we couldn't get one
      return DailyTodo.fromDate(date, taskGoal: defaultGoal);
    }
  }

  /// Get all DailyTodos
  Future<List<DailyTodo>> getAllDailyTodos() async {
    try {
      await initialized;

      final dailyTodoIsars =
          await _isar!.collection<DailyTodoIsar>().where().findAll();

      // Create a map of UUID -> Todo for efficient lookup
      final allTodoIsars = await _isar!.collection<TodoIsar>().where().findAll();
      final allTodos = allTodoIsars.map((t) => t.toDomain()).toList();
      final todoMap = {for (var todo in allTodos) todo.id: todo};

      // Process each DailyTodoIsar to include its todos
      final dailyTodos = dailyTodoIsars.map((dailyTodoIsar) {
        // Get todos for this dailyTodo using the todoIds to lookup in our map
        final todos = dailyTodoIsar.todoIds
            .map((id) => todoMap[id])
            .where((todo) => todo != null)
            .cast<Todo>()
            .toList();

        // Set the todos list before converting to domain model
        dailyTodoIsar.todos = todos;
        return dailyTodoIsar.toDomain();
      }).toList();

      debugPrint(
          '📅 [DailyTodoRepository] Found ${dailyTodos.length} DailyTodos with associated todos');
      return dailyTodos;
    } catch (e) {
      debugPrint('📅 [DailyTodoRepository] Error getting all DailyTodos: $e');
      return [];
    }
  }

  /// Save a DailyTodo
  Future<bool> saveDailyTodo(DailyTodo dailyTodo) async {
    try {
      await initialized;

      // Create the Isar model from domain model
      // This automatically extracts the todoIds from the todos list
      final dailyTodoIsar = DailyTodoIsar.fromDomain(dailyTodo);

      // Find existing by ID
      final dailyTodoIsars =
          await _isar!.collection<DailyTodoIsar>().where().findAll();

      final existing =
          dailyTodoIsars.where((td) => td.dateId == dailyTodo.id).firstOrNull;

      if (existing != null) {
        dailyTodoIsar.id = existing.id;
      }

      await _isar!.writeTxn(() async {
        await _isar!.collection<DailyTodoIsar>().put(dailyTodoIsar);
      });

      debugPrint(
          '📅 [DailyTodoRepository] Saved DailyTodo: ${dailyTodo.id} with ${dailyTodo.todos.length} todos and todoIds: ${dailyTodoIsar.todoIds.length}');
      return true;
    } catch (e) {
      debugPrint('📅 [DailyTodoRepository] Error saving DailyTodo: $e');
      return false;
    }
  }

  /// Delete a DailyTodo by ID
  Future<bool> deleteDailyTodo(String id) async {
    try {
      await initialized;

      final todoDateIsars =
          await _isar!.collection<DailyTodoIsar>().where().build().findAll();
      final existing = todoDateIsars.where((td) => td.dateId == id).firstOrNull;

      if (existing == null) {
        debugPrint(
            '📅 [DailyTodoRepository] DailyTodo not found for deletion: $id');
        return false;
      }

      await _isar!.writeTxn(() async {
        await _isar!.collection<DailyTodoIsar>().delete(existing.id);
      });

      debugPrint('📅 [DailyTodoRepository] Deleted DailyTodo: $id');
      return true;
    } catch (e) {
      debugPrint('📅 [DailyTodoRepository] Error deleting DailyTodo: $e');
      return false;
    }
  }

  /// Add a todo to a specific date's todos list
  /// This is important for tracking which todos belong to which date
  Future<bool> addTodoToDate(DateTime date, Todo todo) async {
    try {
      await initialized;

      // Get the DailyTodo for the date
      final dailyTodo = await getDailyTodoForDate(date);

      // Check if the todo is already in the list
      if (!dailyTodo.todos.any((t) => t.id == todo.id)) {
        // Add the todo to the list
        final updatedTodos = List<Todo>.from(dailyTodo.todos)..add(todo);

        // Create an updated DailyTodo with the new todo list
        final updatedDailyTodo = dailyTodo.copyWith(todos: updatedTodos);

        // Save the updated DailyTodo
        await saveDailyTodo(updatedDailyTodo);

        debugPrint(
            '📅 [DailyTodoRepository] Added todo ${todo.id} to date: ${dailyTodo.id}');
      } else {
        debugPrint(
            '📅 [DailyTodoRepository] Todo ${todo.id} already exists for date: ${dailyTodo.id}');
      }

      return true;
    } catch (e) {
      debugPrint('📅 [DailyTodoRepository] Error adding todo to date: $e');
      return false;
    }
  }

  /// Remove a todo from a specific date's todos list
  Future<bool> removeTodoFromDate(DateTime date, Todo todo) async {
    try {
      await initialized;

      // Get the DailyTodo for the date
      final dailyTodo = await getDailyTodoForDate(date);

      // Check if the todo is in the list
      final updatedTodos = List<Todo>.from(dailyTodo.todos)
        ..removeWhere((t) => t.id == todo.id);

      // Create an updated DailyTodo without the todo
      final updatedDailyTodo = dailyTodo.copyWith(todos: updatedTodos);

      // Save the updated DailyTodo
      await saveDailyTodo(updatedDailyTodo);

      debugPrint(
          '📅 [DailyTodoRepository] Removed todo ${todo.id} from date: ${dailyTodo.id}');
      return true;
    } catch (e) {
      debugPrint('📅 [DailyTodoRepository] Error removing todo from date: $e');
      return false;
    }
  }

  /// Update the DailyTodo counters based on todos for a specific date
  Future<DailyTodo?> updateDailyTodoCounters(DateTime date, List<Todo> todos,
      {int defaultGoal = 0}) async {
    try {
      await initialized;

      // Use the provided goal or fallback to a reasonable default
      final goalToUse = defaultGoal > 0 ? defaultGoal : 20;

      // Get the DailyTodo with the correct goal
      final dailyTodo = await getDailyTodoForDate(date, defaultGoal: goalToUse);

      // Normalize the date for comparison
      final normalizedDate = DateTime(date.year, date.month, date.day);

      debugPrint(
          '📅 [DailyTodoRepository] Calculating counters for date: ${normalizedDate.toString().split(' ')[0]}');

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
              '📅 [DailyTodoRepository] Including todo: ${todo.title} (status: ${todo.status})');
        }

        return result;
      }).toList();

      // Calculate counters for this date only
      final completedCount =
          todosForDate.where((todo) => todo.status == 1).length;
      final deletedCount =
          todosForDate.where((todo) => todo.status == 2).length;

      // Preserve the task goal from the existing DailyTodo
      final taskGoal = dailyTodo.taskGoal;

      debugPrint(
          '📅 [DailyTodoRepository] Found ${todosForDate.length} todos for date: ${normalizedDate.toString().split(' ')[0]}');
      debugPrint(
          '📅 [DailyTodoRepository] Completed: $completedCount, Deleted: $deletedCount, Goal: $taskGoal');

      // Create an updated DailyTodo with the new todos list first
      final withUpdatedTodos = dailyTodo.copyWith(
        todos: todosForDate,
        completedTodosCount: completedCount,
        deletedTodosCount: deletedCount,
        taskGoal: taskGoal, // Ensure goal is preserved
      );

      // Then apply summary if date is in the past
      final updatedDailyTodo = withUpdatedTodos.copyWith(
        summary:
            withUpdatedTodos.isPast ? withUpdatedTodos.generateSummary() : null,
      );

      // Save it
      await saveDailyTodo(updatedDailyTodo);

      debugPrint(
          '📅 [DailyTodoRepository] Updated DailyTodo counters for ${dailyTodo.id}: completed=$completedCount, deleted=$deletedCount, goal=$taskGoal');
      return updatedDailyTodo;
    } catch (e) {
      debugPrint(
          '📅 [DailyTodoRepository] Error updating DailyTodo counters: $e');
      return null;
    }
  }

  /// Get all past DailyTodos
  Future<List<DailyTodo>> getPastDailyTodos() async {
    try {
      await initialized;

      final today = DateTime.now();
      final normalizedToday = DateTime(today.year, today.month, today.day);

      final allDailyTodos = await getAllDailyTodos();

      return allDailyTodos
          .where((todoDate) => todoDate.date.isBefore(normalizedToday))
          .toList()
        // Sort by date, most recent first
        ..sort((a, b) => b.date.compareTo(a.date));
    } catch (e) {
      debugPrint('📅 [DailyTodoRepository] Error getting past DailyTodos: $e');
      return [];
    }
  }

  /// Get the DailyTodo for today
  Future<DailyTodo> getTodayDailyTodo({int defaultGoal = 0}) async {
    final today = DateTime.now();
    return getDailyTodoForDate(today, defaultGoal: defaultGoal);
  }

  /// Set the task goal for a specific date
  Future<DailyTodo?> setTaskGoal(DateTime date, int goal) async {
    try {
      await initialized;

      final todoDate = await getDailyTodoForDate(date);
      final updatedDailyTodo = todoDate.copyWith(taskGoal: goal);

      await saveDailyTodo(updatedDailyTodo);

      debugPrint(
          '📅 [DailyTodoRepository] Set task goal for ${todoDate.id} to $goal');
      return updatedDailyTodo;
    } catch (e) {
      debugPrint('📅 [DailyTodoRepository] Error setting task goal: $e');
      return null;
    }
  }
}
