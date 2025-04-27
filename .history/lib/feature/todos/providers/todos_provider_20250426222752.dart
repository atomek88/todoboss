import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todoApp/core/storage/storage_service.dart';
import 'package:todoApp/shared/providers/selected_date_provider.dart';
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

  return TodoListNotifier(repository);
});

class TodoListNotifier extends StateNotifier<List<Todo>> {
  final TodoRepository _repository;

  TodoListNotifier(this._repository) : super([]) {
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

  void addTodo(Todo todo) async {
    await _repository.addTodo(todo);
    _loadTodos(); // Reload todos from repository
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
    final todoIndex = state.indexWhere((todo) => todo.id == id);
    if (todoIndex != -1) {
      final todo = state[todoIndex];
      final updatedTodo = todo.copyWith(status: 2, endedOn: DateTime.now());
      await _repository.updateTodo(updatedTodo);
      _loadTodos();
    }
  }

  void restoreTodo(String id) async {
    final todoIndex = state.indexWhere((todo) => todo.id == id);
    if (todoIndex != -1) {
      final todo = state[todoIndex];
      final updatedTodo = todo.copyWith(status: 0, endedOn: null);
      await _repository.updateTodo(updatedTodo);
      _loadTodos();
    }
  }

  void completeTodo(String id) async {
    try {
      final todoIndex = state.indexWhere((todo) => todo.id == id);
      if (todoIndex != -1) {
        final todo = state[todoIndex];

        // Update the parent todo to completed status
        final updatedTodo = todo.copyWith(
            status: 1,
            completed: true,
            endedOn: DateTime.now(),
            // If there are subtasks, mark them all as completed too
            subtasks: todo.hasSubtasks
                ? todo.subtasks!
                    .map((subtask) => subtask.copyWith(
                        completed: true, status: 1, endedOn: DateTime.now()))
                    .toList()
                : todo.subtasks);

        // Make a local update first for immediate UI feedback
        state = [...state.where((t) => t.id != id), updatedTodo];

        // Then persist to storage
        await _repository.updateTodo(updatedTodo);

        // Full refresh after storage update
        await _loadTodos();
      }
    } catch (e) {
      print('Error completing todo: $e');
      // Make sure we reload todos in case of error
      await _loadTodos();
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
