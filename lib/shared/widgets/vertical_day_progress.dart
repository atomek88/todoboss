import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:todoApp/core/providers/date_provider.dart';

class VerticalDayProgressScreen extends ConsumerStatefulWidget {
  const VerticalDayProgressScreen({super.key});

  @override
  ConsumerState<VerticalDayProgressScreen> createState() =>
      _VerticalDayProgressScreenState();
}

class _VerticalDayProgressScreenState
    extends ConsumerState<VerticalDayProgressScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _vibratedForGoal = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(minutes: 1),
    )..repeat();

    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);

    Timer.periodic(const Duration(minutes: 1), (timer) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _calculateDayProgress() {
    final now = ref.read(currentDateProvider);
    return (now.hour * 60 + now.minute) / (24 * 60);
  }

  @override
  Widget build(BuildContext context) {
    final now = ref.watch(currentDateProvider);
    final int hour = now.hour;

    Color sliderColor = Colors.blue;
    if (hour >= 6 && hour < 12) {
      sliderColor = Colors.lightBlueAccent;
    } else if (hour >= 12 && hour < 18) {
      sliderColor = Colors.orangeAccent;
    } else if (hour >= 18 || hour < 6) {
      sliderColor = Colors.deepPurpleAccent;
    }

    double progress = _calculateDayProgress();
    if (progress >= 1.0 && !_vibratedForGoal) {
      HapticFeedback.mediumImpact();
      _vibratedForGoal = true;
    } else if (progress < 1.0) {
      _vibratedForGoal = false;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Stack(
        children: [
          Row(
            children: [
              SizedBox(width: 32, child: _RulerWidget()),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: ListView.builder(
                    itemCount: 20,
                    itemBuilder: (context, index) => Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        title: Text('Task #$index',
                            style: const TextStyle(color: Colors.white)),
                        tileColor: Colors.grey[850],
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 32, child: _RulerWidget(opacity: 0.2)),
            ],
          ),
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              final screenHeight = MediaQuery.of(context).size.height;
              return Positioned(
                top: screenHeight * progress,
                left: 0,
                right: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Current time: ${DateFormat('h:mm a').format(DateTime.now())}',
                            style: const TextStyle(color: Colors.white),
                          ),
                          backgroundColor: Colors.black87,
                        ),
                      );
                    },
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            sliderColor.withOpacity(0.8),
                            sliderColor.withOpacity(0.5)
                          ],
                          center: Alignment.center,
                          radius: 0.6,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: sliderColor.withOpacity(0.8),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RulerWidget extends StatelessWidget {
  final double opacity;
  const _RulerWidget({this.opacity = 0.4});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        return CustomPaint(
          painter: _RulerPainter(opacity: opacity),
          size: Size(32, height),
        );
      },
    );
  }
}

class _RulerPainter extends CustomPainter {
  final double opacity;
  _RulerPainter({this.opacity = 0.4});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(opacity)
      ..strokeWidth = 1;

    const double hours = 24;
    final double spacing = size.height / hours;

    for (int i = 0; i <= hours; i++) {
      final y = i * spacing;
      final isMajor = i % 3 == 0;

      canvas.drawLine(
        Offset(isMajor ? 0 : size.width * 0.5, y),
        Offset(size.width, y),
        paint,
      );

      if (isMajor) {
        final textSpan = TextSpan(
          text:
              '${i % 24 == 0 ? 12 : i % 12}${i < 12 || i == 24 ? 'AM' : 'PM'}',
          style: TextStyle(
            color: Colors.grey.withOpacity(opacity),
            fontSize: 8,
          ),
        );
        final textPainter = TextPainter(
          text: textSpan,
          // textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(0, y));
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
