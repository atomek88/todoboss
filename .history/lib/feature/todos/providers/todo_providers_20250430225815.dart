import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todoApp/core/globals.dart';
import 'package:todoApp/core/storage/storage_service.dart';
import '../models/todo.dart';
import '../repositories/todo_repository.dart';

// Provider for TodoRepository
final todoRepositoryProvider = Provider<TodoRepository>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  return TodoRepository(storageService);
});

// Provider for TodoList
final todoListProvider = FutureProvider<List<Todo>>((ref) async {
  final repository = ref.watch(todoRepositoryProvider);
  return repository.getAllTodos();
});

// Notifier for TodoList operations
class TodoListNotifier extends StateNotifier<AsyncValue<List<Todo>>> {
  final TodoRepository _repository;

  TodoListNotifier(this._repository) : super(const AsyncValue.loading()) {
    _loadTodos();
  }

  Future<void> _loadTodos() async {
    state = const AsyncValue.loading();
    try {
      final todos = await _repository.getAllTodos();
      state = AsyncValue.data(todos);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addTodo(Todo todo) async {
    state = const AsyncValue.loading();
    try {
      final currentTodos = state.value ?? [];
      final updatedTodos = [...currentTodos, todo];
      await _repository.saveTodos(updatedTodos);
      state = AsyncValue.data(updatedTodos);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateTodo(String id, Todo updated) async {
    state = const AsyncValue.loading();
    try {
      final currentTodos = state.value ?? [];
      final index = currentTodos.indexWhere((todo) => todo.id == id);

      if (index != -1) {
        final updatedTodos = [...currentTodos];
        updatedTodos[index] = updated;
        await _repository.saveTodos(updatedTodos);
        state = AsyncValue.data(updatedTodos);
      } else {
        state = AsyncValue.data(currentTodos);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteTodo(String id) async {
    state = const AsyncValue.loading();
    try {
      final currentTodos = state.value ?? [];
      final todoIndex = currentTodos.indexWhere((todo) => todo.id == id);

      if (todoIndex != -1) {
        final todo = currentTodos[todoIndex];
        final updatedTodo = todo.copyWith(status: 2, endedOn: DateTime.now());
        final updatedTodos = [...currentTodos];
        updatedTodos[todoIndex] = updatedTodo;
        await _repository.saveTodos(updatedTodos);
        state = AsyncValue.data(updatedTodos);
      } else {
        state = AsyncValue.data(currentTodos);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> completeTodo(String id) async {
    state = const AsyncValue.loading();
    try {
      final currentTodos = state.value ?? [];
      final todoIndex = currentTodos.indexWhere((todo) => todo.id == id);

      if (todoIndex != -1) {
        final todo = currentTodos[todoIndex];
        final updatedTodo = todo.copyWith(status: 1, endedOn: DateTime.now());
        final updatedTodos = [...currentTodos];
        updatedTodos[todoIndex] = updatedTodo;
        await _repository.saveTodos(updatedTodos);
        state = AsyncValue.data(updatedTodos);
      } else {
        state = AsyncValue.data(currentTodos);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> restoreTodo(String id) async {
    state = const AsyncValue.loading();
    try {
      final currentTodos = state.value ?? [];
      final todoIndex = currentTodos.indexWhere((todo) => todo.id == id);

      if (todoIndex != -1) {
        final todo = currentTodos[todoIndex];
        final updatedTodo = todo.copyWith(status: 0, endedOn: null);
        final updatedTodos = [...currentTodos];
        updatedTodos[todoIndex] = updatedTodo;
        await _repository.saveTodos(updatedTodos);
        state = AsyncValue.data(updatedTodos);
      } else {
        state = AsyncValue.data(currentTodos);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

// Provider for TodoListNotifier
final todoListNotifierProvider =
    StateNotifierProvider<TodoListNotifier, AsyncValue<List<Todo>>>((ref) {
  final repository = ref.watch(todoRepositoryProvider);
  return TodoListNotifier(repository);
});

// Provider for active todos
final activeTodosProvider = Provider<AsyncValue<List<Todo>>>((ref) {
  final todosAsync = ref.watch(todoListNotifierProvider);
  return todosAsync.whenData(
    (todos) => todos.where((todo) => todo.status == 0).toList(),
  );
});

// Provider for completed todos
final completedTodosProvider = Provider<AsyncValue<List<Todo>>>((ref) {
  final todosAsync = ref.watch(todoListNotifierProvider);
  return todosAsync.whenData(
    (todos) => todos.where((todo) => todo.status == 1).toList(),
  );
});

// Provider for deleted todos
final deletedTodosProvider = Provider<AsyncValue<List<Todo>>>((ref) {
  final todosAsync = ref.watch(todoListNotifierProvider);
  return todosAsync.whenData(
    (todos) => todos.where((todo) => todo.status == 2).toList(),
  );
});
