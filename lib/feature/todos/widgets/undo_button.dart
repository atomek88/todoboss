import 'package:flutter/material.dart';

class UndoButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;
  final IconData icon;
  final Color? backgroundColor;
  final Duration duration;
  final VoidCallback onDurationEnd;

  const UndoButton({
    Key? key,
    required this.onPressed,
    this.label = 'Undo',
    this.icon = Icons.undo,
    this.backgroundColor,
    this.duration = const Duration(seconds: 5),
    required this.onDurationEnd,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Start the timer when the widget is built
    Future.delayed(duration, onDurationEnd);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: FloatingActionButton.extended(
        onPressed: onPressed,
        label: Text(label),
        icon: Icon(icon),
        backgroundColor: backgroundColor ?? Colors.grey[700],
      ),
    );
  }
}
