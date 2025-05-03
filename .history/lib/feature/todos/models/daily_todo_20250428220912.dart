import 'package:flutter/foundation.dart';
import 'todo.dart';

/// A class representing a day's todo statistics
class DailyTodo {
  final String id; // DDMMYYYY format
  final DateTime date;
  final int taskGoal;
  final int completedTodosCount;
  final int deletedTodosCount;
  final List<String> todoIds; // IDs of todos for this date
  final String? summary; // Optional summary text for the day

  const DailyTodo({
    required this.id,
    required this.date,
    this.taskGoal = 0,
    this.completedTodosCount = 0,
    this.deletedTodosCount = 0,
    this.todoIds = const [],
    this.summary,
  });

  // Helper to create a DailyTodo from a DateTime
  factory DailyTodo.fromDate(DateTime date, {int taskGoal = 0}) {
    final id = _dateToId(date);
    return DailyTodo(
      id: id,
      date: DateTime(date.year, date.month, date.day),
      taskGoal: taskGoal,
    );
  }

  // Format date as DDMMYYYY
  static String _dateToId(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}${date.month.toString().padLeft(2, '0')}${date.year}';
  }

  // Parse date from DDMMYYYY
  static DateTime idToDate(String id) {
    final day = int.parse(id.substring(0, 2));
    final month = int.parse(id.substring(2, 4));
    final year = int.parse(id.substring(4));
    return DateTime(year, month, day);
  }

  // Create a DailyTodo from JSON data
  factory DailyTodo.fromJson(Map<String, dynamic> json) {
    return DailyTodo(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      taskGoal: json['taskGoal'] as int? ?? 0,
      completedTodosCount: json['completedTodosCount'] as int? ?? 0,
      deletedTodosCount: json['deletedTodosCount'] as int? ?? 0,
      todoIds: (json['todoIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      summary: json['summary'] as String?,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'taskGoal': taskGoal,
      'completedTodosCount': completedTodosCount,
      'deletedTodosCount': deletedTodosCount,
      'todoIds': todoIds,
      'summary': summary,
    };
  }

  // Clone with modifications
  DailyTodo copyWith({
    String? id,
    DateTime? date,
    int? taskGoal,
    int? completedTodosCount,
    int? deletedTodosCount,
    List<String>? todoIds,
    String? summary,
  }) {
    return DailyTodo(
      id: id ?? this.id,
      date: date ?? this.date,
      taskGoal: taskGoal ?? this.taskGoal,
      completedTodosCount: completedTodosCount ?? this.completedTodosCount,
      deletedTodosCount: deletedTodosCount ?? this.deletedTodosCount,
      todoIds: todoIds ?? this.todoIds,
      summary: summary,
    );
  }

  // Check if this DailyTodo is for today
  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  // Check if this DailyTodo is in the past
  bool get isPast {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return date.isBefore(today);
  }

  // Check if this DailyTodo is in the future
  bool get isFuture {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return date.isAfter(today);
  }

  // Get completion percentage
  double get completionPercentage {
    if (taskGoal <= 0) return 0.0;
    return (completedTodosCount / taskGoal) * 100;
  }

  // Generate a summary of the day's activity
  String generateSummary(List<Todo> todos) {
    final activeTodos = todos.where((todo) => todo.status == 0).length;

    return 'Completed $completedTodosCount/${todos.length} tasks. '
        '${deletedTodosCount > 0 ? 'Deleted $deletedTodosCount tasks. ' : ''}'
        '${taskGoal > 0 ? 'Daily goal: $completedTodosCount/$taskGoal (${completionPercentage.toStringAsFixed(0)}%). ' : ''}'
        '${activeTodos > 0 ? '$activeTodos tasks remaining.' : 'All tasks completed!'}';
  }

  // Add a todo ID to this date
  DailyTodo addTodoId(String todoId) {
    if (todoIds.contains(todoId)) return this;
    return copyWith(todoIds: [...todoIds, todoId]);
  }

  // Remove a todo ID from this date
  DailyTodo removeTodoId(String todoId) {
    if (!todoIds.contains(todoId)) return this;
    return copyWith(todoIds: todoIds.where((id) => id != todoId).toList());
  }

  // Update counters based on todos
  DailyTodo updateCounters(List<Todo> todos) {
    final completed = todos.where((todo) => todo.status == 1).length;
    final deleted = todos.where((todo) => todo.status == 2).length;

    return copyWith(
      completedTodosCount: completed,
      deletedTodosCount: deleted,
      summary: isPast ? generateSummary(todos) : null,
    );
  }

  @override
  String toString() {
    return 'DailyTodo(id: $id, date: $date, goal: $taskGoal, completed: $completedTodosCount, deleted: $deletedTodosCount)';
  }
}
