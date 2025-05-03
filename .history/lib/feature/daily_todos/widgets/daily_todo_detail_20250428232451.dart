import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../todos/models/daily_todo.dart';
import '../../todos/models/todo.dart';

/// A widget that displays detailed information about a daily todo summary
class DailyTodoDetail extends StatelessWidget {
  /// The daily todo to display
  final DailyTodo dailyTodo;

  /// Color for completed todos
  final Color completedColor;

  /// Color for deleted todos
  final Color deletedColor;

  /// Background color
  final Color backgroundColor;

  /// Text color
  final Color textColor;

  const DailyTodoDetail({
    Key? key,
    required this.dailyTodo,
    this.completedColor = Colors.green,
    this.deletedColor = Colors.red,
    this.backgroundColor = Colors.white,
    this.textColor = Colors.black87,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');
    final formattedDate = dateFormat.format(dailyTodo.date);
    
    // Get all different todo categories
    final activeTodos = dailyTodo.activeTodos;
    final completedTodos = dailyTodo.completedTodos;
    final deletedTodos = dailyTodo.deletedTodos;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date and overview
          Text(
            formattedDate,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 16),
          
          // Summary metrics
          _buildMetricRow(
            'Task Goal',
            '${dailyTodo.completedTodosCount}/${dailyTodo.taskGoal}',
            completedColor,
          ),
          _buildProgressBar(
            dailyTodo.completionPercentage / 100,
            completedColor,
          ),
          const SizedBox(height: 12),
          
          // Todo counts
          Row(
            children: [
              Expanded(
                child: _buildMetricBox(
                  'Completed',
                  dailyTodo.completedTodosCount.toString(),
                  completedColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricBox(
                  'Deleted',
                  dailyTodo.deletedTodosCount.toString(),
                  deletedColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricBox(
                  'Active',
                  activeTodos.length.toString(),
                  Colors.blue,
                ),
              ),
            ],
          ),
          
          // Todo lists sections
          if (completedTodos.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildSectionTitle('Completed Tasks', completedColor),
            ...completedTodos.map((todo) => _buildTodoItem(todo, completedColor)),
          ],
          
          if (deletedTodos.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildSectionTitle('Deleted Tasks', deletedColor),
            ...deletedTodos.map((todo) => _buildTodoItem(todo, deletedColor)),
          ],
          
          if (activeTodos.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildSectionTitle('Active Tasks', Colors.blue),
            ...activeTodos.map((todo) => _buildTodoItem(todo, Colors.blue)),
          ],
          
          // Daily summary text
          if (dailyTodo.summary != null && dailyTodo.summary!.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildSectionTitle('Daily Summary', textColor.withOpacity(0.7)),
            Text(
              dailyTodo.summary!,
              style: TextStyle(
                fontSize: 15,
                color: textColor.withOpacity(0.8),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Helper to build metric row
  Widget _buildMetricRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: textColor.withOpacity(0.7),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  // Helper to build a progress bar
  Widget _buildProgressBar(double progress, Color progressColor) {
    return Container(
      height: 10,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(5),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: progressColor,
            borderRadius: BorderRadius.circular(5),
          ),
        ),
      ),
    );
  }

  // Helper to build metric box
  Widget _buildMetricBox(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: textColor.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  // Helper to build section title
  Widget _buildSectionTitle(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  // Helper to build todo item
  Widget _buildTodoItem(Todo todo, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            height: 8,
            width: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  todo.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
                if (todo.description != null && todo.description!.isNotEmpty)
                  Text(
                    todo.description!,
                    style: TextStyle(
                      fontSize: 13,
                      color: textColor.withOpacity(0.7),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
