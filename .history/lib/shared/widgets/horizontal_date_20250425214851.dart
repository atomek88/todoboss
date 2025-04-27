import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class HorizontalDatePicker extends StatefulWidget {
  final DateTime initialDate;
  final Function(DateTime)? onDateChanged;
  final int visibleItemCount;
  final List<Color>? gradientColors;
  final TextStyle? selectedDateStyle;
  final TextStyle? adjacentDateStyle;

  const HorizontalDatePicker({
    Key? key,
    required this.initialDate,
    this.onDateChanged,
    this.visibleItemCount = 5,
    this.gradientColors,
    this.selectedDateStyle,
    this.adjacentDateStyle,
  }) : super(key: key);

  @override
  _HorizontalDatePickerState createState() => _HorizontalDatePickerState();
}

class _HorizontalDatePickerState extends State<HorizontalDatePicker> {
  late DateTime _currentDate;
  final ScrollController _scrollController = ScrollController();
  late List<DateTime> _dates;
  final PageController _pageController = PageController(
    viewportFraction: 0.25, // Show more dates
    initialPage: 180, // Start in the middle
  );

  @override
  void initState() {
    super.initState();
    _currentDate = widget.initialDate;
    _generateDates();
    WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToInitialDate());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _generateDates() {
    _dates = List.generate(
        365, (index) => DateTime.now().add(Duration(days: index - 180)));
  }

  void _jumpToInitialDate() {
    int centerIndex =
        _dates.indexWhere((date) => _isSameDay(date, _currentDate));
    _pageController.jumpToPage(centerIndex);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _onPageChanged(int index) {
    DateTime selectedDate = _dates[index];
    setState(() => _currentDate = selectedDate);
    if (widget.onDateChanged != null) widget.onDateChanged!(selectedDate);
    HapticFeedback.mediumImpact();
  }

  // Format date for display based on whether it's selected
  String _formatDate(DateTime date, bool isSelected) {
    if (isSelected) {
      return DateFormat('MMMM d')
          .format(date); // Full month name for selected date
    } else {
      return DateFormat('MMM d')
          .format(date); // Abbreviated month for adjacent dates
    }
  }

  @override
  Widget build(BuildContext context) {
    // Default gradient colors if not provided - matching the design image
    final gradientColors = widget.gradientColors ??
        [
          const Color(0xFFF5A78B), // Coral/salmon color from left side
          const Color(0xFFD279B6), // Pink/purple in middle
          const Color(0xFF8C67C8), // Purple color from right side
        ];

    return Column(
      children: [
        Container(
          height: 100,
          width: double.infinity, // Ensure full width to prevent overflow
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            itemCount: _dates.length,
            itemBuilder: (context, index) {
              final date = _dates[index];
              final isSelected = _isSameDay(date, _currentDate);
              final distance = (index - _pageController.page!).abs();
              final isVisible = distance < 2; // Only build visible items

              if (!isVisible) {
                return const SizedBox.shrink();
              }

              // Scale and opacity based on distance from center
              final scale = 1.0 - (distance * 0.2).clamp(0.0, 0.4);
              final opacity = 1.0 - (distance * 0.3).clamp(0.0, 0.6);

              // Choose text style based on whether date is selected
              final textStyle = isSelected
                  ? (widget.selectedDateStyle ??
                      const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        letterSpacing: 0.5,
                      ))
                  : (widget.adjacentDateStyle ??
                      TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                        color: Colors.black.withOpacity(0.7),
                        letterSpacing: 0.3,
                      ));

              return Transform.scale(
                scale: scale,
                child: Opacity(
                  opacity: opacity,
                  child: Center(
                    child: Text(
                      _formatDate(date, isSelected),
                      style: textStyle,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          color: Colors.black, // Background for tick marks
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              15,
              (_) => Container(
                height: 4,
                width: 1,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                color: Colors.white.withOpacity(0.4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
//
