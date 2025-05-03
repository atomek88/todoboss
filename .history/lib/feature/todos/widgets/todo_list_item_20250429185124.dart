import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/todo.dart';
import 'todo_form_modal.dart';
import 'todo_content.dart';
import 'todo_priority_indicator.dart';
import 'todo_status_indicator.dart';
import 'todo_subtask_indicators.dart';
import 'todo_subtask_panel.dart';
import 'todo_action_buttons.dart';
import 'todo_swipe_actions.dart';

/// A list item that displays a todo with swipeable actions, subtasks, and indicators
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // If read-only mode, don't use Dismissible
    if (isReadOnly) {
      return _buildReadOnlyItem(context, ref);
    }

    // For interactive mode, wrap with swipe actions
    return TodoSwipeActions(
      todo: todo,
      onToggle: onToggle,
      onComplete: onComplete,
      onDelete: onDelete2,
      onDeleteLegacy: onDelete,
      child: _buildTodoCard(context, ref),
    );
  }

  /// Build a read-only version of the todo item (for past dates)
  Widget _buildReadOnlyItem(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      color: TodoPriorityIndicator(priority: todo.priority, opacity: 0.4)
          .priorityColor(),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Main content area
          _buildTodoCardContent(context, ref),

          // Subtask panel if needed
          if (todo.hasSubtasks)
            TodoSubtaskPanel(
              todo: todo,
              isReadOnly: true,
            ),
        ],
      ),
    );
  }

  /// Build the interactive todo card
  Widget _buildTodoCard(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      color: TodoPriorityIndicator(priority: todo.priority, opacity: 0.4)
          .priorityColor(),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Main content area
          _buildTodoCardContent(context, ref),

          // Subtask panel if needed
          if (todo.hasSubtasks)
            TodoSubtaskPanel(
              todo: todo,
              isReadOnly: isReadOnly,
            ),
        ],
      ),
    );
  }

  /// Build the core content of the todo card
  Widget _buildTodoCardContent(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        title: TodoContent(
          todo: todo,
          isCompleted: todo.completed,
        ),
        // Leading icon/indicator
        leading: todo.hasSubtasks
            ? GestureDetector(
                onTap: () {
                  // Toggle expanded state for subtasks
                  final currentState = ref.read(todoExpandedProvider(todo.id));
                  ref.read(todoExpandedProvider(todo.id).notifier).state =
                      !currentState;
                },
                child: Stack(
                  alignment: Alignment.topRight,
                  children: [
                    // Animated container for the icon with outline when expanded
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        border: ref.watch(todoExpandedProvider(todo.id))
                            ? Border.all(color: Colors.black, width: 1.0)
                            : null,
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      padding: EdgeInsets.all(
                        ref.watch(todoExpandedProvider(todo.id)) ? 2.0 : 0.0,
                      ),
                      child: Image.asset(
                        'assets/icons/subtasks.png',
                        width: 26,
                        height: 26,
                        fit: BoxFit.cover,
                      ),
                    ),
                    // Indicator dot for subtasks when not expanded
                    if (todo.hasSubtasks &&
                        !ref.watch(todoExpandedProvider(todo.id)))
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(width: 8, height: 8),
                      ),
                  ],
                ),
              )
            : TodoPriorityIndicator(priority: todo.priority, size: 24),

        // Right side widgets
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // First show status indicator
            TodoStatusIndicator(status: todo.status),
            const SizedBox(width: 4),

            // Subtask indicators if any
            if (todo.hasSubtasks)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: TodoSubtaskIndicators(todo: todo),
              ),

            // Action buttons
            if (!isReadOnly)
              TodoActionButtons(
                todo: todo,
                isReadOnly: isReadOnly,
                onToggle: onToggle,
                onComplete: onComplete,
                onDelete: onDelete2,
                onDeleteLegacy: onDelete,
                onEdit: () => showTodoFormModal(
                  context,
                  todo: todo,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
