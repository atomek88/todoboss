import 'package:flutter/material.dart';
import 'package:todoApp/shared/animations/animation_constants.dart';
import 'package:todoApp/shared/utils/theme/color_scheme.dart';

/// A beautiful launch screen animation widget that displays a spinning logo
/// that scales and fades in
class LaunchScreenAnimation extends StatefulWidget {
  /// The logo to display (defaults to a placeholder if not provided)
  final Widget? logo;
  
  /// The size of the logo container
  final double size;
  
  /// Background color (defaults to the primary container color)
  final Color? backgroundColor;
  
  /// Callback when animation completes
  final VoidCallback? onAnimationComplete;

  const LaunchScreenAnimation({
    Key? key,
    this.logo,
    this.size = 120.0,
    this.backgroundColor,
    this.onAnimationComplete,
  }) : super(key: key);

  @override
  State<LaunchScreenAnimation> createState() => _LaunchScreenAnimationState();
}

class _LaunchScreenAnimationState extends State<LaunchScreenAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller
    _controller = AnimationController(
      duration: AnimationConstants.slow,
      vsync: this,
    );
    
    // Create animations
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: AnimationConstants.fullRotation,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.0, 0.7, curve: AnimationConstants.gentleCurve),
      ),
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.2, 0.8, curve: AnimationConstants.bouncyCurve),
      ),
    );
    
    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.0, 0.6, curve: AnimationConstants.defaultCurve),
      ),
    );
    
    // Start animation
    _controller.forward();
    
    // Call onAnimationComplete when animation finishes
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && widget.onAnimationComplete != null) {
        widget.onAnimationComplete!();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          color: widget.backgroundColor ?? lightColorScheme.primaryContainer,
          child: Center(
            child: Opacity(
              opacity: _opacityAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Transform.rotate(
                  angle: _rotationAnimation.value,
                  child: Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      color: lightColorScheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: lightColorScheme.primary.withOpacity(0.3),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: widget.logo ?? _buildDefaultLogo(),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDefaultLogo() {
    return Center(
      child: Icon(
        Icons.check_circle_outline,
        size: widget.size * 0.6,
        color: lightColorScheme.primary,
      ),
    );
  }
}
