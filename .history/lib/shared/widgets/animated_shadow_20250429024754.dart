import 'package:flutter/material.dart';
import 'dart:math' as math;

class CreepingShadowAnimation extends StatefulWidget {
  final Widget child;
  final Duration animationDuration;
  final Curve curve;
  final Color shadowColor;
  final double maxShadowOpacity;
  final double maxShadowBlur;
  final double maxShadowSpread;

  const CreepingShadowAnimation({
    Key? key,
    required this.child,
    this.animationDuration = const Duration(minutes: 5),
    this.curve = Curves.easeInOut,
    this.shadowColor = Colors.black45,
    this.maxShadowOpacity = 0.5,
    this.maxShadowBlur = 25.0,
    this.maxShadowSpread = 10.0,
  }) : super(key: key);

  @override
  _CreepingShadowAnimationState createState() =>
      _CreepingShadowAnimationState();
}

class _CreepingShadowAnimationState extends State<CreepingShadowAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late Animation<Offset> _shadowPositionAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize the animation controller with the specified duration
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    // Create a curved animation using the specified curve
    _animation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );

    // Animation for the shadow's position across the screen
    _shadowPositionAnimation = Tween<Offset>(
      begin: const Offset(-0.5, -0.5),
      end: const Offset(1.2, 1.2),
    ).animate(_animation);

    // Start the animation and make it repeat
    _controller.repeat(reverse: false);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Stack(
          children: [
            // The main content
            widget.child,

            // The animated shadow overlay
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: ShadowPainter(
                    progress: _animation.value,
                    shadowPosition: _shadowPositionAnimation.value,
                    shadowColor: widget.shadowColor.withOpacity(
                        widget.maxShadowOpacity *
                            _getShadowIntensity(_animation.value)),
                    shadowBlur: widget.maxShadowBlur *
                        _getShadowIntensity(_animation.value),
                    shadowSpread: widget.maxShadowSpread *
                        _getShadowIntensity(_animation.value),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Function to calculate the shadow intensity based on the animation progress
  double _getShadowIntensity(double progress) {
    // This creates a pulsing effect by using a sine wave
    double pulseEffect = (math.sin(progress * 2 * math.pi) + 1) / 4;
    // Combine with linear progression
    return 0.3 + (progress * 0.5) + pulseEffect;
  }
}

class ShadowPainter extends CustomPainter {
  final double progress;
  final Offset shadowPosition;
  final Color shadowColor;
  final double shadowBlur;
  final double shadowSpread;

  ShadowPainter({
    required this.progress,
    required this.shadowPosition,
    required this.shadowColor,
    required this.shadowBlur,
    required this.shadowSpread,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Calculate the shadow's position and size based on the animation progress
    final double centerX = size.width * shadowPosition.dx;
    final double centerY = size.height * shadowPosition.dy;

    // Create a radial gradient for a more natural shadow effect
    final Paint paint = Paint()
      ..shader = RadialGradient(
        colors: [
          shadowColor,
          shadowColor.withOpacity(0.7),
          shadowColor.withOpacity(0.4),
          shadowColor.withOpacity(0.1),
          shadowColor.withOpacity(0.0),
        ],
        stops: const [0.0, 0.3, 0.6, 0.8, 1.0],
      ).createShader(
        Rect.fromCircle(
          center: Offset(centerX, centerY),
          radius: size.width * (0.5 + shadowSpread / 100) * progress,
        ),
      )
      ..maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        shadowBlur,
      );

    // Draw the shadow
    canvas.drawCircle(
      Offset(centerX, centerY),
      size.width * (0.5 + shadowSpread / 100) * progress,
      paint,
    );
  }

  @override
  bool shouldRepaint(ShadowPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.shadowPosition != shadowPosition ||
        oldDelegate.shadowColor != shadowColor ||
        oldDelegate.shadowBlur != shadowBlur ||
        oldDelegate.shadowSpread != shadowSpread;
  }
}

// Example usage in a screen
class ShadowAnimationDemo extends StatelessWidget {
  const ShadowAnimationDemo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CreepingShadowAnimation(
        animationDuration: const Duration(minutes: 10),
        shadowColor: Colors.purple.withOpacity(0.3),
        child: YourAppContent(),
      ),
    );
  }
}

// Replace with your actual app content
class YourAppContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Your App Content Here',
        style: TextStyle(fontSize: 24),
      ),
    );
  }
}
