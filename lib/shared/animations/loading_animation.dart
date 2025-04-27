import 'package:flutter/material.dart';
import 'package:todoApp/shared/animations/animation_constants.dart';
import 'package:todoApp/shared/utils/theme/color_scheme.dart';

/// A beautiful loading animation that shows a pulsing circle with a rotating arc
class LoadingAnimation extends StatefulWidget {
  /// Size of the loading indicator
  final double size;
  
  /// Primary color of the loading indicator
  final Color? color;
  
  /// Secondary color of the loading indicator
  final Color? secondaryColor;
  
  /// Stroke width of the arc
  final double strokeWidth;

  const LoadingAnimation({
    Key? key,
    this.size = 60.0,
    this.color,
    this.secondaryColor,
    this.strokeWidth = 4.0,
  }) : super(key: key);

  @override
  State<LoadingAnimation> createState() => _LoadingAnimationState();
}

class _LoadingAnimationState extends State<LoadingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;

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
        curve: Interval(0.0, 1.0, curve: AnimationConstants.defaultCurve),
      ),
    );
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.0, 1.0, curve: Curves.easeInOut),
      ),
    );
    
    // Start animation and repeat
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.color ?? lightColorScheme.primary;
    final secondaryColor = widget.secondaryColor ?? lightColorScheme.secondary;
    
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Pulsing background circle
              Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: widget.size * 0.85,
                  height: widget.size * 0.85,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primaryColor.withOpacity(0.1),
                  ),
                ),
              ),
              
              // Rotating arc
              Transform.rotate(
                angle: _rotationAnimation.value,
                child: CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: _LoadingArcPainter(
                    color: primaryColor,
                    secondaryColor: secondaryColor,
                    strokeWidth: widget.strokeWidth,
                    value: _controller.value,
                  ),
                ),
              ),
              
              // Center dot
              Container(
                width: widget.size * 0.15,
                height: widget.size * 0.15,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: secondaryColor,
                  boxShadow: [
                    BoxShadow(
                      color: secondaryColor.withOpacity(0.4),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Custom painter for drawing the loading arc
class _LoadingArcPainter extends CustomPainter {
  final Color color;
  final Color secondaryColor;
  final double strokeWidth;
  final double value;

  _LoadingArcPainter({
    required this.color,
    required this.secondaryColor,
    required this.strokeWidth,
    required this.value,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: size.width / 2 - strokeWidth / 2,
    );
    
    // Background circle
    final backgroundPaint = Paint()
      ..color = color.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth / 2
      ..strokeCap = StrokeCap.round;
    
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width / 2 - strokeWidth / 2,
      backgroundPaint,
    );
    
    // Foreground arc
    final foregroundPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          color.withOpacity(0.0),
          color,
          secondaryColor,
        ],
        stops: const [0.0, 0.5, 1.0],
        startAngle: 0,
        endAngle: AnimationConstants.fullRotation,
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    
    // Draw arc with dynamic sweep angle
    canvas.drawArc(
      rect,
      0,
      AnimationConstants.fullRotation * 0.75, // 270 degrees
      false,
      foregroundPaint,
    );
  }

  @override
  bool shouldRepaint(_LoadingArcPainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.color != color ||
        oldDelegate.secondaryColor != secondaryColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
