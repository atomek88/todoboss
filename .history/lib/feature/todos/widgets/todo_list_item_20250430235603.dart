import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/todo.dart';
import 'todo_form_modal.dart';
import 'components/todo_subtask_section.dart';
import 'todo_swipe_actions.dart';

// Provider to track expanded state of todo items
final _expandedTodoItemsProvider =
    StateProvider.family<bool, String>((ref, todoId) => false);

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

  Color _priorityColor(int priority) {
    switch (priority) {
      case 2:
        return Colors.redAccent;
      case 1:
        return Colors.amberAccent;
      default:
        return const Color.fromARGB(255, 105, 240, 174);
    }
  }

  /// Checks if all subtasks are completed
  bool _areAllSubtasksCompleted(Todo todo) {
    if (todo.subtasks == null || todo.subtasks!.isEmpty) return true;
    return todo.subtasks!.every((subtask) => subtask.completed);
  }

  /// Builds indicators showing subtask completion status
  Widget _buildSubtaskIndicators(Todo todo) {
    if (todo.subtasks == null || todo.subtasks!.isEmpty) {
      return const SizedBox.shrink();
    }

    final completedCount =
        todo.subtasks!.where((subtask) => subtask.completed).length;
    final totalCount = todo.subtasks!.length;

    // Use a more compact representation for many subtasks
    // Show count for all subtasks, but limit visual indicators
    final maxVisualIndicators = 3;
    final indicatorsToShow =
        totalCount > maxVisualIndicators ? maxVisualIndicators : totalCount;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Show indicators as a row of colored dots
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            ...List.generate(indicatorsToShow, (index) {
              final isCompleted = index <
                  (completedCount > maxVisualIndicators
                      ? maxVisualIndicators
                      : completedCount);
              return Container(
                width: 5, // Even smaller dots to prevent overflow
                height: 5,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted ? Colors.greenAccent : Colors.redAccent,
                  border: Border.all(
                    color: Colors.white,
                    width: 0.5,
                  ),
                ),
              );
            }),
            // Show ellipsis if we're not showing all indicators
            if (totalCount > maxVisualIndicators)
              const Text('...', style: TextStyle(fontSize: 8, height: 0.5)),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Check if all subtasks are completed (if any)
    final allSubtasksCompleted = _areAllSubtasksCompleted(todo);
    final hasSubtasks = todo.hasSubtasks;

    // Create the card content - this will be used in both read-only and swipeable modes
    Widget cardContent = Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      color: _priorityColor(todo.priority).withOpacity(0.4),
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
            subtitle: todo.description != null && todo.description!.isNotEmpty
                ? Text(
                    todo.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  )
                : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Status indicator
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: todo.status == 1
                        ? Colors.green
                        : (todo.status == 2 ? Colors.red : Colors.grey),
                  ),
                ),
                const SizedBox(width: 4),
                if (hasSubtasks) ...[
                  GestureDetector(
                    onTap: () {
                      final currentState =
                          ref.read(_expandedTodoItemsProvider(todo.id));
                      ref
                          .read(_expandedTodoItemsProvider(todo.id).notifier)
                          .state = !currentState;

                      debugPrint(
                          '🔍 [TodoListItem] Toggled subtasks for ${todo.id} - ${todo.title}: ${!currentState}');
                    },
                    child: Icon(
                      ref.watch(_expandedTodoItemsProvider(todo.id))
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 20,
                    ),
                  ),
                ],
              ],
            ),
            onTap: isReadOnly
                ? null
                : () => showTodoFormModal(context, todo: todo),
          ),

          // Subtasks section if expanded
          if (hasSubtasks && ref.watch(_expandedTodoItemsProvider(todo.id)))
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
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
