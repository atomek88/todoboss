import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/todo.dart';

/// A widget that provides swipe actions for todo items
class TodoSwipeActions extends StatelessWidget {
  /// The todo to act upon
  final Todo todo;
  
  /// Callback when todo is completed via swipe
  final Function(String)? onToggle;
  final Function(Todo)? onComplete;
  
  /// Callback when todo is deleted via swipe
  final Function(String)? onDelete;
  final Function(Todo)? onDeleteLegacy;
  
  /// The widget to wrap with swipe actions
  final Widget child;

  const TodoSwipeActions({
    Key? key,
    required this.todo,
    required this.child,
    this.onToggle,
    this.onComplete,
    this.onDelete,
    this.onDeleteLegacy,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Define swipe properties
    final isCompleted = todo.completed;

    return Dismissible(
      key: ValueKey('dismissible-${todo.id}'),
      // Swipe from left to complete
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20.0),
        color: isCompleted ? Colors.orange : Colors.green,
        child: Icon(
          isCompleted ? Icons.replay : Icons.check,
          color: Colors.white,
        ),
      ),
      // Swipe from right to delete
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        color: Colors.red,
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      // Confirmation before dismissal (crucial for both directions)
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Provide haptic feedback for completion
          HapticFeedback.mediumImpact();
          
          // Handle completion with either callback pattern
          if (onToggle != null) {
            onToggle!(todo.id);
          } else if (onComplete != null) {
            onComplete!(todo);
          }
          
          // Return false to prevent actual dismissal from widget tree
          // This fixes the "dismissed Dismissible widget still in tree" error
          return false;
        } else if (direction == DismissDirection.endToStart) {
          // For delete action, show confirmation dialog
          HapticFeedback.mediumImpact();
          
          // Return the result of the dialog (true if user confirms delete)
          return await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Delete Todo?'),
              content: Text(
                'Are you sure you want to delete "${todo.title}"?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('CANCEL'),
                ),
                TextButton(
                  onPressed: () {
                    // Handle deletion with either callback pattern
                    if (onDelete != null) {
                      onDelete!(todo.id);
                    } else if (onDeleteLegacy != null) {
                      onDeleteLegacy!(todo);
                    }
                    Navigator.of(context).pop(true);
                  },
                  child: const Text('DELETE'),
                ),
              ],
            ),
          ) ?? false; // Default to false if dialog is dismissed
        }
        return false;
      },
      // We don't need onDismissed anymore since we handle actions in confirmDismiss
      // This prevents the error by avoiding duplicate handling
      onDismissed: (_) {}, // Empty implementation required by Dismissible
      child: child,
    );
  }
}
