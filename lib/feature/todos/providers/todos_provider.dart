import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todoApp/core/storage/storage_service.dart';
import '../models/todo.dart';
import '../repositories/todo_repository.dart';

// Provider for the TodoRepository
final todoRepositoryProvider = Provider<TodoRepository>((ref) {
  return TodoRepository(ref.watch(storageServiceProvider));
});

// Provider for the list of todos
final todoListProvider = StateNotifierProvider<TodoListNotifier, List<Todo>>(
    (ref) => TodoListNotifier(ref.watch(todoRepositoryProvider)));

class TodoListNotifier extends StateNotifier<List<Todo>> {
  final TodoRepository _repository;

  TodoListNotifier(this._repository) : super([]) {
    _loadTodos();
  }

  Future<void> _loadTodos() async {
    final todos = await _repository.getTodos();
    state = todos;
  }

  void addTodo(Todo todo) async {
    await _repository.addTodo(todo);
    _loadTodos(); // Reload todos from repository
  }

  void updateTodo(String id, Todo updated) async {
    await _repository.updateTodo(updated);
    _loadTodos();
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
    final todoIndex = state.indexWhere((todo) => todo.id == id);
    if (todoIndex != -1) {
      final todo = state[todoIndex];
      
      // Update the parent todo to completed status
      final updatedTodo = todo.copyWith(
        status: 1, 
        endedOn: DateTime.now(),
        // If there are subtasks, mark them all as completed too
        subtasks: todo.hasSubtasks ? 
          todo.subtasks!.map((subtask) => 
            subtask.copyWith(completed: true, status: 1, endedOn: DateTime.now())
          ).toList() : 
          todo.subtasks
      );
      
      await _repository.updateTodo(updatedTodo);
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
