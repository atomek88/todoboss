import 'package:flutter/material.dart';

/// Extension on BuildContext to easily access theme colors
extension ThemeExtension on BuildContext {
  // Access to color scheme
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  
  // Common colors for app bars and widgets
  Color get primaryColor => colorScheme.primary;
  Color get onPrimaryColor => colorScheme.onPrimary;
  Color get surfaceColor => colorScheme.surface;
  Color get onSurfaceColor => colorScheme.onSurface;
  
  // Background colors
  Color get backgroundPrimary => colorScheme.surface;
  Color get backgroundSecondary => colorScheme.surfaceVariant;
  
  // Text colors
  Color get textPrimary => colorScheme.onSurface;
  Color get textSecondary => colorScheme.onSurfaceVariant;
  
  // Utility colors
  Color get dividerColor => colorScheme.outline;
  Color get errorColor => colorScheme.error;
  
  // Text themes
  TextStyle? get titleLarge => Theme.of(this).textTheme.titleLarge;
  TextStyle? get titleMedium => Theme.of(this).textTheme.titleMedium;
  TextStyle? get bodyLarge => Theme.of(this).textTheme.bodyLarge;
  TextStyle? get bodyMedium => Theme.of(this).textTheme.bodyMedium;
}
