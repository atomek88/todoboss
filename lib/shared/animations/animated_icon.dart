import 'package:flutter/material.dart';
import 'package:todoApp/shared/animations/animation_constants.dart';
import 'package:todoApp/shared/utils/theme/color_scheme.dart';

/// A beautiful animated icon that can transition between two states
class AnimatedAppIcon extends StatefulWidget {
  /// The first icon to display
  final IconData firstIcon;
  
  /// The second icon to display (for toggle)
  final IconData secondIcon;
  
  /// Size of the icon
  final double size;
  
  /// Color of the icon
  final Color? color;
  
  /// Background color of the icon container
  final Color? backgroundColor;
  
  /// Whether the icon is in the second state
  final bool isSecondState;
  
  /// Callback when the icon is tapped
  final VoidCallback? onTap;
  
  /// Whether to show a background
  final bool showBackground;
  
  /// Whether to animate on initial build
  final bool animateOnInit;

  const AnimatedAppIcon({
    Key? key,
    required this.firstIcon,
    required this.secondIcon,
    this.size = 24.0,
    this.color,
    this.backgroundColor,
    this.isSecondState = false,
    this.onTap,
    this.showBackground = true,
    this.animateOnInit = false,
  }) : super(key: key);

  @override
  State<AnimatedAppIcon> createState() => _AnimatedAppIconState();
}

class _AnimatedAppIconState extends State<AnimatedAppIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  late Animation<double> _firstIconOpacityAnimation;
  late Animation<double> _secondIconOpacityAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller
    _controller = AnimationController(
      duration: AnimationConstants.fast,
      vsync: this,
    );
    
    // Create animations
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: AnimationConstants.halfRotation,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.0, 1.0, curve: AnimationConstants.sharpCurve),
      ),
    );
    
    _firstIconOpacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.0, 0.5, curve: AnimationConstants.defaultCurve),
      ),
    );
    
    _secondIconOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.5, 1.0, curve: AnimationConstants.defaultCurve),
      ),
    );
    
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.8),
        weight: 1.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.8, end: 1.0),
        weight: 1.0,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: AnimationConstants.defaultCurve,
      ),
    );
    
    // Set initial state
    if (widget.isSecondState) {
      _controller.value = 1.0;
    }
    
    // Animate on init if requested
    if (widget.animateOnInit && widget.isSecondState) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void didUpdateWidget(AnimatedAppIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Animate when isSecondState changes
    if (widget.isSecondState != oldWidget.isSecondState) {
      if (widget.isSecondState) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? lightColorScheme.primary;
    final backgroundColor = widget.backgroundColor ?? lightColorScheme.primaryContainer;
    
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: widget.showBackground ? widget.size * 1.8 : widget.size,
              height: widget.showBackground ? widget.size * 1.8 : widget.size,
              decoration: widget.showBackground
                  ? BoxDecoration(
                      color: backgroundColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.2),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    )
                  : null,
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // First icon
                    Opacity(
                      opacity: _firstIconOpacityAnimation.value,
                      child: Transform.rotate(
                        angle: _rotationAnimation.value,
                        child: Icon(
                          widget.firstIcon,
                          size: widget.size,
                          color: color,
                        ),
                      ),
                    ),
                    
                    // Second icon
                    Opacity(
                      opacity: _secondIconOpacityAnimation.value,
                      child: Transform.rotate(
                        angle: _rotationAnimation.value,
                        child: Icon(
                          widget.secondIcon,
                          size: widget.size,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
