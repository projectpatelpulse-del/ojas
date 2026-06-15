import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6B21A8), // Purple shade from UI
        primary: const Color(0xFF6B21A8),
      ),
      textTheme: GoogleFonts.interTextTheme(),
    );
  }
}
