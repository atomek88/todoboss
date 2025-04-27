import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:todoApp/feature/daily_summary/models/daily_summary.dart';
import 'dart:math' as math;

/// A calendar heatmap widget that displays a grid of cells representing daily activity
/// Each row represents a week (Monday to Sunday)
/// The color intensity represents the completion rate of todos
class CalendarHeatmap extends StatelessWidget {
  /// List of daily summaries to display
  final List<DailySummary> summaries;
  
  /// Number of weeks to display
  final int weeksToShow;
  
  /// Size of each cell
  final double cellSize;
  
  /// Spacing between cells
  final double cellSpacing;
  
  /// Border radius of cells
  final double cellBorderRadius;
  
  /// Color for completed todos
  final Color completedColor;
  
  /// Color for deleted todos
  final Color deletedColor;
  
  /// Color for empty cells
  final Color emptyColor;
  
  /// Background color
  final Color backgroundColor;
  
  /// Whether to show the day labels (M, T, W, etc.)
  final bool showDayLabels;
  
  /// Whether to show the week labels (Week 1, Week 2, etc.)
  final bool showWeekLabels;
  
  /// Callback when a cell is tapped
  final Function(DailySummary)? onCellTap;

  const CalendarHeatmap({
    Key? key,
    required this.summaries,
    this.weeksToShow = 10,
    this.cellSize = 32,
    this.cellSpacing = 4,
    this.cellBorderRadius = 4,
    this.completedColor = Colors.green,
    this.deletedColor = Colors.red,
    this.emptyColor = Colors.grey,
    this.backgroundColor = Colors.white,
    this.showDayLabels = true,
    this.showWeekLabels = true,
    this.onCellTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get the current date
    final today = DateTime.now();
    
    // Calculate the start date (weeksToShow weeks ago)
    final startDate = today.subtract(Duration(days: weeksToShow * 7));
    
    // Create a map of dates to summaries for quick lookup
    final summaryMap = <String, DailySummary>{};
    for (final summary in summaries) {
      final dateKey = _dateToKey(summary.date);
      summaryMap[dateKey] = summary;
    }
    
    // Group summaries by week
    final weeksList = _groupByWeek(startDate, today, summaryMap);
    
    return Container(
      color: backgroundColor,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showDayLabels) _buildDayLabels(),
          const SizedBox(height: 8),
          ...weeksList.map((week) => _buildWeekRow(week)),
        ],
      ),
    );
  }
  
  /// Build the day labels (M, T, W, T, F, S, S)
  Widget _buildDayLabels() {
    final dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    
    return Padding(
      padding: EdgeInsets.only(left: showWeekLabels ? 50 : 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: dayLabels.map((label) => 
          SizedBox(
            width: cellSize + cellSpacing,
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
          )
        ).toList(),
      ),
    );
  }
  
  /// Build a row representing a week
  Widget _buildWeekRow(Map<String, dynamic> week) {
    final weekNumber = week['weekNumber'] as int;
    final days = week['days'] as List<Map<String, dynamic>>;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          if (showWeekLabels)
            SizedBox(
              width: 50,
              child: Text(
                'Week $weekNumber',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ),
          ...days.map((day) => _buildDayCell(day)),
        ],
      ),
    );
  }
  
  /// Build a cell representing a day
  Widget _buildDayCell(Map<String, dynamic> day) {
    final date = day['date'] as DateTime;
    final summary = day['summary'] as DailySummary?;
    final isToday = _isToday(date);
    
    // Determine cell color based on completion and deletion rates
    Color cellColor = emptyColor.withOpacity(0.2);
    if (summary != null) {
      if (summary.todoCompletedCount > 0 || summary.todoDeletedCount > 0) {
        // Blend colors based on completion and deletion rates
        final completionRate = summary.completionRate;
        final deletionRate = summary.deletionRate;
        
        // Ensure opacity values are within valid range (0.0 to 1.0)
        final safeCompletionOpacity = 0.3 + (completionRate * 0.7).clamp(0.0, 0.7);
        final safeDeletionOpacity = 0.3 + (deletionRate * 0.7).clamp(0.0, 0.7);
        
        if (completionRate > 0 && deletionRate > 0) {
          // Blend colors if both rates are positive
          final blendFactor = (deletionRate / (completionRate + deletionRate)).clamp(0.0, 1.0);
          cellColor = Color.lerp(
            completedColor.withOpacity(safeCompletionOpacity),
            deletedColor.withOpacity(safeDeletionOpacity),
            blendFactor,
          ) ?? emptyColor;
        } else if (completionRate > 0) {
          // Only completion rate is positive
          cellColor = completedColor.withOpacity(safeCompletionOpacity);
        } else if (deletionRate > 0) {
          // Only deletion rate is positive
          cellColor = deletedColor.withOpacity(safeDeletionOpacity);
        }
      }
    }
    
    return GestureDetector(
      onTap: () {
        if (summary != null && onCellTap != null) {
          HapticFeedback.lightImpact();
          onCellTap!(summary);
        }
      },
      child: Container(
        width: cellSize,
        height: cellSize,
        margin: EdgeInsets.all(cellSpacing / 2),
        decoration: BoxDecoration(
          color: cellColor,
          borderRadius: BorderRadius.circular(cellBorderRadius),
          border: isToday 
              ? Border.all(color: Colors.blue, width: 2) 
              : null,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                date.day.toString(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  color: isToday ? Colors.blue : Colors.black54,
                ),
              ),
              if (summary != null && (summary.todoCompletedCount > 0 || summary.todoDeletedCount > 0))
                Text(
                  '${summary.todoCompletedCount}/${summary.todoGoal > 0 ? summary.todoGoal : summary.todoCompletedCount + summary.todoDeletedCount}',
                  style: TextStyle(
                    fontSize: 8,
                    color: isToday ? Colors.blue : Colors.black54,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Group summaries by week
  List<Map<String, dynamic>> _groupByWeek(
    DateTime startDate, 
    DateTime endDate, 
    Map<String, DailySummary> summaryMap
  ) {
    final result = <Map<String, dynamic>>[];
    
    // Calculate the first day of the week (Monday) for the start date
    final firstDayOfWeek = startDate.subtract(Duration(days: startDate.weekday - 1));
    
    // Iterate through weeks
    var currentWeekStart = firstDayOfWeek;
    while (currentWeekStart.isBefore(endDate) || _isSameDay(currentWeekStart, endDate)) {
      final weekDays = <Map<String, dynamic>>[];
      
      // Calculate week number
      final weekNumber = _getWeekNumber(currentWeekStart);
      
      // Iterate through days in the week (Monday to Sunday)
      for (var i = 0; i < 7; i++) {
        final currentDate = currentWeekStart.add(Duration(days: i));
        
        // Skip if the date is after the end date
        if (currentDate.isAfter(endDate)) {
          weekDays.add({
            'date': currentDate,
            'summary': null,
          });
          continue;
        }
        
        // Get the summary for this date
        final dateKey = _dateToKey(currentDate);
        final summary = summaryMap[dateKey];
        
        weekDays.add({
          'date': currentDate,
          'summary': summary,
        });
      }
      
      result.add({
        'weekNumber': weekNumber,
        'days': weekDays,
      });
      
      // Move to the next week
      currentWeekStart = currentWeekStart.add(const Duration(days: 7));
    }
    
    return result;
  }
  
  /// Convert a date to a string key for the map
  String _dateToKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
  
  /// Check if two dates are the same day
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
  
  /// Check if a date is today
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return _isSameDay(date, now);
  }
  
  /// Get the week number in the year
  int _getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysIntoYear = date.difference(firstDayOfYear).inDays;
    return ((daysIntoYear - date.weekday + 10) / 7).floor();
  }
}
