import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/todo.dart';

/// Provider to track expanded state of todo items
final todoExpandedProvider =
    StateProvider.family<bool, String>((ref, todoId) => false);

/// A widget that displays and manages expandable subtasks
class TodoSubtaskPanel extends ConsumerWidget {
  /// The parent todo with subtasks
  final Todo todo;
  
  /// Whether the panel should be in read-only mode
  final bool isReadOnly;

  const TodoSubtaskPanel({
    Key? key,
    required this.todo,
    this.isReadOnly = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Skip if no subtasks
    if (!todo.hasSubtasks) return const SizedBox.shrink();
    
    // Get current expanded state
    final isExpanded = ref.watch(todoExpandedProvider(todo.id));
    
    return Column(
      children: [
        // Subtask header
        GestureDetector(
          onTap: () {
            // Toggle expansion state
            ref.read(todoExpandedProvider(todo.id).notifier).state = !isExpanded;
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Subtasks (${todo.subtasks?.length ?? 0})',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Icon(
                  isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
        
        // Subtask list (only shown when expanded)
        if (isExpanded)
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: todo.subtasks?.length ?? 0,
            itemBuilder: (context, index) {
              final subtask = todo.subtasks![index];
              return ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 24.0),
                title: Text(
                  subtask.title,
                  style: TextStyle(
                    fontSize: 14,
                    decoration: subtask.completed ? TextDecoration.lineThrough : null,
                  ),
                ),
                leading: Icon(
                  subtask.completed
                      ? Icons.check_circle
                      : Icons.circle_outlined,
                  color: subtask.completed ? Colors.green : Colors.grey,
                  size: 18,
                ),
                // Only allow interaction if not in read-only mode
                onTap: isReadOnly
                    ? null
                    : () {
                        // In a real implementation, this would update the subtask
                        // but we're keeping existing functionality
                      },
              );
            },
          ),
      ],
    );
  }
}
