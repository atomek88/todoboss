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

    return Row(
      mainAxisAlignment: MainAxisAlignment.end, // Align to the right
      mainAxisSize: MainAxisSize.min, // Take only needed space
      children: [
        // Show indicators as colored dots
        ...List.generate(totalCount, (index) {
          final isCompleted = index < completedCount;
          return Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted ? Colors.greenAccent : Colors.redAccent,
              border: Border.all(
                color: Colors.white,
                width: 1,
              ),
            ),
          );
        }),
        const SizedBox(width: 4),
      ],
    );
  }

  // Removed unused _priorityLabel method

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Check if all subtasks are completed (if any)
    final allSubtasksCompleted = _areAllSubtasksCompleted(todo);
    
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
      direction: DismissDirection.horizontal, // Allow both directions
      dismissThresholds: const {
        DismissDirection.startToEnd: 0.4,
        DismissDirection.endToStart: 0.4,
      },
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Only allow completion if all subtasks are completed or there are no subtasks
          if (allSubtasksCompleted) {
            // Complete todo
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
                height: 70, // Fixed height for all items
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
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
                                              color:
                                                  Colors.black.withOpacity(0.6)),
                                        )
                                      : const SizedBox(), // Empty space if no description
                                ),
                              ],
                            ),
                          ),
                        
                          ),
                          // Right side container with indicators and buttons
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // Subtask completion indicators at the top right
                              if (todo.hasSubtasks)
                                _buildSubtaskIndicators(todo),
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
                                                .read(_expandedTodoItemsProvider(todo.id)
                                                    .notifier)
                                                .state =
                                            !ref.read(
                                                _expandedTodoItemsProvider(todo.id));
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            Image.asset(
                                              'assets/icons/subtasks.png',
                                              width: 28,
                                              height: 28,
                                              fit: BoxFit.cover,
                                            ),
                                            if (todo.hasSubtasks ||
                                                ref.watch(
                                                    _expandedTodoItemsProvider(todo.id)))
                                              Container(
                                                width: 32,
                                                height: 32,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: Colors.blue.shade700,
                                                    width: 2.0,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
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
