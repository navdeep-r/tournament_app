import 'package:flutter/material.dart';

import 'package:tournament_app/core/theme/app_colors.dart';

abstract class AppTypography {
  // Playfair Display — headings
  static TextStyle displayLarge = const TextStyle(
    fontFamily: 'Playfair Display',
    fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
    height: 1.2,
  );
  static TextStyle displayMedium = const TextStyle(
    fontFamily: 'Playfair Display',
    fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
    height: 1.25,
  );
  static TextStyle headlineLarge = const TextStyle(
    fontFamily: 'Playfair Display',
    fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
    height: 1.3,
  );
  static TextStyle headlineMedium = const TextStyle(
    fontFamily: 'Playfair Display',
    fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
    height: 1.3,
  );
  static TextStyle headlineSmall = const TextStyle(
    fontFamily: 'Playfair Display',
    fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
    height: 1.35,
  );
  static TextStyle titleLarge = const TextStyle(
    fontFamily: 'Playfair Display',
    fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
  );

  // Inter — body / labels
  static TextStyle bodyLarge = const TextStyle(
    fontFamily: 'Inter',
    fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.textPrimary,
    height: 1.5,
  );
  static TextStyle bodyMedium = const TextStyle(
    fontFamily: 'Inter',
    fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textPrimary,
    height: 1.5,
  );
  static TextStyle bodySmall = const TextStyle(
    fontFamily: 'Inter',
    fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.textSecondary,
    height: 1.5,
  );
  static TextStyle labelLarge = const TextStyle(
    fontFamily: 'Inter',
    fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
    letterSpacing: 0.1,
  );
  static TextStyle labelMedium = const TextStyle(
    fontFamily: 'Inter',
    fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary,
    letterSpacing: 0.5,
  );
  static TextStyle labelSmall = const TextStyle(
    fontFamily: 'Inter',
    fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textSecondary,
    letterSpacing: 0.5,
  );
  static TextStyle caption = const TextStyle(
    fontFamily: 'Inter',
    fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textSecondary,
  );
  static TextStyle button = const TextStyle(
    fontFamily: 'Inter',
    fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.activeElement,
    letterSpacing: 0.5,
  );
  static TextStyle queueNumber = const TextStyle(
    fontFamily: 'Playfair Display',
    fontSize: 64, fontWeight: FontWeight.w700, color: AppColors.primaryBrand,
  );
}
