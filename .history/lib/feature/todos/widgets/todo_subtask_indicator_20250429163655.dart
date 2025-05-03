import 'package:flutter/material.dart';
import 'package:todoApp/feature/todos/models/todo.dart';

/// A widget that displays indicators for subtask completion status
class TodoSubtaskIndicator extends StatelessWidget {
  final Todo todo;
  
  const TodoSubtaskIndicator({Key? key, required this.todo}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    if (todo.subtasks == null || todo.subtasks!.isEmpty) {
      return const SizedBox.shrink();
    }

    final completedCount = todo.subtasks!.where((subtask) => subtask.completed).length;
    final totalCount = todo.subtasks!.length;
    
    // Use a more compact representation for many subtasks
    // Show count for all subtasks, but limit visual indicators
    final maxVisualIndicators = 3;
    final indicatorsToShow = totalCount > maxVisualIndicators ? maxVisualIndicators : totalCount;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Subtask count text indicator
        Text(
          '$completedCount/$totalCount',
          style: TextStyle(
            fontSize: 10,
            color: completedCount == totalCount ? Colors.green : Colors.grey[700],
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        // Show indicators as a row of colored dots
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            ...List.generate(indicatorsToShow, (index) {
              final isCompleted = index < (completedCount > maxVisualIndicators 
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
  
  /// Checks if all subtasks are completed
  static bool areAllCompleted(Todo todo) {
    if (todo.subtasks == null || todo.subtasks!.isEmpty) return true;
    return todo.subtasks!.every((subtask) => subtask.completed);
  }
}
