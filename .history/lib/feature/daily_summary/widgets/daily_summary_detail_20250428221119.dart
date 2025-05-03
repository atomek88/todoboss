import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/daily_summary.dart';

/// A widget that displays detailed information about a daily summary
class DailySummaryDetail extends StatelessWidget {
  /// The daily summary to display
  final DailySummary summary;

  /// Color for completed todos
  final Color completedColor;

  /// Color for deleted todos
  final Color deletedColor;

  /// Background color
  final Color backgroundColor;

  /// Text color
  final Color textColor;

  const DailySummaryDetail({
    Key? key,
    required this.summary,
    this.completedColor = Colors.green,
    this.deletedColor = Colors.red,
    this.backgroundColor = Colors.white,
    this.textColor = Colors.black87,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');
    final formattedDate = dateFormat.format(summary.date);

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
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            formattedDate,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 16),

          // Completion rate indicator
          _buildProgressSection(
            'Task Completion',
            summary.todoCompletedCount,
            summary.todoGoal > 0
                ? summary.todoGoal
                : summary.todoCompletedCount + summary.todoDeletedCount,
            completedColor,
          ),
          const SizedBox(height: 12),

          // Metrics grid
          _buildMetricsGrid(),
          const SizedBox(height: 16),

          // Goal achievement indicator
          if (summary.todoGoal > 0) _buildGoalAchievementIndicator(),
        ],
      ),
    );
  }

  /// Build the progress section with a linear progress indicator
  Widget _buildProgressSection(
      String title, int completed, int total, Color color) {
    final progress = total > 0 ? completed / total : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 8,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '$completed/$total',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Build a grid of metrics
  Widget _buildMetricsGrid() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  'Completed',
                  summary.todoCompletedCount.toString(),
                  completedColor,
                  Icons.check_circle_outline,
                ),
              ),
              Expanded(
                child: _buildMetricItem(
                  'Deleted',
                  summary.todoDeletedCount.toString(),
                  deletedColor,
                  Icons.delete_outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  'Created',
                  summary.todoCreatedCount.toString(),
                  Colors.blue,
                  Icons.add_circle_outline,
                ),
              ),
              Expanded(
                child: _buildMetricItem(
                  'Goal',
                  summary.todoGoal.toString(),
                  Colors.amber,
                  Icons.star_outline,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build a single metric item
  Widget _buildMetricItem(
      String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: textColor.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  /// Build the goal achievement indicator
  Widget _buildGoalAchievementIndicator() {
    final achieved = summary.goalAchieved;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: achieved
            ? Colors.green.withOpacity(0.1)
            : Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: achieved ? Colors.green : Colors.amber,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            achieved ? Icons.emoji_events : Icons.hourglass_empty,
            color: achieved ? Colors.green : Colors.amber,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              achieved
                  ? 'Daily goal achieved! 🎉'
                  : 'Daily goal not yet achieved',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
