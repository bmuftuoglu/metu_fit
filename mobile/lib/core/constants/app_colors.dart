import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF2563EB);
  static const primaryDark = Color(0xFF1D4ED8);
  static const primaryLight = Color(0xFF3B82F6);
  static const secondary = Color(0xFF10B981);
  static const secondaryDark = Color(0xFF059669);
  static const tertiary = Color(0xFF8B5CF6);
  static const background = Color(0xFFF8FAFF);
  static const surface = Colors.white;
  static const error = Color(0xFFEF4444);
  static const warning = Color(0xFFF59E0B);
  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B);
  static const border = Color(0xFFE2E8F0);
  static const cardShadow = Color(0x08000000);

  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2563EB), Color(0xFF1E3A8A)],
  );

  static const secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF10B981), Color(0xFF065F46)],
  );

  static const calorieConsumed = Color(0xFF2563EB);
  static const calorieBurned = Color(0xFF10B981);
  static const calorieNet = Color(0xFFF59E0B);
}
