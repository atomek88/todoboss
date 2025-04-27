import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';

part 'todo.freezed.dart';
part 'todo.g.dart';

/// Todo model with additional properties using freezed
@freezed
class Todo with _$Todo {
  // Add this constructor for custom methods
  const Todo._();

  // Private constructor for freezed
  @JsonSerializable(explicitToJson: true)
  const factory Todo({
    required String id,
    required String title,
    String? description,
    @Default(false) bool completed,
    @Default(0) int priority, // 0: low, 1: medium, 2: high
    @Default(true) bool rollover,
    @Default(0) int status, // 0: active, 1: completed, 2: deleted
    required DateTime createdAt,
    DateTime? endedOn,
    @Default(<int>{})
    Set<int> scheduled, // Set of weekdays (1-7, where 1 is Monday)
    List<Todo>? subtasks, // New property for subtasks
  }) = _Todo;

  // Factory for creating a new Todo with auto-generated ID
  factory Todo.create({
    required String title,
    String? description,
    bool completed = false,
    int priority = 0,
    bool rollover = true,
    int status = 0,
    Set<int>? scheduled,
    List<Todo>? subtasks,
    DateTime? createdAt,
    DateTime? endedOn,
  }) {
    return Todo(
      id: const Uuid().v4(),
      title: title,
      description: description,
      completed: completed,
      priority: priority,
      rollover: rollover,
      status: status,
      scheduled: scheduled ?? <int>{},
      subtasks: subtasks,
      createdAt: createdAt ?? DateTime.now(),
      endedOn: endedOn,
    );
  }

  // From JSON factory
  factory Todo.fromJson(Map<String, dynamic> json) => _$TodoFromJson(json);

  // Helper methods
  bool get isLowPriority => priority == 0;
  bool get isMediumPriority => priority == 1;
  bool get isHighPriority => priority == 2;

  bool get isActive => status == 0;
  bool get isCompleted => status == 1;
  bool get isDeleted => status == 2;

  bool get hasSubtasks => subtasks != null && subtasks!.isNotEmpty;
  bool get isScheduled => scheduled.isNotEmpty;

  // Check if todo is scheduled for a specific day
  bool isScheduledForDay(int weekday) => scheduled.contains(weekday);

  // Check if todo is scheduled for todays
  bool get isScheduledForToday => scheduled.contains(DateTime.now().weekday);

  // Get a formatted string of scheduled days
  String get scheduledDaysText {
    if (scheduled.isEmpty) return 'Not scheduled';

    const dayNames = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final days = scheduled.toList()..sort();
    return days.map((day) => dayNames[day]).join(', ');
  }
}
