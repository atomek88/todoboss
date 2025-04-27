import 'package:flutter/material.dart';

// Warm, metallic-glazed UI with soft shading
const lightColorScheme = ColorScheme(
  brightness: Brightness.light,
  // Warm bronze primary color
  primary: Color(0xFFCD7F32),
  onPrimary: Color(0xFFF8F0E3),
  primaryContainer: Color(0xFFE8C9A3),
  onPrimaryContainer: Color(0xFF5D4037),
  // Soft gold accent
  secondary: Color(0xFFD4AF37),
  onSecondary: Color(0xFF3E2723),
  secondaryContainer: Color(0xFFF5E7C1),
  onSecondaryContainer: Color(0xFF5D4037),
  // Warm copper tertiary
  tertiary: Color(0xFFB87333),
  onTertiary: Color(0xFFF8F0E3),
  tertiaryContainer: Color(0xFFE6CCAD),
  onTertiaryContainer: Color(0xFF4E342E),
  // Error states
  error: Color(0xFFB71C1C),
  onError: Color(0xFFFFF8E1),
  errorContainer: Color(0xFFFFCDD2),
  onErrorContainer: Color(0xFF4E342E),
  // Surface colors with warm texture feel
  surface: Color(0xFFF5EFE6),
  onSurface: Color(0xFF3E2723),
  // Outline for subtle metallic borders
  outline: Color(0xFFBCAAA4),
  // Inverse colors
  inverseSurface: Color(0xFF5D4037),
  onInverseSurface: Color(0xFFF5EFE6),
  inversePrimary: Color(0xFFE8C9A3),
  // Shadow with slight metallic tint
  shadow: Color(0x55A1887F),
  // Surface tint for metallic glaze
  surfaceTint: Color(0xFFD4AF37),

  onSurfaceVariant: Color(0xFF5D4037),
);

// Dark theme with warm metallic feel
const darkColorScheme = ColorScheme(
  brightness: Brightness.dark,
  // Deep bronze primary
  primary: Color(0xFFE8C9A3),
  onPrimary: Color(0xFF3E2723),
  primaryContainer: Color(0xFF8D6E63),
  onPrimaryContainer: Color(0xFFF5EFE6),
  // Muted gold secondary
  secondary: Color(0xFFF5E7C1),
  onSecondary: Color(0xFF4E342E),
  secondaryContainer: Color(0xFF8D6E63),
  onSecondaryContainer: Color(0xFFF5EFE6),
  // Warm copper tertiary
  tertiary: Color(0xFFE6CCAD),
  onTertiary: Color(0xFF3E2723),
  tertiaryContainer: Color(0xFF8D6E63),
  onTertiaryContainer: Color(0xFFF5EFE6),
  // Error states
  error: Color(0xFFEF9A9A),
  onError: Color(0xFF3E2723),
  errorContainer: Color(0xFF8D6E63),
  onErrorContainer: Color(0xFFF5EFE6),
  // Surface colors with dark warm texture
  surface: Color(0xFF3E2723),
  onSurface: Color(0xFFF5EFE6),
  // Outline for subtle metallic borders
  outline: Color(0xFFD7CCC8),
  // Inverse colors
  inverseSurface: Color(0xFFECE0D1),
  onInverseSurface: Color(0xFF4E342E),
  inversePrimary: Color(0xFF8D6E63),
  // Shadow with slight metallic tint
  shadow: Color(0x66000000),
  // Surface tint for metallic glaze
  surfaceTint: Color(0xFFE8C9A3),

  onSurfaceVariant: Color(0xFFECE0D1),
  outlineVariant: Color(0xFFBCAAA4),
  scrim: Color(0xFF000000),
);
