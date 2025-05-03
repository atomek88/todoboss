import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/todo.dart';
import 'todo_read_only_item.dart';
import 'todo_dismissible_container.dart';
import 'todo_interactive_card.dart';

/// A widget that displays a todo item with appropriate styling and interactions
/// based on the todo state and whether it's in read-only mode
class TodoListItem extends ConsumerWidget {
  final Todo todo;
  // Support both old and new callback patterns for backward compatibility
  final Function(Todo)? onComplete; // Legacy - takes Todo object
  final Function(Todo)? onDelete; // Legacy - takes Todo object
  final Function(String)? onToggle; // New - takes String ID
  final Function(String)? onDelete2; // New - takes String ID
  final bool isReadOnly;

  const TodoListItem({
    Key? key,
    required this.todo,
    this.onComplete,
    this.onDelete,
    this.onToggle,
    this.onDelete2,
    this.isReadOnly = false,
  }) : super(key: key);

  /// Delegate methods for the legacy callback pattern
  void _handleLegacyComplete(Todo todo) {
    if (onComplete != null) {
      onComplete!(todo);
    }
  }

  /// Delegate methods for the legacy delete pattern
  void _handleLegacyDelete(Todo todo) {
    if (onDelete != null) {
      onDelete!(todo);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use the read-only implementation if specified
    if (isReadOnly) {
      return TodoReadOnlyItem(todo: todo);
    }

    // For interactive mode, check if we're using legacy or new callbacks
    if (onComplete != null || onDelete != null) {
      // Legacy mode using object-based callbacks
      return TodoDismissibleContainer(
        todo: todo,
        onComplete: _handleLegacyComplete,
        onDelete: _handleLegacyDelete,
        child: TodoInteractiveCard(
          todo: todo,
          onToggle: (id) => _handleLegacyComplete(todo),
          onDelete: (id) => _handleLegacyDelete(todo),
        ),
      );
    } else {
      // Modern mode using ID-based callbacks
      return TodoInteractiveCard(
        todo: todo,
        onToggle: onToggle,
        onDelete: onDelete2,
      );
    }
  }
}
