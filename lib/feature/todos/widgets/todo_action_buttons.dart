import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/todo.dart';

/// A widget that provides action buttons for a todo item
class TodoActionButtons extends StatelessWidget {
  /// The todo to act upon
  final Todo todo;
  
  /// Whether actions should be disabled (read-only mode)
  final bool isReadOnly;
  
  /// Callback when todo is toggled via button
  final Function(String)? onToggle;
  final Function(Todo)? onComplete;
  
  /// Callback when todo is deleted via button
  final Function(String)? onDelete;
  final Function(Todo)? onDeleteLegacy;
  
  /// Callback when edit button is pressed
  final VoidCallback? onEdit;

  const TodoActionButtons({
    Key? key,
    required this.todo,
    this.isReadOnly = false,
    this.onToggle,
    this.onComplete,
    this.onDelete,
    this.onDeleteLegacy,
    this.onEdit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Toggle completion button
        IconButton(
          icon: todo.completed
              ? const Icon(Icons.check_circle, color: Colors.green)
              : const Icon(Icons.radio_button_unchecked),
          onPressed: isReadOnly
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  // Support both callback patterns
                  if (onToggle != null) {
                    onToggle!(todo.id);
                  } else if (onComplete != null) {
                    onComplete!(todo);
                  }
                },
        ),
        
        // Edit button - only shown if not read-only and not completed
        if (!isReadOnly && !todo.completed && onEdit != null)
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: onEdit,
          ),
        
        // Delete button - only shown if not read-only and not completed
        if (!isReadOnly && !todo.completed)
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              // Confirm delete with dialog
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Todo?'),
                  content: Text(
                      'Are you sure you want to delete "${todo.title}"?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('CANCEL'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        HapticFeedback.mediumImpact();
                        // Support both callback patterns
                        if (onDelete != null) {
                          onDelete!(todo.id);
                        } else if (onDeleteLegacy != null) {
                          onDeleteLegacy!(todo);
                        }
                      },
                      child: const Text('DELETE'),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}
