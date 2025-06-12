import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF6366F1); // Indigo
  static const Color secondary = Color(0xFF818CF8); // Light Indigo
  static const Color accent = Color(0xFF4338CA); // Dark Indigo
  static const Color success = Color(0xFF10B981); // Emerald
  static const Color error = Color(0xFFEF4444); // Red
  static const Color warning = Color(0xFFF59E0B); // Amber

  // Background Colors
  static const Color background = Color(0xFFF8FAFC); // Light Gray
  static const Color surface = Color(0xFFFFFFFF); // White
  static const Color cardBackground = Color(0xFFF3F4F6); // Very Light Gray

  // Text Colors
  static const Color textPrimary = Color(0xFF1E293B); // Dark Gray
  static const Color textSecondary = Color(0xFF64748B); // Medium Gray
  static const Color textHint = Color(0xFF94A3B8); // Light Gray

  // Border Colors
  static const Color border = Color(0xFFE5E7EB); // Very Light Gray
  static const Color disabled = Color(0xFF94A3B8); // Light Gray

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, Color(0xFF8B5CF6)], // Indigo to Purple
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Glassmorphism effect
  static const LinearGradient glassGradient = LinearGradient(colors: [Color.fromRGBO(255, 255, 255, 0.1), Color.fromRGBO(255, 255, 255, 0.05)], begin: Alignment.topLeft, end: Alignment.bottomRight);

  // Card shadows
  static const BoxShadow cardShadow = BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.05), blurRadius: 20, offset: Offset(0, 10));

  // Button gradients
  static const LinearGradient buttonGradient = LinearGradient(colors: [primary, secondary], begin: Alignment.centerLeft, end: Alignment.centerRight);
}
