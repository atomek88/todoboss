import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:todoApp/feature/todos/models/daily_todo.dart';
import 'package:todoApp/feature/todos/models/todo.dart';

// This will be generated by build_runner
part 'daily_todo_isar.g.dart';

/// Isar model for DailyTodo
@collection
class DailyTodoIsar {
  // Isar ID - auto-incremented
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String dateId;

  late String dateIso;
  int taskGoal = 0;
  int completedTodosCount = 0;
  int deletedTodosCount = 0;

  @ignore
  List<Todo> todos = [];

  /// Store the todo IDs as a comma-separated string for Isar
  String todoIdsString = '';

  /// Summary text
  String? summary;

  /// Convert from domain model to Isar model
  static DailyTodoIsar fromDomain(DailyTodo todoDate) {
    final todoDateIsar = DailyTodoIsar()
      ..dateId = todoDate.id
      ..dateIso = todoDate.date.toIso8601String()
      ..taskGoal = todoDate.taskGoal
      ..completedTodosCount = todoDate.completedTodosCount
      ..deletedTodosCount = todoDate.deletedTodosCount
      ..todos = todoDate.todos
      ..todoIdsString = todoDate.todos.join(',')
      ..summary = todoDate.summary;

    debugPrint(
        '📆 [DailyTodoIsar] Created from domain: ${todoDate.id}, goal: ${todoDate.taskGoal}');
    return todoDateIsar;
  }

  /// Convert to domain model
  DailyTodo toDomain() {
    final date = DateTime.parse(dateIso);

    return DailyTodo(
      id: dateId,
      date: date,
      taskGoal: taskGoal,
      completedTodosCount: completedTodosCount,
      deletedTodosCount: deletedTodosCount,
      todos: todos,
      summary: summary,
    );
  }
}
