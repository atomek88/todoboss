import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:todoApp/core/storage/storage_service.dart';
import 'package:todoApp/feature/daily_todos/providers/daily_todos_provider.dart';
import 'package:todoApp/core/providers/date_provider.dart';
import '../models/todo.dart';
import '../repositories/todo_repository.dart';

// Provider for the TodoRepository
final todoRepositoryProvider = Provider<TodoRepository>((ref) {
  return TodoRepository(ref.watch(storageServiceProvider));
});

// Provider for the list of todos
final todoListProvider =
    StateNotifierProvider<TodoListNotifier, List<Todo>>((ref) {
  final repository = ref.watch(todoRepositoryProvider);

  // Force refresh when date changes
  ref.watch(
      selectedDateProvider); // This creates a dependency on the selected date

  return TodoListNotifier(ref, repository);
});

class TodoListNotifier extends StateNotifier<List<Todo>> {
  final TodoRepository _repository;
  final Ref _ref;

  TodoListNotifier(this._ref, this._repository) : super([]) {
    _loadTodos();
  }

  Future<void> _loadTodos() async {
    try {
      final todos = await _repository.getAllTodos();
      if (mounted) {
        // Check if notifier is still active
        state = todos;
      }
    } catch (e) {
      print('Error loading todos: $e');
      // If loading fails, keep existing state
    }
  }

  /// Get all todos (for DailyTodoNotifier)
  Future<List<Todo>> getAllTodos() async {
    return _repository.getAllTodos();
  }

  /// Get a specific todo by ID
  Future<Todo?> getTodoById(String id) async {
    try {
      // Otherwise try to get it from the repository
      return await _repository.getTodoById(id);
    } catch (e) {
      debugPrint('Error getting todo by ID $id: $e');
      return null;
    }
  }

  void addTodo(Todo todo) async {
    try {
      // Save the todo to repository
      await _repository.addTodo(todo);

      // Add the todo to its creation date for proper tracking
      final dailyTodoRepo = _ref.read(dailyTodoRepositoryProvider);
      final creationDate = normalizeDate(todo.createdAt);
      await dailyTodoRepo.addTodoToDate(creationDate, todo);

      // Reload todos from repository
      _loadTodos();
    } catch (e) {
      debugPrint('Error adding todo: $e');
      _loadTodos();
    }
  }

  void updateTodo(String id, Todo updated) async {
    try {
      // Optimistic update for better UI responsiveness
      state = state.map((todo) => todo.id == id ? updated : todo).toList();

      // Then persist to storage
      await _repository.updateTodo(updated);

      // Full refresh after storage update to ensure consistency
      await _loadTodos();
    } catch (e) {
      print('Error updating todo: $e');
      // Make sure we reload todos in case of error
      await _loadTodos();
    }
  }

  void deleteTodo(String id) async {
    try {
      final todoIndex = state.indexWhere((todo) => todo.id == id);
      if (todoIndex != -1) {
        final todo = state[todoIndex];
        final now = DateTime.now();

        // Create the updated todo with deleted status
        final updatedTodo = todo.copyWith(status: 2, endedOn: now);

        // Optimistic UI update first for responsiveness
        state = [...state.where((t) => t.id != id), updatedTodo];

        // 1. Update the todo with deleted status in repository
        await _repository.updateTodo(updatedTodo);

        // 2. Get the DailyTodo repository and today's date
        final dailyTodoRepo = _ref.read(dailyTodoRepositoryProvider);
        final deletionDate = normalizeDate(now);

        // 3. Get the current DailyTodo for today
        final dailyTodo = await dailyTodoRepo.getDailyTodoForDate(deletionDate);

        // 4. Add the deleted todo to today's DailyTodo.todos list
        final dailyTodos = List<Todo>.from(dailyTodo.todos);
        if (!dailyTodos.any((t) => t.id == updatedTodo.id)) {
          dailyTodos.add(updatedTodo);
        } else {
          // Replace the existing todo with the updated one
          final index = dailyTodos.indexWhere((t) => t.id == updatedTodo.id);
          if (index >= 0) {
            dailyTodos[index] = updatedTodo;
          }
        }

        // 5. Update the counters based on the todos list
        final completedCount = dailyTodos.where((t) => t.status == 1).length;
        final deletedCount = dailyTodos.where((t) => t.status == 2).length;

        // 6. Create an updated DailyTodo with the new counts
        final updatedDailyTodo = dailyTodo.copyWith(
          todos: dailyTodos,
          completedTodosCount: completedCount,
          deletedTodosCount: deletedCount,
        );

        // 7. Save the updated DailyTodo
        await dailyTodoRepo.saveDailyTodo(updatedDailyTodo);

        // 8. Notify the DailyTodo provider of the update
        _ref.read(dailyTodoProvider.notifier).forceReload();

        // 9. Full refresh for consistency
        await _loadTodos();

        debugPrint(
            '✅ Todo deleted and DailyTodo counters updated successfully: ${todo.title}');
      }
    } catch (e) {
      debugPrint('❌ Error deleting todo: $e');
      _loadTodos();
    }
  }

  void restoreTodo(String id) async {
    try {
      final todoIndex = state.indexWhere((todo) => todo.id == id);
      if (todoIndex != -1) {
        final todo = state[todoIndex];
        // No need for current time when restoring
        final updatedTodo = todo.copyWith(status: 0, endedOn: null);

        // Optimistic UI update
        state = [...state.where((t) => t.id != id), updatedTodo];

        // 1. Update the todo in repository
        await _repository.updateTodo(updatedTodo);

        // 2. Get the DailyTodo repository
        final dailyTodoRepo = _ref.read(dailyTodoRepositoryProvider);

        // 3. Add todo back to its creation date for proper tracking
        final creationDate = normalizeDate(todo.createdAt);

        // 4. Get current DailyTodo for creation date (where it should be tracked)
        final dailyTodo = await dailyTodoRepo.getDailyTodoForDate(creationDate);

        // 5. Add or update the restored todo in the DailyTodo.todos list
        final dailyTodos = List<Todo>.from(dailyTodo.todos);
        if (!dailyTodos.any((t) => t.id == updatedTodo.id)) {
          dailyTodos.add(updatedTodo);
        } else {
          // Replace the existing todo with the updated one
          final index = dailyTodos.indexWhere((t) => t.id == updatedTodo.id);
          if (index >= 0) {
            dailyTodos[index] = updatedTodo;
          }
        }

        // 6. Update the counters based on the todos list
        final completedCount = dailyTodos.where((t) => t.status == 1).length;
        final deletedCount = dailyTodos.where((t) => t.status == 2).length;

        // 7. Create updated DailyTodo with new counts
        final updatedDailyTodo = dailyTodo.copyWith(
          todos: dailyTodos,
          completedTodosCount: completedCount,
          deletedTodosCount: deletedCount,
        );

        // 8. Save the updated DailyTodo
        await dailyTodoRepo.saveDailyTodo(updatedDailyTodo);

        // 9. Also need to update the DailyTodo for the date when the todo was deleted/completed
        // as that will still be counting this todo
        if (todo.endedOn != null) {
          final endDate = normalizeDate(todo.endedOn!);
          if (!endDate.isAtSameMomentAs(creationDate)) {
            final endDateDailyTodo =
                await dailyTodoRepo.getDailyTodoForDate(endDate);
            final endDateTodos = List<Todo>.from(endDateDailyTodo.todos)
              ..removeWhere((t) => t.id == todo.id);

            final endDateCompletedCount =
                endDateTodos.where((t) => t.status == 1).length;
            final endDateDeletedCount =
                endDateTodos.where((t) => t.status == 2).length;

            final updatedEndDateDailyTodo = endDateDailyTodo.copyWith(
              todos: endDateTodos,
              completedTodosCount: endDateCompletedCount,
              deletedTodosCount: endDateDeletedCount,
            );

            await dailyTodoRepo.saveDailyTodo(updatedEndDateDailyTodo);
          }
        }

        // 10. Reload todoDate providers
        _ref.read(dailyTodoProvider.notifier).forceReload();

        // 11. Full refresh for consistency
        await _loadTodos();

        debugPrint(
            '✅ Todo restored and DailyTodo counters updated successfully: ${todo.title}');
      }
    } catch (e) {
      debugPrint('❌ Error restoring todo: $e');
      _loadTodos();
    }
  }

  /// Helper method to normalize a DateTime to midnight (00:00:00)
  DateTime normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  void completeTodo(String id) async {
    try {
      final todoIndex = state.indexWhere((todo) => todo.id == id);
      if (todoIndex != -1) {
        final todo = state[todoIndex];
        final now = DateTime.now();

        // Create updated todo with completed status
        final updatedTodo = todo.copyWith(
            status: 1,
            endedOn: now,
            // If there are subtasks, mark them all as completed too
            subtasks: todo.hasSubtasks && todo.subtasks != null
                ? todo.subtasks!
                    .map((subtask) => subtask.copyWith(status: 1, endedOn: now))
                    .toList()
                : todo.subtasks);

        // Optimistic UI update first for responsiveness
        state = [...state.where((t) => t.id != id), updatedTodo];

        // 1. Update the todo with completed status in repository
        await _repository.updateTodo(updatedTodo);

        // 2. Get the DailyTodo repository and today's date
        final dailyTodoRepo = _ref.read(dailyTodoRepositoryProvider);
        final completionDate = normalizeDate(now);

        // 3. Get the current DailyTodo for today
        final dailyTodo =
            await dailyTodoRepo.getDailyTodoForDate(completionDate);

        // 4. Add the completed todo to today's DailyTodo.todos list
        final dailyTodos = List<Todo>.from(dailyTodo.todos);
        if (!dailyTodos.any((t) => t.id == updatedTodo.id)) {
          dailyTodos.add(updatedTodo);
        } else {
          // Replace the existing todo with the updated one
          final index = dailyTodos.indexWhere((t) => t.id == updatedTodo.id);
          if (index >= 0) {
            dailyTodos[index] = updatedTodo;
          }
        }

        // 5. Update the counters based on the todos list
        final completedCount = dailyTodos.where((t) => t.status == 1).length;
        final deletedCount = dailyTodos.where((t) => t.status == 2).length;

        // 6. Create an updated DailyTodo with the new counts
        final updatedDailyTodo = dailyTodo.copyWith(
          todos: dailyTodos,
          completedTodosCount: completedCount,
          deletedTodosCount: deletedCount,
        );

        // 7. Save the updated DailyTodo
        await dailyTodoRepo.saveDailyTodo(updatedDailyTodo);

        // 8. Notify the DailyTodo provider of the update
        _ref.read(dailyTodoProvider.notifier).forceReload();

        // 9. Full refresh for consistency
        await _loadTodos();

        debugPrint(
            '✅ Todo completed and DailyTodo counters updated successfully: ${todo.title}');
      }
    } catch (e) {
      debugPrint('❌ Error completing todo: $e');
      _loadTodos();
    }
  }

  // Get todos by status
  Future<List<Todo>> getTodosByStatus(int status) async {
    return await _repository.getTodosByStatus(status);
  }

  // Get active todos
  Future<List<Todo>> getActiveTodos() async {
    return await _repository.getTodosByStatus(0);
  }

  // Get completed todos
  Future<List<Todo>> getCompletedTodos() async {
    return await _repository.getTodosByStatus(1);
  }

  // Get deleted todos
  Future<List<Todo>> getDeletedTodos() async {
    return await _repository.getTodosByStatus(2);
  }

  // Get todos with subtasks
  Future<List<Todo>> getTodosWithSubtasks() async {
    return await _repository.getTodosWithSubtasks();
  }

  // Get scheduled todos
  Future<List<Todo>> getScheduledTodos() async {
    return await _repository.getScheduledTodos();
  }

  // Get todos scheduled for today
  Future<List<Todo>> getTodosScheduledForToday() async {
    return await _repository.getTodosScheduledForToday();
  }
}
