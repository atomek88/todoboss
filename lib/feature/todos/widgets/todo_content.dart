import 'package:flutter/material.dart';
import '../models/todo.dart';

/// A widget that displays the content of a todo item (title, description)
class TodoContent extends StatelessWidget {
  /// The todo to display
  final Todo todo;
  
  /// Whether the todo is completed
  final bool isCompleted;
  
  /// Text style for the title
  final TextStyle? titleStyle;
  
  /// Text style for the description
  final TextStyle? descriptionStyle;

  const TodoContent({
    Key? key,
    required this.todo,
    this.isCompleted = false,
    this.titleStyle,
    this.descriptionStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hasDescription = todo.description != null && todo.description!.isNotEmpty;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Title with optional strike-through for completed todos
        Text(
          todo.title,
          style: (titleStyle ?? const TextStyle(fontWeight: FontWeight.bold)).copyWith(
            decoration: isCompleted ? TextDecoration.lineThrough : null,
            decorationThickness: 2.0,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        
        // Description if available
        if (hasDescription)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              todo.description!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: descriptionStyle ?? TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
                decoration: isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
      ],
    );
  }
}
