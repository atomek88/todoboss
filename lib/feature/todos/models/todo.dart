import 'package:uuid/uuid.dart';

/// Todo model with additional properties as requested
class Todo {
  final String id;
  final String title;
  final String? description;
  final bool completed;
  
  // New properties
  final int priority; // 0: low, 1: medium, 2: high
  final bool rollover;
  final int status; // 0: active, 1: completed, 2: deleted
  final DateTime createdAt;
  final DateTime? endedOn;

  // Constructor for creating a new Todo with auto-generated ID
  Todo({
    required this.title,
    this.description,
    this.completed = false,
    this.priority = 0,
    this.rollover = true,
    this.status = 0,
    DateTime? createdAt,
    this.endedOn,
  }) : 
    id = const Uuid().v4(),
    createdAt = createdAt ?? DateTime.now();

  // Internal constructor with all fields
  Todo._internal({
    required this.id,
    required this.title,
    required this.description,
    required this.completed,
    required this.priority,
    required this.rollover,
    required this.status,
    required this.createdAt,
    required this.endedOn,
  });
  
  // Factory for creating a Todo with an existing ID (e.g., from database)
  factory Todo.withId({
    required String id,
    required String title,
    String? description,
    bool completed = false,
    int priority = 0,
    bool rollover = true,
    int status = 0,
    required DateTime createdAt,
    DateTime? endedOn,
  }) {
    return Todo._internal(
      id: id,
      title: title,
      description: description,
      completed: completed,
      priority: priority,
      rollover: rollover,
      status: status,
      createdAt: createdAt,
      endedOn: endedOn,
    );
  }

  // CopyWith method for creating a new Todo with some properties changed
  Todo copyWith({
    String? title,
    String? description,
    bool? completed,
    int? priority,
    bool? rollover,
    int? status,
    DateTime? createdAt,
    DateTime? endedOn,
  }) {
    return Todo._internal(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      completed: completed ?? this.completed,
      priority: priority ?? this.priority,
      rollover: rollover ?? this.rollover,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      endedOn: endedOn ?? this.endedOn,
    );
  }

  // From JSON factory
  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo._internal(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      completed: json['completed'] as bool? ?? false,
      priority: json['priority'] as int? ?? 0,
      rollover: json['rollover'] as bool? ?? true,
      status: json['status'] as int? ?? 0,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : DateTime.now(),
      endedOn: json['ended_on'] != null 
          ? DateTime.parse(json['ended_on'] as String) 
          : null,
    );
  }

  // To JSON method
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'completed': completed,
      'priority': priority,
      'rollover': rollover,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'ended_on': endedOn?.toIso8601String(),
    };
  }

  // Helper methods
  bool get isLowPriority => priority == 0;
  bool get isMediumPriority => priority == 1;
  bool get isHighPriority => priority == 2;

  bool get isActive => status == 0;
  bool get isCompleted => status == 1;
  bool get isDeleted => status == 2;
  
  @override
  String toString() => 'Todo(id: $id, title: $title, completed: $completed, priority: $priority, status: $status)';
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Todo &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          description == other.description &&
          completed == other.completed &&
          priority == other.priority &&
          rollover == other.rollover &&
          status == other.status;

  @override
  int get hashCode => id.hashCode ^ title.hashCode ^ completed.hashCode;
}
