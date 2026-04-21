import 'package:flutter/material.dart';

abstract class AppColors {
  // Backgrounds
  static const Color background = Color(0xFFFAF6F0);
  static const Color surface = Color(0xFFFFF8EE);
  static const Color activeElement = Color(0xFFFFFFFF);

  // Brand
  static const Color primaryBrand = Color(0xFFC8A96E);
  static const Color secondaryBrand = Color(0xFF8B5E3C);

  // Status
  static const Color success = Color(0xFF4CAF50);
  static const Color eliminated = Color(0xFF9E9E9E);
  static const Color error = Color(0xFFD64045);

  // Text
  static const Color textPrimary = Color(0xFF2C1A0E);
  static const Color textSecondary = Color(0xFF7A6652);
  static const Color divider = Color(0xFFE8DDD0);

  // Payment
  static const Color paymentHighlight = Color(0xFF1A73E8);
  static const Color upiAccent = Color(0xFF5F259F);
  static const Color paymentSuccess = Color(0xFF00C853);

  // Card shadow
  static const Color cardShadow = Color(0x22C8A96E);

  // Gradients
  static const LinearGradient creamGradient = LinearGradient(
    colors: [Color(0xFFFAF6F0), Color(0xFFFFF3E0)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFC8A96E), Color(0xFF8B5E3C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
