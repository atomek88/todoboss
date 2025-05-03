import 'package:flutter/material.dart';

/// A widget that displays the status of a todo item
class TodoStatusIndicator extends StatelessWidget {
  /// Status value (0 = pending, 1 = completed, 2 = overdue)
  final int status;
  
  /// Size of the indicator
  final double size;

  const TodoStatusIndicator({
    Key? key,
    required this.status,
    this.size = 12.0,
  }) : super(key: key);

  /// Get the appropriate color based on status
  Color _statusColor() {
    switch (status) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _statusColor(),
      ),
    );
  }
}
