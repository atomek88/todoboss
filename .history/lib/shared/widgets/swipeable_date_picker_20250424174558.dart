import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'dart:math' as math;
import '../providers/selected_date_provider.dart';

/// Provider to track visible dates in the date picker
final _visibleDatesProvider = StateProvider<List<DateTime>>((ref) {
  final currentDate = ref.watch(selectedDateProvider);
  return List.generate(
    7, // Show a week of dates
    (index) => currentDate.add(Duration(days: index - 3)), // 3 days before and after
  );
});

/// Provider to track loading state for date transitions
final _dateTransitionLoadingProvider = StateProvider<bool>((ref) => false);

/// A swipeable date picker widget that shows a horizontal scrollable list of dates
/// with the current date in the center and adjacent dates appearing smaller
class SwipeableDatePicker extends ConsumerStatefulWidget {
  /// Optional suffix text to display after the date
  final String? suffixText;
  
  /// Optional style for the date text
  final TextStyle? dateTextStyle;
  
  /// Optional style for the suffix text
  final TextStyle? suffixTextStyle;
  
  /// Animation duration for the date change
  final Duration animationDuration;
  
  /// Number of visible dates on each side of the selected date
  final int visibleDatesOnEachSide;

  const SwipeableDatePicker({
    super.key,
    this.suffixText,
    this.dateTextStyle,
    this.suffixTextStyle,
    this.animationDuration = const Duration(milliseconds: 300),
    this.visibleDatesOnEachSide = 2,
  });

  @override
  ConsumerState<SwipeableDatePicker> createState() => _SwipeableDatePickerState();
}

class _SwipeableDatePickerState extends ConsumerState<SwipeableDatePicker> with SingleTickerProviderStateMixin {
  // Controller for the PageView
  late PageController _pageController;
  
  // Number of dates to show on each side of the current date
  late int _daysVisible;
  
  // The middle page index (representing today)
  static const int _initialPage = 500; // Large number to allow "infinite" scrolling
  
  late AnimationController _loadingController;
  Timer? _loadingTimer;
  
  @override
  void initState() {
    super.initState();
    _daysVisible = widget.visibleDatesOnEachSide * 2 + 1; // Total visible dates
    
    // Initialize the page controller with the middle page
    _pageController = PageController(
      initialPage: _initialPage,
      viewportFraction: 0.2, // Show multiple dates in the viewport
    );
    
    // Update the visible dates when the widget is first created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateVisibleDates(_initialPage);
    });
    
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    _loadingController.dispose();
    _loadingTimer?.cancel();
    super.dispose();
  }
  
  // Update the visible dates based on the current page
  void _updateVisibleDates(int currentPage) {
    final selectedDate = ref.read(selectedDateProvider);
    final offset = currentPage - _initialPage;
    final newDate = selectedDate.add(Duration(days: offset));
    
    // Update the selected date
    if (offset != 0) {
      ref.read(selectedDateProvider.notifier).setDate(newDate);
    }
    
    // Update the list of visible dates
    final visibleDates = List.generate(
      _daysVisible,
      (index) => newDate.add(Duration(days: index - widget.visibleDatesOnEachSide)),
    );
    ref.read(_visibleDatesProvider.notifier).state = visibleDates;
    
    // Start loading animation
    _startLoadingAnimation();
  }
  
  void _startLoadingAnimation() {
    // Cancel any existing timer
    _loadingTimer?.cancel();
    
    // Set loading state to true
    ref.read(_dateTransitionLoadingProvider.notifier).state = true;
    
    // Start the animation
    _loadingController.reset();
    _loadingController.forward();
    
    // Set a timer to finish the loading state
    _loadingTimer = Timer(const Duration(milliseconds: 600), () {
      ref.read(_dateTransitionLoadingProvider.notifier).state = false;
    });
  }
  
  // Format a date for display
  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }
  
  // Check if a date is today
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }
  
  // Build a date item widget
  Widget _buildDateItem(DateTime date, bool isSelected, double distance) {
    // Calculate scale based on distance from center (0.0 to 1.0)
    // Center item has distance 0, items further away have higher distance
    final scale = 1.0 - (0.3 * math.min(1.0, distance.abs()));
    final opacity = 1.0 - (0.5 * math.min(1.0, distance.abs()));
    
    final isDateToday = _isToday(date);
    
    return Transform.scale(
      scale: scale,
      child: Opacity(
        opacity: opacity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Day of month (larger)
            Text(
              date.day.toString(),
              style: TextStyle(
                fontSize: isSelected ? 32 : 24,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isDateToday ? Colors.blue : (isSelected ? Colors.black : Colors.grey),
              ),
            ),
            // Month (smaller)
            Text(
              _formatDate(date).split(' ')[0], // Just the month abbreviation
              style: TextStyle(
                fontSize: isSelected ? 14 : 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isDateToday ? Colors.blue : (isSelected ? Colors.black : Colors.grey.shade600),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    // Get the current selected date
    final selectedDate = ref.watch(selectedDateProvider);
    // Watch the loading state
    final isLoading = ref.watch(_dateTransitionLoadingProvider);
    
    return Container(
      height: 100, // Fixed height for the date picker
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            Colors.blue.withOpacity(0.1),
            Colors.purple.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: _updateVisibleDates,
            itemBuilder: (context, index) {
              // Calculate the date for this page
              final pageDate = selectedDate.add(Duration(days: index - _initialPage));
              final isSelected = index == _pageController.page?.round();
              
              // Calculate distance from center (0.0 to 1.0)
              final distance = (index - (_pageController.page ?? _initialPage)).abs() / widget.visibleDatesOnEachSide;
              
              return Center(
                child: _buildDateItem(pageDate, isSelected, distance),
              );
            },
          ),
          if (isLoading)
            AnimatedBuilder(
              animation: _loadingController,
              builder: (context, child) {
                return Container(
                  width: 60,
                  height: 2,
                  margin: const EdgeInsets.only(top: 30),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.blue.withOpacity(0.7),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  transform: Matrix4.translationValues(
                    -30 + 120 * _loadingController.value, 0, 0),
                );
              },
            ),
          if (widget.suffixText != null)
            Positioned(
              bottom: 10,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(width: 8),
                  Text(
                    widget.suffixText!,
                    style: widget.suffixTextStyle ??
                        const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      
  }
}
