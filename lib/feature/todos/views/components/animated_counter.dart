import 'package:flutter/material.dart';

/// An animated counter widget that transitions between values with an animation
class AnimatedCounter extends StatelessWidget {
  final int count;
  final int total;
  final Color color;
  
  /// Create an animated counter that displays a count and optionally a total
  /// 
  /// - [count] is the current value to display
  /// - [total] is the maximum or target value (if applicable)
  /// - [color] is the text color to use
  const AnimatedCounter({
    Key? key,
    required this.count,
    required this.total,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // For deleted tasks, don't show the total
    final displayText = color == Colors.grey ? '$count' : '$count/$total';

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: Text(
        displayText,
        key: ValueKey(count),
        style: TextStyle(
          fontSize: 32, 
          fontWeight: FontWeight.bold, 
          color: color,
        ),
      ),
    );
  }
}
