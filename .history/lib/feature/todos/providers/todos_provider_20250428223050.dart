import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:todoApp/core/storage/storage_service.dart';
import 'package:todoApp/feature/todos/providers/daily_todos_provider.dart';
import 'package:todoApp/core/providers/selected_date_provider.dart';
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
      final todoDateRepo = _ref.read(todoDateRepositoryProvider);
      final creationDate = normalizeDate(todo.createdAt);
      await todoDateRepo.addTodoToDate(creationDate, todo);

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
        final updatedTodo = todo.copyWith(status: 2, endedOn: now);

        // Update the todo with deleted status
        await _repository.updateTodo(updatedTodo);

        // Also add the todo to its deletion date for proper deletion counter tracking
        final todoDateRepo = _ref.read(todoDateRepositoryProvider);
        final deletionDate = normalizeDate(now);
        await todoDateRepo.addTodoToDate(deletionDate, todo);

        // Reload todos
        _loadTodos();
      }
    } catch (e) {
      debugPrint('Error deleting todo: $e');
      _loadTodos();
    }
  }

  void restoreTodo(String id) async {
    try {
      final todoIndex = state.indexWhere((todo) => todo.id == id);
      if (todoIndex != -1) {
        final todo = state[todoIndex];
        final updatedTodo = todo.copyWith(status: 0, endedOn: null);
        await _repository.updateTodo(updatedTodo);

        // Add the todo back to its original creation date for proper tracking
        final todoDateRepo = _ref.read(todoDateRepositoryProvider);
        final creationDate = normalizeDate(todo.createdAt);
        await todoDateRepo.addTodoToDate(creationDate, todo);

        _loadTodos();
      }
    } catch (e) {
      debugPrint('Error restoring todo: $e');
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

        // Update the todo with completed status
        await _repository.updateTodo(updatedTodo);

        // Also add the todo to its completion date for proper completion counter tracking
        final todoDateRepo = _ref.read(todoDateRepositoryProvider);
        final completionDate = normalizeDate(now);
        await todoDateRepo.addTodoToDate(completionDate, todo);

        // Reload todos
        _loadTodos();
      }
    } catch (e) {
      debugPrint('Error completing todo: $e');
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
