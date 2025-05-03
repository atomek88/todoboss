import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/todo.dart';
import 'todo_form_modal.dart';
import 'todo_subtask_section.dart';

// Provider to track expanded state of todo items
final _expandedTodoItemsProvider =
    StateProvider.family<bool, String>((ref, todoId) => false);

class TodoListItem extends ConsumerWidget {
  final Todo todo;
  // Support both old and new callback patterns for backward compatibility
  final Function(Todo)? onComplete; // Legacy - takes Todo object
  final Function(Todo)? onDelete;   // Legacy - takes Todo object
  final Function(String)? onToggle;  // New - takes String ID
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
    if (todo.subtasks == null || todo.subtasks!.isEmpty)
      return const SizedBox.shrink();

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

  // Removed unused _priorityLabel method

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Check if all subtasks are completed (if any)
    final allSubtasksCompleted = _areAllSubtasksCompleted(todo);
    final hasSubtasks = todo.hasSubtasks;

    // If read-only mode, don't use Dismissible
    if (isReadOnly) {
      return Card(
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
                                          children: [
                                            // Animated container for the icon with outline when expanded
                                            AnimatedContainer(
                                              duration: const Duration(milliseconds: 200),
                                              decoration: BoxDecoration(
                                                border: ref.watch(_expandedTodoItemsProvider(todo.id))
                                                    ? Border.all(color: Colors.black, width: 1.0)
                                                    : null,
                                                borderRadius: BorderRadius.circular(4.0),
                                              ),
                                              padding: EdgeInsets.all(
                                                ref.watch(_expandedTodoItemsProvider(todo.id))
                                                    ? 2.0
                                                    : 0.0,
                                              ),
                                              child: Image.asset(
                                                'assets/icons/subtasks.png',
                                                width: 26,
                                                height: 26,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      
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
                                                if (onDelete2 != null) {
                                                  onDelete2?.call(todo.id);
                                                } else {
                                                  onDelete?.call(todo);
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
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Expandable subtask section with animation
          AnimatedCrossFade(
            firstChild: const SizedBox(height: 0),
            secondChild: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Container(
                decoration: BoxDecoration(
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
