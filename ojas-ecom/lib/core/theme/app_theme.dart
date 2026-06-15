import 'package:flutter/material.dart';
import 'package:ojas_user/core/constants/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Light Theme
  static final ThemeData lightTheme = ThemeData(
    primaryColor: AppColors.primaryIndigo,
    scaffoldBackgroundColor: AppColors.bgPrimaryLight,
    brightness: Brightness.light,
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primaryIndigo,
      brightness: Brightness.light,
      surface: AppColors.bgSecondaryLight,
      onSurface: AppColors.textPrimary,
      primary: AppColors.primaryBlue,
      secondary: AppColors.accentOrange,
    ),
    textTheme: GoogleFonts.interTextTheme().copyWith(
      displayLarge: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
      displayMedium: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
      titleLarge: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.borderLight),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.borderLight),
      ),
    ),
  );

  // Dark Theme (Optional but kept for premium feel if needed)
  static final ThemeData darkTheme = ThemeData(
    primaryColor: AppColors.primaryIndigo,
    scaffoldBackgroundColor: AppColors.bgPrimaryDark,
    brightness: Brightness.dark,
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primaryIndigo,
      brightness: Brightness.dark,
      primary: AppColors.primaryBlue,
    ),
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
  );
}

