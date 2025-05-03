import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todoApp/feature/todos/models/todo.dart';
import 'package:todoApp/feature/todos/widgets/todo_form_modal.dart';
import 'package:todoApp/feature/todos/widgets/todo_priority_indicator.dart';
import 'package:todoApp/feature/todos/widgets/todo_subtask_indicator.dart';
import 'package:todoApp/feature/todos/widgets/todo_subtask_section.dart';

/// The interactive card component for todo items when they're editable
class TodoInteractiveCard extends ConsumerWidget {
  final Todo todo;
  final Function(String)? onToggle;
  final Function(String)? onDelete;

  // Use the same provider as TodoReadOnlyItem for consistency
  final _expandedTodoItemsProvider =
      StateProvider.family<bool, String>((ref, todoId) => false);

  TodoInteractiveCard({
    Key? key,
    required this.todo,
    this.onToggle,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => showTodoFormModal(context, todo: todo),
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        color: TodoPriorityIndicator.getColor(todo.priority).withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Checkbox or completion indicator
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, left: 4.0),
                    child: IconButton(
                      icon: todo.completed
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : const Icon(Icons.radio_button_unchecked),
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        if (onToggle != null) {
                          onToggle!.call(todo.id);
                        }
                      },
                    ),
                  ),

                  // Main content - title, description, etc.
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Todo title with possible line-through if completed
                          Text(
                            todo.title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              decoration: todo.completed
                                  ? TextDecoration.lineThrough
                                  : null,
                              color:
                                  todo.completed ? Colors.grey : Colors.black,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),

                          // Description if available
                          if (todo.description != null &&
                              todo.description!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                todo.description!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                  decoration: todo.completed
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),

                          // Show due date if scheduled
                          if (todo.scheduled != null &&
                              todo.scheduled!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 12,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatScheduledDate(todo.scheduled!),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Right side actions and indicators
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Subtask indicators
                      if (todo.hasSubtasks)
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0, top: 8.0),
                          child: TodoSubtaskIndicator(todo: todo),
                        ),

                      // Action buttons
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Subtasks button
                          if (todo.hasSubtasks)
                            IconButton(
                              icon: Icon(
                                ref.watch(_expandedTodoItemsProvider(todo.id))
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                                size: 20,
                              ),
                              onPressed: () {
                                final currentState = ref
                                    .read(_expandedTodoItemsProvider(todo.id));
                                ref
                                    .read(_expandedTodoItemsProvider(todo.id)
                                        .notifier)
                                    .state = !currentState;
                              },
                            ),

                          // Delete button - only shown if not completed
                          if (!todo.completed)
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
                                        onPressed: () =>
                                            Navigator.of(context).pop(),
                                        child: const Text('CANCEL'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                          HapticFeedback.mediumImpact();
                                          if (onDelete != null) {
                                            onDelete!.call(todo.id);
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
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Subtasks section if expanded
            if (todo.hasSubtasks &&
                ref.watch(_expandedTodoItemsProvider(todo.id)))
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: TodoSubtaskSection(parentTodo: todo),
              ),
          ],
        ),
      ),
    );
  }

  // Format a timestamp into a human-readable scheduled date
  String _formatScheduledDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    if (date.year == today.year &&
        date.month == today.month &&
        date.day == today.day) {
      return 'Today';
    } else if (date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day) {
      return 'Tomorrow';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }
}
