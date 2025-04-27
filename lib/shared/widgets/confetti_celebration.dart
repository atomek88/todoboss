import 'dart:math';
import 'package:flutter/material.dart';

/// A widget that displays a confetti/sparkle celebration animation
class ConfettiCelebration extends StatefulWidget {
  /// Whether the animation is playing
  final bool isPlaying;
  
  /// Duration of the animation
  final Duration duration;
  
  /// Number of particles to display
  final int particleCount;
  
  /// Colors of the particles
  final List<Color> colors;
  
  /// Child widget to display beneath the confetti
  final Widget child;
  
  /// Maximum number of animation cycles
  final int maxCycles;
  
  /// Callback when animation completes
  final VoidCallback? onComplete;

  const ConfettiCelebration({
    Key? key,
    required this.isPlaying,
    required this.child,
    this.duration = const Duration(seconds: 2),
    this.particleCount = 50,
    this.maxCycles = 2,
    this.onComplete,
    this.colors = const [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.purple,
      Colors.orange,
    ],
  }) : super(key: key);

  @override
  State<ConfettiCelebration> createState() => _ConfettiCelebrationState();
}

class _ConfettiCelebrationState extends State<ConfettiCelebration> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Particle> _particles;
  final Random _random = Random();
  int _currentCycle = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    
    // Add listener for animation completion
    _controller.addStatusListener(_handleAnimationStatus);
    
    _initializeParticles();
    
    // Listen for changes in isPlaying
    _updatePlayState();
  }
  
  @override
  void didUpdateWidget(ConfettiCelebration oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      _updatePlayState();
    }
    
    if (widget.particleCount != oldWidget.particleCount) {
      _initializeParticles();
    }
    
    // Reset cycle count if duration changed
    if (widget.duration != oldWidget.duration) {
      _controller.duration = widget.duration;
      _currentCycle = 0;
    }
  }
  
  void _handleAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _currentCycle++;
      
      // Check if we've reached the maximum number of cycles
      if (_currentCycle >= widget.maxCycles) {
        // Call the onComplete callback if provided
        if (widget.onComplete != null) {
          widget.onComplete!();
        }
      } else {
        // Start the next cycle
        if (widget.isPlaying) {
          _controller.reset();
          _initializeParticles(); // Reinitialize particles for variety
          _controller.forward();
        }
      }
    }
  }
  
  void _updatePlayState() {
    if (widget.isPlaying) {
      _currentCycle = 0;
      _controller.reset();
      _controller.forward();
    } else {
      _controller.stop();
    }
  }
  
  void _initializeParticles() {
    _particles = List.generate(
      widget.particleCount,
      (_) => Particle(
        color: widget.colors[_random.nextInt(widget.colors.length)],
        position: Offset(
          _random.nextDouble() * 400,
          _random.nextDouble() * 200 - 250,
        ),
        size: _random.nextDouble() * 15 + 5,
        speed: _random.nextDouble() * 200 + 100,
        angle: _random.nextDouble() * pi,
        angleSpeed: _random.nextDouble() * 2 - 1,
        sparkleRate: _random.nextDouble() * 0.8 + 0.2,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Child is always on top to ensure interactivity
        widget.child,
        
        // Confetti is behind the child and doesn't block interaction
        if (widget.isPlaying)
          Positioned.fill(
            child: IgnorePointer(
              // Make sure the confetti doesn't block interaction
              ignoring: true,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return CustomPaint(
                    painter: ConfettiPainter(
                      particles: _particles,
                      progress: _controller.value,
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}

/// Represents a single confetti particle
class Particle {
  final Color color;
  final Offset position;
  final double size;
  final double speed;
  final double angle;
  final double angleSpeed;
  final double sparkleRate;

  Particle({
    required this.color,
    required this.position,
    required this.size,
    required this.speed,
    required this.angle,
    required this.angleSpeed,
    required this.sparkleRate,
  });
}

/// CustomPainter for drawing the confetti particles
class ConfettiPainter extends CustomPainter {
  final List<Particle> particles;
  final double progress;
  final Paint _paint = Paint();
  final Random _random = Random();

  ConfettiPainter({
    required this.particles,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      // Calculate current position based on progress
      final currentPosition = Offset(
        particle.position.dx + cos(particle.angle) * particle.speed * progress,
        particle.position.dy + sin(particle.angle) * particle.speed * progress + 
            // Add gravity effect
            200 * progress * progress,
      );
      
      // Only draw if within bounds
      if (currentPosition.dx >= 0 &&
          currentPosition.dx <= size.width &&
          currentPosition.dy >= 0 &&
          currentPosition.dy <= size.height) {
        
        // Sparkle effect - vary the opacity based on time and sparkle rate
        final shouldSparkle = _random.nextDouble() < particle.sparkleRate;
        final opacity = shouldSparkle ? 0.8 : 0.4;
        
        // Draw star/sparkle shape
        _paint.color = particle.color.withOpacity(opacity);
        
        // Rotate the star over time
        final rotation = progress * particle.angleSpeed * 2 * pi;
        
        canvas.save();
        canvas.translate(currentPosition.dx, currentPosition.dy);
        canvas.rotate(rotation);
        
        // Draw a star shape
        final path = Path();
        final outerRadius = particle.size;
        final innerRadius = particle.size * 0.4;
        final numPoints = 5;
        
        for (int i = 0; i < numPoints * 2; i++) {
          final radius = i.isEven ? outerRadius : innerRadius;
          final angle = i * pi / numPoints;
          final x = cos(angle) * radius;
          final y = sin(angle) * radius;
          
          if (i == 0) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
          }
        }
        path.close();
        
        canvas.drawPath(path, _paint);
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
