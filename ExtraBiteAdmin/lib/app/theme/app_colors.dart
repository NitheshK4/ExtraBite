import 'package:flutter/material.dart';

class AppColors {
  // Brand & Semantic
  static const Color primary = Color(0xFF1B5E20); // Forest Emerald Green
  static const Color primaryDark = Color(0xFF0F3813); // Dark Emerald Sidebar
  static const Color primaryLight = Color(0xFFE8F5E9); // Mint Container Tint
  static const Color primaryContainer = Color(0xFFE8F5E9);
  static const Color onPrimary = Colors.white;
  static const Color onPrimaryContainer = Color(0xFF003300);

  static const Color secondary = Color(0xFFE65100); // Warm Amber Accent
  static const Color secondaryLight = Color(0xFFFFF3E0); // Warm Glow Pill
  static const Color secondaryContainer = Color(0xFFFFF3E0);
  static const Color onSecondary = Colors.white;
  static const Color onSecondaryContainer = Color(0xFF561900);

  static const Color tertiary = Color(0xFF1976D2); // Digital Pass Blue
  static const Color tertiaryLight = Color(0xFFE3F2FD);
  static const Color tertiaryContainer = Color(0xFFE3F2FD);
  static const Color onTertiary = Colors.white;
  
  // Surfaces & Backgrounds
  static const Color background = Color(0xFFF8F9FA); // Soft Neutral Canvas
  static const Color surface = Colors.white;
  static const Color surfaceDim = Color(0xFFF1F3F5);
  static const Color surfaceContainerLow = Color(0xFFF8F9FA);
  static const Color surfaceContainer = Colors.white;
  static const Color surfaceContainerHigh = Color(0xFFF1F3F5);
  static const Color surfaceContainerHighest = Color(0xFFE9ECEF);
  
  // Typography
  static const Color textPrimary = Color(0xFF1A1D1E);
  static const Color onSurface = Color(0xFF1A1D1E);
  static const Color textSecondary = Color(0xFF5A626A);
  static const Color onSurfaceVariant = Color(0xFF5A626A);
  static const Color textLight = Color(0xFF8D959E);
  
  // Borders & Feedback
  static const Color border = Color(0xFFE0E3E7);
  static const Color outline = Color(0xFFE0E3E7);
  static const Color outlineVariant = Color(0xFFCBD2D9);
  static const Color error = Color(0xFFD32F2F);
  static const Color errorLight = Color(0xFFFFEBEE);
  static const Color errorContainer = Color(0xFFFFEBEE);
  static const Color success = Color(0xFF2E7D32);
  
  // Veg / Non-Veg
  static const Color veg = Color(0xFF2E7D32);
  static const Color vegBg = Color(0xFFE8F5E9);
  static const Color nonVeg = Color(0xFFC62828);
  static const Color nonVegBg = Color(0xFFFFEBEE);

  // Status Colors
  static const Color statusConfirmed = Color(0xFFE65100);
  static const Color statusReady = Color(0xFF1976D2);
  static const Color statusCompleted = Color(0xFF2E7D32);
  static const Color statusCancelled = Color(0xFF757575);
}
