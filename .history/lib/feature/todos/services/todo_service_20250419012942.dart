import 'package:todoApp/feature/todos/models/todo.dart';

class TodosService {
  List<Todo> todos = [];

  void add(Todo todo) {
    todos.add(todo);
  }

  void remove(Todo todo) {
    todos.remove(todo);
  }

  void update(Todo todo) {
    final index = todos.indexWhere((element) => element.id == todo.id);
    todos[index] = todo;
  }
}
