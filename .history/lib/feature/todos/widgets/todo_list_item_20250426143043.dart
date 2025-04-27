import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/todo.dart';
import 'todo_form_modal.dart';
import 'todo_subtask_section.dart';

// Provider to track expanded state of todo items
final _expandedTodoItemsProvider =
    StateProvider.family<bool, String>((ref, todoId) => false);

class TodoListItem extends ConsumerWidget {
  final Todo todo;
  final Function(Todo) onComplete;
  final Function(Todo) onDelete;

  const TodoListItem({
    Key? key,
    required this.todo,
    required this.onComplete,
    required this.onDelete,
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
          if (allSubtasksCompleted) {
            // Complete todo with subtask count for the counter
            onComplete(todo);
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
        } else if (direction == DismissDirection.endToStart) {
          // Delete todo
          onDelete(todo);
          return false; // Don't actually dismiss, we'll handle it in the parent
        }
        return false;
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () {
              showTodoFormModal(context, todo: todo);
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
                                      // Toggle expanded state
                                      ref
                                              .read(_expandedTodoItemsProvider(
                                                      todo.id)
                                                  .notifier)
                                              .state =
                                          !ref.read(_expandedTodoItemsProvider(
                                              todo.id));
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: ref.watch(
                                                _expandedTodoItemsProvider(
                                                    todo.id))
                                            ? Colors.blueAccent.withValues(
                                                0.1) // Light blue background when expanded
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            // Animated container for the icon with outline when expanded
                                            AnimatedContainer(
                                              duration: const Duration(
                                                  milliseconds: 200),
                                              decoration: BoxDecoration(
                                                border: ref.watch(
                                                        _expandedTodoItemsProvider(
                                                            todo.id))
                                                    ? Border.all(
                                                        color: Colors.black,
                                                        width: 1.0)
                                                    : null,
                                                borderRadius:
                                                    BorderRadius.circular(4.0),
                                              ),
                                              padding: EdgeInsets.all(
                                                ref.watch(
                                                        _expandedTodoItemsProvider(
                                                            todo.id))
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
                                            // Indicator dot for subtasks when not expanded
                                            if (todo.hasSubtasks &&
                                                !ref.watch(
                                                    _expandedTodoItemsProvider(
                                                        todo.id)))
                                              Positioned(
                                                top: 0,
                                                right: 0,
                                                child: Container(
                                                  width: 8,
                                                  height: 8,
                                                  decoration: BoxDecoration(
                                                    color: Colors.blue.shade500,
                                                    shape: BoxShape.circle,
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black
                                                            .withOpacity(0.2),
                                                        blurRadius: 1,
                                                        offset:
                                                            const Offset(0, 1),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
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
          // Expandable subtask section
          if (ref.watch(_expandedTodoItemsProvider(todo.id)))
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: TodoSubtaskSection(parentTodo: todo),
            ),
        ],
      ),
    );
  }
}
