// lib/feature/todos/providers/todos_notifier.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:todoApp/feature/todos/models/todo.dart';
import 'package:todoApp/feature/todos/services/todo_service.dart';

// This will generate the code in todos_notifier.g.dart
part 'todos_notifier.g.dart';

@Riverpod(keepAlive: true)
class Todos extends _$Todos {
  // The build method is called when the provider is first used
  @override
  List<Todo> build() {
    return _service.todos;
  }

  TodosService get _service => ref.read(todosServiceProvider);
  List<Todo> get _serviceTodos => List.from(_service.todos);

  void add(Todo todo) {
    _service.add(todo);
    state = _serviceTodos;
  }

  void update(Todo todo) {
    _service.update(todo);
    state = _serviceTodos;
  }

  void remove(Todo todo) {
    _service.remove(todo);
    state = _serviceTodos;
  }
}
