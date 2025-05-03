import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:todoApp/feature/todos/models/daily_todo.dart';
import 'dart:math' as math;
import 'dart:async';

/// A calendar heatmap widget that displays a grid of cells representing daily activity
/// Each row represents a week (Monday to Sunday)
/// The color intensity represents the completion rate of todos
class DailyTodoCalendarHeatmap extends StatefulWidget {
  /// List of daily todos to display
  final List<DailyTodo> dailyTodos;
  
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
  
  /// Whether to show month labels (Jan, Feb, etc.)
  final bool showMonthLabels;
  
  /// Callback when a cell is tapped
  final Function(DailyTodo)? onCellTap;

  const DailyTodoCalendarHeatmap({
    Key? key,
    required this.dailyTodos,
    this.weeksToShow = 12,
    this.cellSize = 16,
    this.cellSpacing = 4,
    this.cellBorderRadius = 4,
    this.completedColor = Colors.green,
    this.deletedColor = Colors.red,
    this.emptyColor = Colors.grey,
    this.backgroundColor = Colors.white,
    this.showDayLabels = true,
    this.showWeekLabels = false,
    this.showMonthLabels = true,
    this.onCellTap,
  }) : super(key: key);

  @override
  State<DailyTodoCalendarHeatmap> createState() => _DailyTodoCalendarHeatmapState();
}

class _DailyTodoCalendarHeatmapState extends State<DailyTodoCalendarHeatmap> {
  late List<Map<String, dynamic>> _weeks;
  late List<DateTime> _monthTransitions;
  Timer? _debounceTimer;
  
  @override
  void initState() {
    super.initState();
    _prepareData();
  }
  
  @override
  void didUpdateWidget(DailyTodoCalendarHeatmap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dailyTodos != widget.dailyTodos || 
        oldWidget.weeksToShow != widget.weeksToShow) {
      _prepareData();
    }
  }
  
  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
  
  /// Prepare the data for rendering
  void _prepareData() {
    // Cancel any pending calculations
    _debounceTimer?.cancel();
    
    // Use a debounce to avoid multiple recalculations during rapid changes
    _debounceTimer = Timer(const Duration(milliseconds: 50), () {
      // Create a map of date keys to summaries for faster lookup
      final Map<String, DailyTodo> dailyTodoMap = {};
      for (final dailyTodo in widget.dailyTodos) {
        final dateKey = _dateToKey(dailyTodo.date);
        dailyTodoMap[dateKey] = dailyTodo;
      }
      
      // Generate start and end dates
      final today = DateTime.now();
      final endDate = DateTime(today.year, today.month, today.day);
      final startDate = endDate.subtract(Duration(days: widget.weeksToShow * 7 - 1));
      
      // Group by week
      _weeks = _groupByWeek(startDate, endDate, dailyTodoMap);
      
      // Identify month transitions for labels
      _identifyMonthTransitions();
      
      if (mounted) setState(() {});
    });
  }
  
  /// Identify transitions between months for labeling
  void _identifyMonthTransitions() {
    _monthTransitions = [];
    DateTime? lastMonth;
    
    for (final week in _weeks) {
      for (final day in week['days'] as List<Map<String, dynamic>>) {
        if (day['date'] != null) {
          final date = day['date'] as DateTime;
          if (lastMonth == null || date.month != lastMonth.month) {
            _monthTransitions.add(date);
            lastMonth = date;
          }
        }
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate responsive cell size based on available width
        final cellSize = _calculateResponsiveCellSize(constraints.maxWidth);
        
        return Container(
          color: widget.backgroundColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Day labels (Mon, Tue, etc.)
              if (widget.showDayLabels) 
                _buildDayLabels(cellSize),
              
              // Month labels and weeks grid
              Stack(
                children: [
                  // Calendar weeks
                  Column(
                    children: _weeks.map((week) => _buildWeekRow(week, cellSize)).toList(),
                  ),
                  
                  // Month labels
                  if (widget.showMonthLabels)
                    ..._monthTransitions.map((date) {
                      // Find the position of this date in our grid
                      int weekIndex = 0;
                      
                      // Find the position of this date in our grid
                      for (int w = 0; w < _weeks.length; w++) {
                        final week = _weeks[w];
                        final days = week['days'] as List<Map<String, dynamic>>;
                        
                        for (int d = 0; d < days.length; d++) {
                          final day = days[d];
                          if (day['date'] != null && 
                              day['date'] is DateTime && 
                              _isSameDay(day['date'] as DateTime, date)) {
                            weekIndex = w;
                            // No need to track dayIndexInWeek since we're only using vertical positioning
                            break;
                          }
                        }
                      }
                      
                      // Calculate position for month label
                      final monthFormat = DateFormat('MMM');
                      final monthLabel = monthFormat.format(date);
                      final verticalOffset = weekIndex * (cellSize + widget.cellSpacing);
                      
                      return Positioned(
                        left: 0,
                        top: verticalOffset,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: widget.backgroundColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            monthLabel,
                            style: TextStyle(
                              fontSize: cellSize * 0.75,
                              fontWeight: FontWeight.bold,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
  
  /// Calculate responsive cell size based on available width
  double _calculateResponsiveCellSize(double availableWidth) {
    // Account for day labels (if shown) and cell spacing
    double totalWidth = availableWidth;
    if (widget.showMonthLabels) {
      totalWidth -= 28; // Approximate space for month labels
    }
    if (widget.showWeekLabels) {
      totalWidth -= 40; // Approximate space for week labels
    }
    
    // Calculate based on 7 cells per row plus spacing
    double calculatedSize = (totalWidth - (7 - 1) * widget.cellSpacing) / 7;
    
    // Ensure minimum cell size
    return math.max(calculatedSize, 10.0);
  }
  
  /// Build the day labels (M, T, W, etc.)
  Widget _buildDayLabels(double cellSize) {
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    
    return Padding(
      padding: EdgeInsets.only(
        left: widget.showMonthLabels ? 28 : 0,
        right: widget.showWeekLabels ? 40 : 0,
        bottom: 4,
      ),
      child: Row(
        children: days.map((day) {
          return Container(
            width: cellSize,
            height: cellSize,
            margin: EdgeInsets.all(widget.cellSpacing / 2),
            alignment: Alignment.center,
            child: Text(
              day,
              style: TextStyle(
                fontSize: cellSize * 0.75,
                color: Colors.black54,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
  
  /// Build a week row
  Widget _buildWeekRow(Map<String, dynamic> week, double cellSize) {
    return Padding(
      padding: EdgeInsets.only(
        left: widget.showMonthLabels ? 28 : 0,
      ),
      child: Row(
        children: [
          // Week's days
          ...List.generate(7, (index) {
            final days = week['days'] as List<Map<String, dynamic>>;
            if (index < days.length) {
              return _buildDayCell(days[index], cellSize);
            } else {
              return const SizedBox.shrink();
            }
          }),
          
          // Week number (if enabled)
          if (widget.showWeekLabels)
            Container(
              width: 36,
              height: cellSize,
              margin: EdgeInsets.only(left: widget.cellSpacing),
              alignment: Alignment.centerLeft,
              child: Text(
                'W${week['weekNum']}',
                style: TextStyle(
                  fontSize: cellSize * 0.75,
                  color: Colors.black54,
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  /// Build a single day cell
  Widget _buildDayCell(Map<String, dynamic> day, double cellSize) {
    final date = day['date'] as DateTime?;
    final dailyTodo = day['dailyTodo'] as DailyTodo?;
    
    // Determine cell color based on completion rate
    Color cellColor = widget.emptyColor.withOpacity(0.1);
    if (dailyTodo != null && dailyTodo.taskGoal > 0) {
      final completionRate = dailyTodo.completionPercentage / 100;
      cellColor = Color.lerp(
        widget.emptyColor.withOpacity(0.1),
        widget.completedColor.withOpacity(0.8),
        completionRate,
      ) ?? widget.emptyColor;
    }
    
    return GestureDetector(
      onTap: () {
        if (dailyTodo != null && widget.onCellTap != null) {
          HapticFeedback.selectionClick();
          widget.onCellTap!(dailyTodo);
        }
      },
      child: Container(
        width: cellSize,
        height: cellSize,
        margin: EdgeInsets.all(widget.cellSpacing / 2),
        decoration: BoxDecoration(
          color: date == null ? Colors.transparent : cellColor,
          borderRadius: BorderRadius.circular(widget.cellBorderRadius),
          border: _isToday(date) 
            ? Border.all(color: Colors.blue, width: 2) 
            : null,
        ),
        child: dailyTodo != null && dailyTodo.deletedTodosCount > 0
          ? Center(
              child: Container(
                width: cellSize * 0.35,
                height: cellSize * 0.35,
                decoration: BoxDecoration(
                  color: widget.deletedColor.withOpacity(0.7),
                  shape: BoxShape.circle,
                ),
              ),
            )
          : null,
      ),
    );
  }
  
  /// Convert date to string key for map lookup
  String _dateToKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
  
  /// Check if two dates are the same day
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
  
  /// Check if a date is today
  bool _isToday(DateTime? date) {
    if (date == null) return false;
    final now = DateTime.now();
    return _isSameDay(date, now);
  }
  
  /// Get the week number (1-53) for a date
  int _getWeekNumber(DateTime date) {
    int dayOfYear = int.parse(DateFormat('D').format(date));
    return ((dayOfYear - date.weekday + 10) / 7).floor();
  }
  
  /// Group dates by week
  List<Map<String, dynamic>> _groupByWeek(
    DateTime startDate, 
    DateTime endDate, 
    Map<String, DailyTodo> dailyTodoMap
  ) {
    // Ensure start date is a Monday
    final adjustedStartDate = startDate.subtract(Duration(days: startDate.weekday - 1));
    
    final weeks = <Map<String, dynamic>>[];
    var currentDate = adjustedStartDate;
    
    while (currentDate.isBefore(endDate) || _isSameDay(currentDate, endDate)) {
      final week = <Map<String, dynamic>>[];
      final weekNum = _getWeekNumber(currentDate);
      
      // Add days for this week
      for (int i = 0; i < 7; i++) {
        if (currentDate.isAfter(endDate)) {
          // Future dates are empty
          week.add({'date': null, 'dailyTodo': null});
        } else if (currentDate.isBefore(startDate)) {
          // Past dates outside our range are empty
          week.add({'date': null, 'dailyTodo': null});
        } else {
          // Regular date
          final dateKey = _dateToKey(currentDate);
          final dailyTodo = dailyTodoMap[dateKey];
          week.add({
            'date': DateTime(currentDate.year, currentDate.month, currentDate.day),
            'dailyTodo': dailyTodo,
          });
        }
        
        currentDate = currentDate.add(const Duration(days: 1));
      }
      
      weeks.add({'weekNum': weekNum, 'days': week});
    }
    
    return weeks;
  }
}
