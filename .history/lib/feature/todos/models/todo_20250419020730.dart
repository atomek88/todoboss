import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';

part 'todo.freezed.dart';
part 'todo.g.dart';

@freezed
class Todo with _$Todo {
  Todo._();

  // Factory constructor with all properties
  factory Todo({
    @JsonKey(name: 'id') required String id,
    @JsonKey(name: 'title') required String title,
    @JsonKey(name: 'description') String? description,
    @JsonKey(name: 'completed') @Default(false) bool completed,

    // New properties
    @JsonKey(name: 'priority')
    required int priority, // 0: low, 1: medium, 2: high
    @JsonKey(name: 'rollover') required bool rollover,
    @JsonKey(name: 'status')
    required int status, // 0: active, 1: completed, 2: deleted
    @JsonKey(name: 'created_at')
    @Default(DateTime.now())
    required DateTime createdAt,
    @JsonKey(name: 'ended_on') DateTime? endedOn,
  }) = _Todo;

  // Factory for creating a new Todo with auto-generated ID
  factory Todo.create({
    required String title,
    String? description,
    bool completed = false,
    int priority = 0,
    bool rollover = false,
    int status = 0,
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
}
