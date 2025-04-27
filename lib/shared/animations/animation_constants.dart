import 'package:flutter/material.dart';

/// Animation constants used throughout the app
class AnimationConstants {
  /// Standard durations for animations
  static const Duration veryFast = Duration(milliseconds: 150);
  static const Duration fast = Duration(milliseconds: 300);
  static const Duration medium = Duration(milliseconds: 500);
  static const Duration slow = Duration(milliseconds: 700);
  static const Duration verySlow = Duration(milliseconds: 1000);

  /// Standard curves for animations
  static const Curve defaultCurve = Curves.easeInOut;
  static const Curve bouncyCurve = Curves.elasticOut;
  static const Curve sharpCurve = Curves.easeOutQuint;
  static const Curve gentleCurve = Curves.easeInOutCubic;
  
  /// Animation values
  static const double fullRotation = 2 * 3.14159; // 2π radians (360 degrees)
  static const double halfRotation = 3.14159; // π radians (180 degrees)
  static const double quarterRotation = 3.14159 / 2; // π/2 radians (90 degrees)
}
