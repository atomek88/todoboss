import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:intl/intl.dart';
import '../providers/selected_date_provider.dart';

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

  // For backward compatibility with existing code

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
      final currentDate = ref.read(selectedDateProvider);
      final today = DateTime.now();
      if (currentDate.year != today.year ||
          currentDate.month != today.month ||
          currentDate.day != today.day) {
        ref.read(selectedDateProvider.notifier).setDate(today);
      }
    });
  }

  @override
  void dispose() {
    _pageController.removeListener(_updateEffects);
    _pageController.dispose();
    _transitionController.dispose();
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
    final newDate = currentDate.add(Duration(days: dayOffset));

    // Provide haptic feedback if enabled
    if (widget.enableHapticFeedback) {
      HapticFeedback.mediumImpact();
    }

    // Update the selected date
    ref.read(selectedDateProvider.notifier).setDate(newDate);

    // Animate to the new page
    final targetPage = _initialPage + dayOffset;
    _pageController
        .animateToPage(
      targetPage,
      duration: widget.animationDuration,
      curve: Curves.easeOutCubic,
    )
        .then((_) {
      _isAnimating = false;

      // Reset page controller to middle to allow "infinite" scrolling
      if ((targetPage - _initialPage).abs() > 100) {
        _pageController.jumpToPage(_initialPage);
      }
    });

    // Start transition animation
    _transitionController.forward(from: 0.0);
  }

  // Format a date for display in full format (e.g., "April 24")
  String _formatDateFull(DateTime date) {
    return DateFormat('MMMM d').format(date);
  }

  // Format a date for display in abbreviated format (e.g., "Apr 23")
  String _formatDateAbbr(DateTime date) {
    return DateFormat('MMM d').format(date);
  }

  // Build a date item widget for the PageView
  Widget _buildDateItem(int index) {
    // Calculate the date for this index
    final selectedDate = ref.watch(selectedDateProvider);
    final dayOffset = index - _initialPage;
    final date = selectedDate.add(Duration(days: dayOffset));

    // Get the current page position for animation effects
    final currentPage = ref.watch(_currentPageProvider);
    final distance = (index - currentPage).abs();
    final isCenter = distance < 0.5;

    // Calculate opacity and scale based on distance from center
    final opacity = math.max(0.0, 1.0 - distance * 0.3);
    final scale = math.max(0.8, 1.0 - distance * 0.1);

    // Format date based on position
    final formattedDate =
        isCenter ? _formatDateFull(date) : _formatDateAbbr(date);

    // Choose text style based on position - matching the design image
    final textStyle = isCenter
        ? (widget.mainDateTextStyle ??
            widget.dateTextStyle ??
            const TextStyle(
              fontSize: 28, // Larger font size for center date
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ))
        : (widget.adjacentDateTextStyle ??
            TextStyle(
              fontSize: 18, // Slightly larger for adjacent dates
              fontWeight: FontWeight.w400,
              color:
                  Colors.white.withOpacity(0.7), // More visible adjacent dates
              letterSpacing: 0.3,
            ));

    return Transform.scale(
      scale: scale,
      child: Opacity(
        opacity: opacity,
        child: Center(
          child: Text(
            formattedDate,
            style: textStyle,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  // Build tick marks for the date picker - matching the design image
  Widget _buildTickMarks() {
    return SizedBox(
      height: 6,
      width: double.infinity, // Ensure full width
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(15, (index) {
          // Create evenly spaced tick marks
          return Container(
            width: 1,
            height: 4,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.4),
              borderRadius: BorderRadius.circular(0.5),
            ),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get the current selected date
    final selectedDate = ref.watch(selectedDateProvider);
    // We're not using parallax effect with the new design
    // but keeping the provider for future enhancements

    // Default gradient colors if not provided - matching the design image
    final gradientColors = widget.gradientColors ??
        [
          const Color(0xFFF5A78B), // Coral/salmon color from left side
          const Color(0xFFD279B6), // Pink/purple in middle
          const Color(0xFF8C67C8), // Purple color from right side
        ];

    return Container(
      height: widget.height,
      width: double.infinity, // Ensure full width to prevent overflow
      decoration: BoxDecoration(
        // Gradient background with parallax effect
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Main content with PageView for swiping
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Date PageView
              SizedBox(
                height: widget.height - (widget.showTickMarks ? 20 : 0),
                width: double.infinity, // Ensure full width to prevent overflow
                child: GestureDetector(
                  // Handle horizontal drag for date changes
                  onHorizontalDragEnd: (details) {
                    // Capture velocity for fast swipes
                    _swipeVelocity = details.primaryVelocity ?? 0;

                    // Determine direction and number of days to jump
                    if (_swipeVelocity.abs() > 100) {
                      final direction = _swipeVelocity > 0
                          ? -1
                          : 1; // Swipe right = previous day

                      // Calculate days to jump based on velocity
                      int daysToJump = 1;
                      if (_swipeVelocity.abs() > 1000) {
                        // Fast swipe - jump multiple days
                        daysToJump = math.min(
                            ((_swipeVelocity.abs() - 1000) / 500).round() + 1,
                            widget.maxDaysJumpOnFastSwipe);
                      }

                      _changeDate(direction * daysToJump);
                    }
                  },

                  // Track swipe start for better gesture detection
                  onHorizontalDragStart: (_) {
                    _swipeVelocity = 0;
                  },

                  child: PageView.builder(
                    controller: _pageController,
                    itemBuilder: (context, index) => _buildDateItem(index),
                    onPageChanged: (index) {
                      // Update selected date when page changes
                      final dayOffset = index - _initialPage;
                      if (dayOffset != 0) {
                        final newDate =
                            selectedDate.add(Duration(days: dayOffset));
                        ref
                            .read(selectedDateProvider.notifier)
                            .setDate(newDate);

                        // Provide haptic feedback
                        if (widget.enableHapticFeedback) {
                          HapticFeedback.mediumImpact();
                        }
                      }
                    },
                  ),
                ),
              ),

              // Tick marks below the dates
              if (widget.showTickMarks)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: _buildTickMarks(),
                ),
            ],
          ),

          // Accessibility hint (semantics only)
          Semantics(
            label: "Date picker showing ${_formatDateFull(selectedDate)}",
            hint: "Swipe left or right to change the day",
            child: const SizedBox.expand(),
          ),
        ],
      ),
    );
  }
}
