import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import 'dart:async';
import 'package:intl/intl.dart';
import '../../core/providers/selected_date_provider.dart';
import 'package:todoApp/core/providers/date_provider.dart'
    show currentDateProvider, normalizeDate, refreshCurrentDate;
import 'package:todoApp/feature/todos/views/past_date_page.dart';

/// Provider to track background offset for parallax effect
final _parallaxOffsetProvider = StateProvider<double>((ref) => 0.0);

/// Provider to track current page for animation effects
final _currentPageProvider = StateProvider<double>((ref) => 500.0);

/// A swipeable date picker widget with elegant design inspired by Rolodex/gear dial metaphor
/// Features subtle swipe indicators, tick marks, and parallax background effect
class SwipeableDatePicker extends ConsumerStatefulWidget {
  /// Animation duration for the date change
  final Duration animationDuration;

  /// Background gradient colors for the date picker
  final List<Color>? gradientColors;

  /// Text style for the main date display
  final TextStyle? mainDateTextStyle;

  /// Text style for the adjacent date displays
  final TextStyle? adjacentDateTextStyle;

  /// Whether to provide haptic feedback on date change
  final bool enableHapticFeedback;

  /// Maximum number of days to jump on fast swipe
  final int maxDaysJumpOnFastSwipe;

  /// Height of the date picker container
  final double height;

  /// Whether to show tick marks below the dates
  final bool showTickMarks;

  /// Maximum days forward from current date that can be selected
  final int maxDaysForward;

  /// For backward compatibility with existing code
  final TextStyle? dateTextStyle;

  const SwipeableDatePicker({
    super.key,
    this.animationDuration = const Duration(milliseconds: 300),
    this.gradientColors,
    this.mainDateTextStyle,
    this.adjacentDateTextStyle,
    this.enableHapticFeedback = true,
    this.maxDaysJumpOnFastSwipe = 5,
    this.height = 100,
    this.showTickMarks = true,
    this.maxDaysForward = 7, // Limit to one week forward by default
    this.dateTextStyle, // For backward compatibility
  });

  @override
  ConsumerState<SwipeableDatePicker> createState() =>
      _SwipeableDatePickerState();
}

class _SwipeableDatePickerState extends ConsumerState<SwipeableDatePicker>
    with SingleTickerProviderStateMixin {
  // Controller for the PageView
  late PageController _pageController;

  // The middle page index (representing today)
  static const int _initialPage =
      500; // Large number to allow "infinite" scrolling

  // Animation controllers
  late AnimationController _transitionController;

  // Track swipe velocity for fast swipes
  double _swipeVelocity = 0.0;

  // Track if we're currently animating
  bool _isAnimating = false;

  // Debounce timer for date changes
  Timer? _dateChangeDebounceTimer;

  // The last stable date that was fully settled
  DateTime? _stableDate;

  @override
  void initState() {
    super.initState();

    // Initialize the page controller with the middle page
    _pageController = PageController(
      initialPage: _initialPage,
      viewportFraction: 0.6, // Show partial adjacent dates
    );

    // Initialize animation controller for transitions
    _transitionController = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    // Listen to page changes to update parallax effect and current page
    _pageController.addListener(_updateEffects);

    // Initialize with the current date
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Force refresh the current date to ensure we're using the actual current date
      refreshCurrentDate(ref);

      final currentDate = ref.read(currentDateProvider);
      final today = ref.read(selectedDateProvider);

      // Use the date provider's normalizeDate function for consistency
      final normalizedToday = normalizeDate(today);

      if (currentDate.year != normalizedToday.year ||
          currentDate.month != normalizedToday.month ||
          currentDate.day != normalizedToday.day) {
        debugPrint(
            '📅 [SwipeableDatePicker] Initializing with today\'s date: ${normalizedToday.toString()} (${normalizedToday.weekday})');
        ref.read(selectedDateProvider.notifier).setDate(normalizedToday);
      } else {
        debugPrint(
            '📅 [SwipeableDatePicker] Current date already set to today: ${normalizedToday.toString()} (${normalizedToday.weekday})');
      }
    });
  }

  @override
  void dispose() {
    _pageController.removeListener(_updateEffects);
    _pageController.dispose();
    _transitionController.dispose();
    _dateChangeDebounceTimer?.cancel();
    super.dispose();
  }

  // Update visual effects based on page position
  void _updateEffects() {
    if (_pageController.hasClients) {
      final offset = _pageController.page ?? _initialPage.toDouble();

      // Update parallax offset
      final normalizedOffset =
          (offset - _initialPage) / 5; // Scale down for subtle effect
      ref.read(_parallaxOffsetProvider.notifier).state = normalizedOffset;

      // Update current page for animations
      ref.read(_currentPageProvider.notifier).state = offset;
    }
  }

  // Handle date changes with proper animations and feedback
  void _changeDate(int dayOffset) {
    if (_isAnimating) return;
    _isAnimating = true;

    // Get current date and calculate new date
    final currentDate = ref.read(selectedDateProvider);

    // Ensure we're adding days to a normalized date to avoid time inconsistencies
    final normalizedDate = normalizeDate(currentDate);
    final newDate = normalizedDate.add(Duration(days: dayOffset));

    // Check if the new date is within allowed range
    if (!_isDateWithinAllowedRange(newDate)) {
      // If not within range, cancel animation and provide feedback
      _isAnimating = false;
      if (widget.enableHapticFeedback) {
        HapticFeedback
            .heavyImpact(); // Stronger feedback to indicate limit reached
      }
      return;
    }

    // Provide haptic feedback if enabled
    if (widget.enableHapticFeedback) {
      HapticFeedback.mediumImpact();
    }

    // Cancel any existing timers to avoid race conditions
    _dateChangeDebounceTimer?.cancel();

    // Update the visual state immediately for smooth animation
    // But apply a debounce before updating the actual provider state
    // to avoid thrashing when rapidly swiping
    debugPrint(
        '⏱️ [SwipeableDatePicker] Starting debounce timer for date change: $normalizedDate → $newDate');

    // Start a new debounce timer
    _dateChangeDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      // After debounce, update the selectedDateProvider with the new stable date
      if (!_isAnimating) {
        debugPrint(
            '⏱️ [SwipeableDatePicker] DEBOUNCED date change applied: $newDate');
        ref.read(selectedDateProvider.notifier).setDate(newDate);
        _stableDate = newDate; // Store the stable date
      }
    });

    // Then animate the page view
    final targetPage = _initialPage + dayOffset;
    _pageController
        .animateToPage(
      targetPage,
      duration: widget.animationDuration,
      curve: Curves.easeOutCubic,
    )
        .then((_) {
      // Animation complete
      // Update the provider immediately after animation completes
      // if we haven't already debounced
      debugPrint('🗓 [SwipeableDatePicker] Page animation completed');

      // Mark animation as complete
      _isAnimating = false;

      // Apply the date change immediately after animation completes
      // This ensures UI is instantly responsive while still preventing state thrashing
      if (_stableDate != newDate) {
        debugPrint(
            '🗓 [SwipeableDatePicker] Applying immediate date update after animation: $newDate');
        ref.read(selectedDateProvider.notifier).setDate(newDate);
        _stableDate = newDate;

        // Cancel any pending debounce since we've already updated
        _dateChangeDebounceTimer?.cancel();
      }

      // Reset page controller to middle to allow "infinite" scrolling
      if ((targetPage - _initialPage).abs() > 100) {
        _pageController.jumpToPage(_initialPage);
      }
    });

    // Start transition animation
    _transitionController.forward(from: 0.0);
  }

  // Format a date for display in full format (e.g., "Mon, Apr 24")
  String _formatDateFull(DateTime date) {
    // Use consistent date formatting to ensure what's displayed matches what's used
    final formattedDate = DateFormat('EEE, MMM d').format(date);
    debugPrint(
        '🗓 [SwipeableDatePicker] Formatted full date: $formattedDate for $date');
    return formattedDate;
  }

  // Format a date for display in abbreviated format (e.g., "Apr 23")
  String _formatDateAbbr(DateTime date) {
    return DateFormat('MMM d').format(date);
  }

  // This function has been removed as it's no longer needed
  // DateFormat is now used directly in _formatDateFull

  // Check if date is within allowed range
  bool _isDateWithinAllowedRange(DateTime date) {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    // Calculate difference in days
    final difference = dateOnly.difference(todayOnly).inDays;

    // Allow any date from the past, but limit future dates
    return difference <= widget.maxDaysForward;
  }

  // Build a date item widget for the PageView
  Widget _buildDateItem(int index) {
    // Calculate the date for this index
    final selectedDate = ref.read(selectedDateProvider);
    final dateToShow =
        normalizeDate(selectedDate.add(Duration(days: index - _initialPage)));

    // Log for debugging date consistency
    if (index == _initialPage) {
      debugPrint(
          '🗓 [SwipeableDatePicker] Central date item: ${dateToShow.toString()}');
    }

    // Get the current page position for animation effects
    final currentPage = ref.watch(_currentPageProvider);
    final distance = (index - currentPage).abs();
    final isCenter = distance < 0.5;

    // Enhanced perspective effect with more dramatic scaling
    final opacity =
        math.max(0.0, 1.0 - distance * 0.25); // Slower opacity falloff
    final scale = math.max(0.7, 1.0 - distance * 0.15); // More dramatic scaling

    // Format date based on position
    final formattedDate = isCenter
        ? "${_formatDateFull(dateToShow)}"
        : _formatDateAbbr(dateToShow);

    // Check if this is today's date
    final isToday = _isToday(dateToShow);

    return Transform.scale(
      scale: scale,
      child: Opacity(
        opacity: opacity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Date text with optional badge for today
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min, // To prevent overflow
              children: [
                Flexible(
                  child: Text(
                    formattedDate,
                    overflow: TextOverflow.ellipsis,
                    style: isCenter
                        ? widget.mainDateTextStyle ??
                            widget.dateTextStyle ??
                            TextStyle(
                              fontSize: 14, // Slightly smaller
                              fontWeight: FontWeight.bold,
                              color: isToday
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                            )
                        : widget.adjacentDateTextStyle ??
                            TextStyle(
                              fontSize: 10, // Slightly smaller
                              fontWeight: FontWeight.w400,
                              color: Colors.grey.shade500,
                            ),
                  ),
                ),
                if (isToday && isCenter)
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 2.0),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Today',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Check if the given date is today
  bool _isToday(DateTime date) {
    final today = ref.read(currentDateProvider);
    return date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
  }

  // Build tick marks below the date display
  Widget _buildTickMarks() {
    return Container(
      height: 8,
      margin: const EdgeInsets.only(top: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (int i = -2; i <= 2; i++)
            Container(
              width: i == 0 ? 24 : 8,
              height: i == 0 ? 4 : 2,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: i == 0
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
        ],
      ),
    );
  }

  // Build the parallax gradient background
  Widget _buildBackgroundGradient() {
    // Get the parallax offset for background movement
    final parallaxOffset = ref.watch(_parallaxOffsetProvider);

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 0),
      left: -30 - (parallaxOffset * 15), // Subtle parallax effect
      right: -30 + (parallaxOffset * 15),
      top: -20,
      bottom: -20,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: widget.gradientColors ??
                [
                  Colors.blue.shade100.withOpacity(0.2),
                  Colors.blue.shade50.withOpacity(0.1),
                  Colors.blue.shade100.withOpacity(0.2),
                ],
          ),
        ),
      ),
    );
  }

  // Handle swipe gestures with velocity awareness
  void _handleSwipeGesture(double velocity) {
    // Don't respond to tiny movements
    if (velocity.abs() < 50) return;

    // Determine direction and sensitivity
    final direction = velocity > 0 ? -1 : 1; // Swipe right = previous day
    var daysToJump = 1;

    // Fast swipe - jump multiple days (reduced sensitivity)
    if (velocity.abs() > 1500) {
      daysToJump = math.min(((velocity.abs() - 1500) / 700).round() + 1,
          widget.maxDaysJumpOnFastSwipe);
    }

    // Change the date with the calculated jump
    _changeDate(direction * daysToJump);
  }

  @override
  Widget build(BuildContext context) {
    // Watch selected date
    final selectedDate = ref.watch(selectedDateProvider);

    // Ensure we have a normalized date for consistent display
    final normalizedDate = normalizeDate(selectedDate);

    // Extensive diagnostics for date inconsistency debugging
    debugPrint(
        '📅 [SwipeableDatePicker] Building with selectedDate: $selectedDate');
    debugPrint(
        '📅 [SwipeableDatePicker] Normalized for display: $normalizedDate');

    // Compare with the date that will be used for filtering
    final filteredDate = ref.read(selectedDateProvider);
    final formattedFilterDate = DateFormat('EEE, MMM d').format(filteredDate);

    // Log both date representations to help diagnose discrepancies
    debugPrint(
        '📅 [SwipeableDatePicker] Current UI date: ${_formatDateFull(normalizedDate)}');
    debugPrint(
        '📅 [SwipeableDatePicker] Filter date: $formattedFilterDate (day: ${filteredDate.weekday})');

    // Check if there's a mismatch and log a warning
    if (normalizedDate.day != filteredDate.day ||
        normalizedDate.month != filteredDate.month ||
        normalizedDate.year != filteredDate.year) {
      debugPrint(
          '⚠️ [SwipeableDatePicker] DATE MISMATCH DETECTED between display and filter dates!');
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: widget.height,
          child: Stack(
            children: [
              _buildBackgroundGradient(),

              // Main content
              Positioned.fill(
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    // Track velocity for fast swipes
                    _swipeVelocity = details.primaryDelta ?? 0;
                  },
                  onHorizontalDragEnd: (details) {
                    // Process swipe based on velocity
                    _handleSwipeGesture(details.primaryVelocity ?? 0);
                  },
                  onTap: () {
                    // Navigate to PastDatePage when tapping on the central date
                    final date = ref.read(selectedDateProvider);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => PastDatePage(date: date),
                      ),
                    );
                  },
                  child: PageView.builder(
                    controller: _pageController,
                    physics:
                        const NeverScrollableScrollPhysics(), // We'll handle scrolling ourselves
                    itemCount: 1000, // Large number for "infinite" scrolling
                    itemBuilder: (context, index) => _buildDateItem(index),
                  ),
                ),
              ),

              // Button overlays for tapping left/right
              Positioned.fill(
                child: Row(
                  children: [
                    // Left button (previous day)
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _changeDate(-1),
                        behavior: HitTestBehavior.translucent,
                        child: Container(color: Colors.transparent),
                      ),
                    ),

                    // Middle section (tap to view date details)
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          final date = ref.read(selectedDateProvider);
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => PastDatePage(date: date),
                            ),
                          );
                        },
                        behavior: HitTestBehavior.translucent,
                        child: Container(
                          color: Colors.transparent,
                          child: Center(
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.calendar_today,
                                size: 20,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Right button (next day)
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _changeDate(1),
                        behavior: HitTestBehavior.translucent,
                        child: Container(color: Colors.transparent),
                      ),
                    ),
                  ],
                ),
              ),

              // Optional tick marks
              if (widget.showTickMarks)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _buildTickMarks(),
                ),
            ],
          ),
        ),

        // Small Save/Cancel buttons at the bottom
        Padding(
          padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: TextButton.styleFrom(
                  minimumSize: const Size(80, 36), // Smaller button
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final date = ref.read(selectedDateProvider);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => PastDatePage(date: date),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(80, 36), // Smaller button
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
                child: const Text('View'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
