// lib/feature/todos/services/todo_service.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:todoApp/feature/todos/models/todo.dart';

part 'todo_service.g.dart';

@Riverpod(keepAlive: true)
TodosService todosService(TodosServiceRef ref) {
  return TodosService();
}

class TodosService {
  final List<Todo> _todos = [];

  List<Todo> get todos => _todos;

  void add(Todo todo) {
    _todos.add(todo);
  }

  void update(Todo todo) {
    final index = _todos.indexWhere((t) => t.id == todo.id);
    if (index != -1) {
      _todos[index] = todo;
    }
  }

  void remove(Todo todo) {
    _todos.removeWhere((t) => t.id == todo.id);
  }
}
