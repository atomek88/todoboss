import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:todoApp/shared/animations/animation_constants.dart';
import 'package:todoApp/shared/utils/theme/color_scheme.dart';

/// A beautiful success animation with checkmark and particles
class SuccessAnimation extends StatefulWidget {
  /// Size of the success indicator
  final double size;
  
  /// Primary color of the success indicator
  final Color? color;
  
  /// Background color of the success indicator
  final Color? backgroundColor;
  
  /// Callback when animation completes
  final VoidCallback? onAnimationComplete;
  
  /// Whether to show particles
  final bool showParticles;

  const SuccessAnimation({
    Key? key,
    this.size = 120.0,
    this.color,
    this.backgroundColor,
    this.onAnimationComplete,
    this.showParticles = true,
  }) : super(key: key);

  @override
  State<SuccessAnimation> createState() => _SuccessAnimationState();
}

class _SuccessAnimationState extends State<SuccessAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _circleAnimation;
  late Animation<double> _checkAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _particleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller
    _controller = AnimationController(
      duration: AnimationConstants.medium,
      vsync: this,
    );
    
    // Create animations
    _circleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.0, 0.5, curve: AnimationConstants.defaultCurve),
      ),
    );
    
    _checkAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.5, 0.8, curve: AnimationConstants.sharpCurve),
      ),
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.5, 0.9, curve: AnimationConstants.bouncyCurve),
      ),
    );
    
    _particleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.6, 1.0, curve: AnimationConstants.sharpCurve),
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
    final color = widget.color ?? lightColorScheme.primary;
    final backgroundColor = widget.backgroundColor ?? lightColorScheme.primaryContainer;
    
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Particles
              if (widget.showParticles && _particleAnimation.value > 0)
                ...List.generate(12, (index) {
                  final angle = index * (math.pi * 2 / 12);
                  final distance = widget.size * 0.5 * _particleAnimation.value;
                  
                  return Positioned(
                    left: widget.size / 2 + math.cos(angle) * distance - 4,
                    top: widget.size / 2 + math.sin(angle) * distance - 4,
                    child: Opacity(
                      opacity: _particleAnimation.value,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: index % 2 == 0 ? color : lightColorScheme.secondary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.5),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              
              // Success circle
              Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  width: widget.size * 0.8,
                  height: widget.size * 0.8,
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: CustomPaint(
                    painter: _SuccessPainter(
                      circleValue: _circleAnimation.value,
                      checkValue: _checkAnimation.value,
                      color: color,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Custom painter for drawing the success checkmark
class _SuccessPainter extends CustomPainter {
  final double circleValue;
  final double checkValue;
  final Color color;

  _SuccessPainter({
    required this.circleValue,
    required this.checkValue,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // Draw circle
    final circlePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.08
      ..strokeCap = StrokeCap.round;
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.8),
      -math.pi / 2,
      2 * math.pi * circleValue,
      false,
      circlePaint,
    );
    
    // Draw checkmark
    if (checkValue > 0) {
      final checkPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.08
        ..strokeCap = StrokeCap.round;
      
      final path = Path();
      
      // First line of checkmark (shorter one)
      final firstLineStart = Offset(size.width * 0.3, size.height * 0.5);
      final firstLineEnd = Offset(
        size.width * 0.3 + (size.width * 0.15) * checkValue,
        size.height * 0.5 + (size.height * 0.15) * checkValue,
      );
      
      // Second line of checkmark (longer one)
      final secondLineEnd = Offset(
        size.width * 0.45 + (size.width * 0.25) * checkValue,
        size.height * 0.65 - (size.height * 0.3) * checkValue,
      );
      
      path.moveTo(firstLineStart.dx, firstLineStart.dy);
      path.lineTo(firstLineEnd.dx, firstLineEnd.dy);
      path.lineTo(secondLineEnd.dx, secondLineEnd.dy);
      
      canvas.drawPath(path, checkPaint);
    }
  }

  @override
  bool shouldRepaint(_SuccessPainter oldDelegate) {
    return oldDelegate.circleValue != circleValue ||
        oldDelegate.checkValue != checkValue ||
        oldDelegate.color != color;
  }
}
