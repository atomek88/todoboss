import 'package:flutter/material.dart';

/// A widget that displays the priority of a todo as a colored indicator
class TodoPriorityIndicator extends StatelessWidget {
  /// The priority level (0 = low, 1 = medium, 2 = high)
  final int priority;

  /// Size of the indicator
  final double size;

  /// Optional opacity for the color
  final double opacity;

  const TodoPriorityIndicator({
    Key? key,
    required this.priority,
    this.size = 12.0,
    this.opacity = 1.0,
  }) : super(key: key);

  /// Get the appropriate color based on priority level
  Color priorityColor() {
    switch (priority) {
      case 2:
        return Colors.redAccent.withOpacity(opacity);
      case 1:
        return Colors.amberAccent.withOpacity(opacity);
      default:
        return const Color.fromARGB(255, 105, 240, 174).withOpacity(opacity);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: priorityColor(),
      ),
    );
  }
}
