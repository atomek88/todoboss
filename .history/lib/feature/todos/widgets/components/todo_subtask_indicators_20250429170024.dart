import 'package:flutter/material.dart';
import '../models/todo.dart';

/// A widget that displays indicators for subtask completion
class TodoSubtaskIndicators extends StatelessWidget {
  /// The todo with subtasks
  final Todo todo;
  
  /// Maximum number of visual indicators to show
  final int maxVisualIndicators;
  
  /// Indicator dot size
  final double dotSize;

  const TodoSubtaskIndicators({
    Key? key,
    required this.todo,
    this.maxVisualIndicators = 3,
    this.dotSize = 5.0,
  }) : super(key: key);

  /// Checks if the todo has subtasks
  bool get hasSubtasks => todo.subtasks != null && todo.subtasks!.isNotEmpty;

  /// Checks if all subtasks are completed
  bool get areAllSubtasksCompleted {
    if (!hasSubtasks) return true;
    return todo.subtasks!.every((subtask) => subtask.completed);
  }

  @override
  Widget build(BuildContext context) {
    if (!hasSubtasks) return const SizedBox.shrink();

    final completedCount = todo.subtasks!.where((subtask) => subtask.completed).length;
    final totalCount = todo.subtasks!.length;
    
    // Determine how many indicators to show
    final indicatorsToShow = totalCount > maxVisualIndicators 
        ? maxVisualIndicators 
        : totalCount;

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
                width: dotSize,
                height: dotSize,
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
}
