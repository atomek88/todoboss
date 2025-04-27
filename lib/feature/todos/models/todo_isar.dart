import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:todoApp/feature/todos/models/todo.dart';
import 'package:uuid/uuid.dart';

part 'todo_isar.g.dart';

/// Isar model for Todo
@collection
class TodoIsar {
  // Isar ID - auto-incremented
  Id id = Isar.autoIncrement;

  /// Unique string ID (UUID)
  @Index(unique: true, replace: true)
  late String uuid;

  /// Title of the todo
  late String title;

  /// Optional description
  String? description;

  /// Whether the todo is completed
  bool completed = false;

  /// Priority level (0: low, 1: medium, 2: high)
  int priority = 0;

  /// Whether to roll over the todo to the next day if not completed
  bool rollover = true;

  /// Status of the todo (0: active, 1: completed, 2: deleted)
  int status = 0;

  /// Creation date
  late DateTime createdAt;

  /// Date when the todo was completed or deleted
  DateTime? endedOn;

  /// Days of week when this todo is scheduled (1-7, where 1 is Monday)
  List<int> scheduledDays = [];

  /// Optional subtasks stored as JSON strings
  List<String> subtasks = [];

  /// Convert from domain model to Isar model
  static TodoIsar fromDomain(Todo todo) {
    final todoIsar = TodoIsar()
      ..uuid = todo.id
      ..title = todo.title
      ..description = todo.description
      ..completed = todo.completed
      ..priority = todo.priority
      ..rollover = todo.rollover
      ..status = todo.status
      ..createdAt = todo.createdAt
      ..endedOn = todo.endedOn
      ..scheduledDays = todo.scheduled.toList();

    // Convert subtasks if available
    if (todo.subtasks != null && todo.subtasks!.isNotEmpty) {
      // Properly encode subtasks as JSON strings
      todoIsar.subtasks = todo.subtasks!
          .map((subtask) => jsonEncode(subtask.toJson()))
          .toList();
      
      debugPrint('📦 [TodoIsar] Encoded ${todo.subtasks!.length} subtasks for ${todo.title}');
    }

    return todoIsar;
  }

  /// Convert to domain model
  Todo toDomain() {
    // Convert scheduled days from List<int> to Set<int>
    final scheduledSet = Set<int>.from(scheduledDays);
    
    // Convert subtasks from JSON strings to Todo objects if available
    List<Todo>? domainSubtasks;
    if (subtasks.isNotEmpty) {
      try {
        domainSubtasks = subtasks.map((subtaskJson) {
          try {
            // Properly decode the JSON string
            final Map<String, dynamic> jsonMap = jsonDecode(subtaskJson);
            return Todo.fromJson(jsonMap);
          } catch (e) {
            debugPrint('📦 [TodoIsar] Error parsing individual subtask: $e');
            // Skip this subtask
            return null;
          }
        })
        .where((subtask) => subtask != null) // Filter out null subtasks
        .cast<Todo>() // Cast to correct type
        .toList();
        
        debugPrint('📦 [TodoIsar] Successfully parsed ${domainSubtasks.length} subtasks');
      } catch (e) {
        debugPrint('📦 [TodoIsar] Error parsing subtasks collection: $e');
        // Return empty list if parsing fails
        domainSubtasks = [];
      }
    }

    return Todo(
      id: uuid,
      title: title,
      description: description,
      completed: completed,
      priority: priority,
      rollover: rollover,
      status: status,
      createdAt: createdAt,
      endedOn: endedOn,
      scheduled: scheduledSet,
      subtasks: domainSubtasks,
    );
  }

  /// Factory method to create a new TodoIsar
  static TodoIsar create({
    required String title,
    String? description,
    int priority = 0,
    bool rollover = true,
    Set<int>? scheduled,
    List<TodoIsar>? subtasks,
  }) {
    final todoIsar = TodoIsar()
      ..uuid = const Uuid().v4()
      ..title = title
      ..description = description
      ..priority = priority
      ..rollover = rollover
      ..createdAt = DateTime.now()
      ..status = 0
      ..completed = false
      ..scheduledDays = scheduled?.toList() ?? [];

    // Convert subtasks if available
    if (subtasks != null && subtasks.isNotEmpty) {
      // Properly encode subtasks as JSON strings
      todoIsar.subtasks = subtasks
          .map((subtask) => jsonEncode(subtask.toDomain().toJson()))
          .toList();
          
      debugPrint('📦 [TodoIsar] Created ${subtasks.length} encoded subtasks');
    }

    return todoIsar;
  }
}
