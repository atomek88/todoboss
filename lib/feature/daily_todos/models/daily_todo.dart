import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:json_annotation/json_annotation.dart';
import '../../todos/models/todo.dart';

part 'daily_todo.freezed.dart';
part 'daily_todo.g.dart';

/// A class representing a day's todo statistics
@freezed
class DailyTodo with _$DailyTodo {
  const DailyTodo._(); // Private constructor for custom methods

  /// Default constructor for DailyTodo
  @JsonSerializable(explicitToJson: true)
  const factory DailyTodo({
    required String id, // DDMMYYYY format
    required DateTime date,
    @Default(0) int taskGoal,
    @Default(0) int completedTodosCount,
    @Default(0) int deletedTodosCount,
    @Default([]) List<Todo> todos, // List of todos for this date
    String? summary, // Optional summary text for the day
  }) = _DailyTodo;

  /// Helper to create a DailyTodo from a DateTime
  factory DailyTodo.fromDate(DateTime date, {int taskGoal = 0}) {
    final id = _dateToId(date);
    return DailyTodo(
      id: id,
      date: DateTime(date.year, date.month, date.day),
      taskGoal: taskGoal,
    );
  }

  /// Create from JSON
  factory DailyTodo.fromJson(Map<String, dynamic> json) =>
      _$DailyTodoFromJson(json);

  /// Format date as DDMMYYYY
  static String _dateToId(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}${date.month.toString().padLeft(2, '0')}${date.year}';
  }

  /// Parse date from DDMMYYYY
  static DateTime idToDate(String id) {
    final day = int.parse(id.substring(0, 2));
    final month = int.parse(id.substring(2, 4));
    final year = int.parse(id.substring(4));
    return DateTime(year, month, day);
  }

  /// Get todos by status
  List<Todo> getTodosByStatus(int status) {
    return todos.where((todo) => todo.status == status).toList();
  }

  /// Get todos by priority
  List<Todo> getTodosByPriority(int priority) {
    return todos.where((todo) => todo.priority == priority).toList();
  }

  /// Get active todos (not completed or deleted)
  List<Todo> get activeTodos {
    return todos.where((todo) => todo.status == 0).toList();
  }

  /// Get completed todos
  List<Todo> get completedTodos {
    return todos.where((todo) => todo.status == 1).toList();
  }

  /// Get deleted todos
  List<Todo> get deletedTodos {
    return todos.where((todo) => todo.status == 2).toList();
  }

  /// Generate a summary of the day's activity
  String generateSummary() {
    final activeTodos = todos.where((todo) => todo.status == 0).length;

    return 'Completed $completedTodosCount/${todos.length} tasks. '
        '${deletedTodosCount > 0 ? 'Deleted $deletedTodosCount tasks. ' : ''}'
        '${taskGoal > 0 ? 'Daily goal: $completedTodosCount/$taskGoal (${completionPercentage.toStringAsFixed(0)}%). ' : ''}'
        '${activeTodos > 0 ? '$activeTodos tasks remaining.' : 'All tasks completed!'}';
  }

  /// Check if this DailyTodo is for today
  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Check if this DailyTodo is in the past
  bool get isPast {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return date.isBefore(today);
  }

  /// Check if this DailyTodo is in the future
  bool get isFuture {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return date.isAfter(today);
  }

  /// Calculate completion percentage
  double get completionPercentage {
    if (taskGoal <= 0) return 0;
    return (completedTodosCount / taskGoal) * 100;
  }

  /// Add a todo to this DailyTodo
  DailyTodo addTodo(Todo todo) {
    if (todos.any((existingTodo) => existingTodo.id == todo.id)) {
      return this; // Already contains this todo
    }

    final updatedTodos = List<Todo>.from(todos)..add(todo);
    return copyWith(todos: updatedTodos);
  }

  /// Remove a todo from this DailyTodo
  DailyTodo removeTodo(Todo todo) {
    if (!todos.any((existingTodo) => existingTodo.id == todo.id)) {
      return this; // Doesn't contain this todo
    }

    final updatedTodos = List<Todo>.from(todos)
      ..removeWhere((existingTodo) => existingTodo.id == todo.id);
    return copyWith(todos: updatedTodos);
  }

  /// Clear all todos from this DailyTodo
  DailyTodo clearTodos() {
    return copyWith(todos: []);
  }

  /// Update counters based on todos
  DailyTodo updateCounters(List<Todo> todos) {
    final completed = todos.where((todo) => todo.status == 1).length;
    final deleted = todos.where((todo) => todo.status == 2).length;

    return copyWith(
      completedTodosCount: completed,
      deletedTodosCount: deleted,
    );
  }

  @override
  String toString() {
    return 'DailyTodo(id: $id, date: $date, goal: $taskGoal, completed: $completedTodosCount, deleted: $deletedTodosCount)';
  }
}
