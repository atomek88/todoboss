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

  // Removed unused _priorityLabel method

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: Key(todo.id),
      // Background for swipe right (complete)
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20.0),
        color: Colors.green,
        child: const Icon(
          Icons.check_circle,
          color: Colors.white,
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
          // Complete todo
          onComplete(todo);
          return true;
        } else if (direction == DismissDirection.endToStart) {
          // Delete todo
          onDelete(todo);
          return false; // Don't actually dismiss, we'll handle it in the parent
        }
        return false;
      },
      child: GestureDetector(
        onTap: () {
          showTodoFormModal(context, todo: todo);
        },
        child: Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          color: _priorityColor(todo.priority).withOpacity(0.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 70, // Fixed height for all items
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                            style: const TextStyle(fontWeight: FontWeight.bold),
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
                    // Right side - Actions
                    // Recurring icon (if task has rollover property)
                    if (todo.rollover)
                      Padding(
                        padding: const EdgeInsets.only(right: 4.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: ColorFiltered(
                            colorFilter: ColorFilter.mode(
                              _priorityColor(todo.priority).withOpacity(0.4),
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
                              !ref.read(_expandedTodoItemsProvider(todo.id));
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Image.asset(
                            'assets/icons/subtasks.png',
                            width: 28,
                            height: 28,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Expandable subtask section
              if (ref.watch(_expandedTodoItemsProvider(todo.id)))
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: TodoSubtaskSection(parentTodo: todo),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
