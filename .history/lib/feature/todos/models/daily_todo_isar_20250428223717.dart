import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:todoApp/feature/todos/models/daily_todo.dart';
import 'package:todoApp/feature/todos/models/todo.dart';
import 'package:todoApp/feature/todos/models/todo_isar.dart';

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

  /// Summary text
  String? summary;

  /// Convert from domain model to Isar model
  static DailyTodoIsar fromDomain(DailyTodo dailyTodo) {
    final dailyTodoIsar = DailyTodoIsar()
      ..dateId = dailyTodo.id
      ..dateIso = dailyTodo.date.toIso8601String()
      ..taskGoal = dailyTodo.taskGoal
      ..completedTodosCount = dailyTodo.completedTodosCount
      ..deletedTodosCount = dailyTodo.deletedTodosCount
      ..todos = dailyTodo.todos
      ..summary = dailyTodo.summary;

    debugPrint(
        '📆 [DailyTodoIsar] Created from domain: ${dailyTodo.id}, goal: ${dailyTodo.taskGoal}, todos: ${dailyTodo.todos.length}');
    return dailyTodoIsar;
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
