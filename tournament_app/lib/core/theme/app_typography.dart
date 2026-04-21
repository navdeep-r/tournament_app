import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tournament_app/core/theme/app_colors.dart';

abstract class AppTypography {
  // Playfair Display — headings
  static TextStyle displayLarge = GoogleFonts.playfairDisplay(
    fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
    height: 1.2,
  );
  static TextStyle displayMedium = GoogleFonts.playfairDisplay(
    fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
    height: 1.25,
  );
  static TextStyle headlineLarge = GoogleFonts.playfairDisplay(
    fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
    height: 1.3,
  );
  static TextStyle headlineMedium = GoogleFonts.playfairDisplay(
    fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
    height: 1.3,
  );
  static TextStyle headlineSmall = GoogleFonts.playfairDisplay(
    fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
    height: 1.35,
  );
  static TextStyle titleLarge = GoogleFonts.playfairDisplay(
    fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
  );

  // Inter — body / labels
  static TextStyle bodyLarge = GoogleFonts.inter(
    fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.textPrimary,
    height: 1.5,
  );
  static TextStyle bodyMedium = GoogleFonts.inter(
    fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textPrimary,
    height: 1.5,
  );
  static TextStyle bodySmall = GoogleFonts.inter(
    fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.textSecondary,
    height: 1.5,
  );
  static TextStyle labelLarge = GoogleFonts.inter(
    fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
    letterSpacing: 0.1,
  );
  static TextStyle labelMedium = GoogleFonts.inter(
    fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary,
    letterSpacing: 0.5,
  );
  static TextStyle labelSmall = GoogleFonts.inter(
    fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textSecondary,
    letterSpacing: 0.5,
  );
  static TextStyle caption = GoogleFonts.inter(
    fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textSecondary,
  );
  static TextStyle button = GoogleFonts.inter(
    fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.activeElement,
    letterSpacing: 0.5,
  );
  static TextStyle queueNumber = GoogleFonts.playfairDisplay(
    fontSize: 64, fontWeight: FontWeight.w700, color: AppColors.primaryBrand,
  );
}
