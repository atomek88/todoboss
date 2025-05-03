import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/todo.dart';
import 'todo_form_modal.dart';
import 'components/todo_subtask_section.dart';
import 'components/todo_status_indicator.dart';
import 'components/todo_priority_indicator.dart';
import 'components/todo_subtask_indicators.dart';
import 'todo_swipe_actions.dart';

// Provider to track expanded state of todo items
final _expandedTodoItemsProvider =
    StateProvider.family<bool, String>((ref, todoId) => false);

class TodoListItem extends ConsumerWidget {
  /// The todo item to display
  final Todo todo;
  
  // Support both old and new callback patterns for backward compatibility
  /// Legacy callback for completing a todo - takes Todo object
  final Function(Todo)? onComplete;
  
  /// Legacy callback for deleting a todo - takes Todo object
  final Function(Todo)? onDelete;
  
  /// Callback for toggling a todo completion status - takes String ID
  final Function(String)? onToggle;
  
  /// Callback for deleting a todo - takes String ID
  final Function(String)? onDelete2;
  
  /// Whether the todo item is read-only (non-interactive)
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use the todo.hasSubtasks getter from the model
    final hasSubtasks = todo.hasSubtasks;

    // Create the card content - this will be used in both read-only and swipeable modes
    Widget cardContent = Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      // Use TodoPriorityIndicator's color method rather than implementing it inline
      color: TodoPriorityIndicator(priority: todo.priority, opacity: 0.4).priorityColor(),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text(
              todo.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (todo.description != null && todo.description!.isNotEmpty)
                  Text(
                    todo.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                // Show subtask indicators if there are subtasks
                if (todo.hasSubtasks)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: TodoSubtaskIndicators(todo: todo),
                  ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Use the TodoStatusIndicator component
                TodoStatusIndicator(status: todo.status),
                const SizedBox(width: 4),
                // Only show expand/collapse button if there are subtasks
                if (hasSubtasks)
                  GestureDetector(
                    onTap: () {
                      // Toggle the expansion state
                      final currentState = ref.read(_expandedTodoItemsProvider(todo.id));
                      ref.read(_expandedTodoItemsProvider(todo.id).notifier).state = !currentState;
                      
                      // Log for debugging
                      debugPrint(
                          '🔍 [TodoListItem] Toggled subtasks for ${todo.id} - ${todo.title}: ${!currentState}');
                    },
                    child: Icon(
                      // Show up/down arrow based on current state
                      ref.watch(_expandedTodoItemsProvider(todo.id))
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 20,
                    ),
                  ),
              ],
            ),
            onTap: isReadOnly
                ? null
                : () => showTodoFormModal(context, todo: todo),
          ),

          // Subtasks section if expanded
          if (hasSubtasks && ref.watch(_expandedTodoItemsProvider(todo.id)))
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: TodoSubtaskSection(parentTodo: todo),
            ),
        ],
      ),
    );

    // For read-only mode, just return the card content
    if (isReadOnly) {
      return cardContent;
    }

    // For interactive mode, use the TodoSwipeActions component
    // This handles all the swipe gestures and callback invocation
    return TodoSwipeActions(
      todo: todo,
      onToggle: onToggle, // For new callback pattern using id
      onComplete: onComplete, // For legacy callback pattern using Todo object
      onDelete: onDelete2, // For new callback pattern using id
      onDeleteLegacy: onDelete, // For legacy callback pattern using Todo object
      child: cardContent,
    );
  }
}
