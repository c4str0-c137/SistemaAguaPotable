import 'package:flutter/material.dart';

class AppColors {
  // Primary (Water Theme)
  static const Color primary = Color(0xFF0077B6);
  static const Color primaryLight = Color(0xFF00B4D8);
  static const Color primaryDark = Color(0xFF03045E);
  
  // Secondary / Accent
  static const Color secondary = Color(0xFF90E0EF);
  static const Color accent = Color(0xFFCAF0F8);
  
  // Semantic Colors
  static const Color success = Color(0xFF2DCE89);
  static const Color error = Color(0xFFF5365C);
  static const Color warning = Color(0xFFFB6340);
  static const Color info = Color(0xFF11CDEF);

  // Greys & Neutral
  static const Color background = Color(0xFFF8F9FE);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF32325D);
  static const Color textSecondary = Color(0xFF8898AA);
  
  // Dark Mode Palette
  static const Color darkBackground = Color(0xFF172B4D);
  static const Color darkSurface = Color(0xFF1E3A8A);
  static const Color darkText = Color(0xFFE9ECEF);
  
  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
