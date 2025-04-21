import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/todo.dart';
import 'todo_form_modal.dart';

class TodoListItem extends ConsumerWidget {
  final Todo todo;
  final int index;
  final Function(Todo, int) onComplete;
  final Function(Todo, int) onDelete;

  const TodoListItem({
    Key? key,
    required this.todo,
    required this.index,
    required this.onComplete,
    required this.onDelete,
  }) : super(key: key);

  Color _priorityColor(int priority) {
    switch (priority) {
      case 2:
        return Colors.redAccent;
      case 1:
        return Colors.orangeAccent;
      default:
        return Colors.greenAccent;
    }
  }
  
  // Removed unused _priorityLabel method

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: Key(todo.id),
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20.0),
        color: Colors.green,
        child: const Icon(
          Icons.check_circle,
          color: Colors.white,
        ),
      ),
      direction: DismissDirection.startToEnd,
      dismissThresholds: const {DismissDirection.startToEnd: 0.4},
      confirmDismiss: (direction) async {
        onComplete(todo, index);
        return true;
      },
      child: GestureDetector(
        onTap: () {
          showTodoFormModal(context, todo: todo, index: index);
        },
        child: Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          color: _priorityColor(todo.priority).withOpacity(0.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Container(
            height: 80, // Fixed height for all items
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // Left side - Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Title with priority indicator
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: _priorityColor(todo.priority),
                              shape: BoxShape.circle,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              todo.title,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Description
                      if (todo.description != null && todo.description!.isNotEmpty)
                        Expanded(
                          child: Text(
                            todo.description!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.black.withOpacity(0.6)),
                          ),
                        ),
                    ],
                  ),
                ),
                // Right side - Actions
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Subtasks button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () {
                          print('add subtasks');
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Icon(
                            Icons.list_alt_rounded,
                            color: Colors.blueGrey.shade700,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Delete button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => onDelete(todo, index),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.redAccent.shade200,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
