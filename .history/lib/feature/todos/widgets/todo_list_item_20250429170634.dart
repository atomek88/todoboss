import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/todo.dart';
import 'todo_action_buttons.dart';
import 'todo_content.dart';
import 'todo_form_modal.dart';
import 'todo_priority_indicator.dart';
import 'todo_status_indicator.dart';
import 'todo_subtask_indicators.dart';
import 'todo_subtask_panel.dart';
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
      color: TodoPriorityIndicator(
              priority: todo.priority, opacity: 0.4)
          ._priorityColor(),
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
                    GestureDetector(
                      onTap: () {
                        final currentState =
                            ref.read(_expandedTodoItemsProvider(todo.id));
                        ref
                            .read(_expandedTodoItemsProvider(todo.id).notifier)
                            .state = !currentState;
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
    }

    return Dismissible(
      key: Key(todo.id),
      // Background for swipe right (complete)
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20.0),
        // Only show green if all subtasks are completed or there are no subtasks
        color: allSubtasksCompleted ? Colors.green : Colors.grey.shade400,
        child: Icon(
          Icons.check_circle,
          color: Colors.white,
          // Add a small shake animation if subtasks are incomplete
          size: allSubtasksCompleted ? 24 : 20,
        ),
      ),
      // Background for swipe left (delete)
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        color: Colors.red,
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      // Disable swipe-to-complete if there are incomplete subtasks
      direction: hasSubtasks && !allSubtasksCompleted
          ? DismissDirection.endToStart
          : // Only allow delete
          DismissDirection.horizontal, // Allow both directions
      dismissThresholds: const {
        DismissDirection.startToEnd: 0.4,
        DismissDirection.endToStart: 0.4,
      },
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Only allow completion if all subtasks are completed or there are no subtasks
          if (allSubtasksCompleted && onComplete != null) {
            // Complete todo with subtask count for the counter
            onComplete!(todo);
            return true;
          } else {
            // Show a message that subtasks need to be completed first
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Complete all subtasks first'),
                duration: Duration(seconds: 2),
              ),
            );
            return false;
          }
        } else if (direction == DismissDirection.endToStart &&
            onDelete != null) {
          // Delete todo
          onDelete!(todo);
          return false; // Don't actually dismiss, we'll handle it in the parent
        }
        return false;
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () {
              if (!isReadOnly) {
                showTodoFormModal(context, todo: todo);
              }
            },
            child: Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              color: _priorityColor(todo.priority).withOpacity(0.4),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              child: SizedBox(
                height: 72, // Reduced height by 10% (from 80 to 72)
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 6), // Reduced vertical padding
                  child: Row(
                    children: [
                      // Left side - Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            // Title always at top
                            Text(
                              todo.title,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            // Description
                            Expanded(
                              child: todo.description != null &&
                                      todo.description!.isNotEmpty
                                  ? Text(
                                      todo.description!,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          color: Colors.black.withOpacity(0.6)),
                                    )
                                  : const SizedBox(), // Empty space if no description
                            ),
                          ],
                        ),
                      ),
                      // Right side container with indicators and buttons
                      SizedBox(
                        width: 76, // Fixed width for the right side
                        child: Column(
                          mainAxisSize:
                              MainAxisSize.min, // Use minimum vertical space
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Subtask completion indicators at the top right
                            if (todo.hasSubtasks)
                              Flexible(
                                child: _buildSubtaskIndicators(todo),
                              ),
                            const SizedBox(
                                height:
                                    4), // Add spacing between subtask indicators and buttons
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Recurring icon (if task has rollover property)
                                if (todo.rollover)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 4.0),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: ColorFiltered(
                                        colorFilter: ColorFilter.mode(
                                          _priorityColor(todo.priority)
                                              .withOpacity(0.4),
                                          BlendMode.multiply,
                                        ),
                                        child: Image.asset(
                                          'assets/icons/rock-hill.png',
                                          width: 24,
                                          height: 24,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ),
                                // Subtasks button
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    customBorder: const CircleBorder(),
                                    onTap: () {
                                      // Always toggle expansion state regardless of read-only status
                                      // This ensures subtasks can be viewed even in read-only mode
                                      final currentState = ref.read(
                                          _expandedTodoItemsProvider(todo.id));
                                      ref
                                          .read(_expandedTodoItemsProvider(
                                                  todo.id)
                                              .notifier)
                                          .state = !currentState;

                                      // Add a small haptic feedback when toggling expansion
                                      HapticFeedback.lightImpact();

                                      // Debug log for expansion state
                                      debugPrint(
                                          '🔍 [TodoListItem] Toggled subtasks for ${todo.id} - ${todo.title}: ${!currentState}');
                                      if (todo.subtasks != null) {
                                        debugPrint(
                                            '🔍 [TodoListItem] Found ${todo.subtasks!.length} subtasks');
                                      }
                                    },
                                    child: Container(
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Stack(
                                          alignment: Alignment.center,
          ),
          // Expandable subtask section with animation
          AnimatedCrossFade(
            firstChild: const SizedBox(height: 0),
            secondChild: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: TodoSubtaskSection(parentTodo: todo),
                  border: Border.all(color: Colors.black12),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TodoSubtaskSection(parentTodo: todo),
                    ],
                  ),
                ),
              ),
            ),
            crossFadeState: ref.watch(_expandedTodoItemsProvider(todo.id))
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }
}
