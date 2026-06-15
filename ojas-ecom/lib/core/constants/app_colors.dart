import 'package:flutter/material.dart';

class AppColors {
  // OJAS Branding Colors
  static const Color primaryIndigo = Color(0xFF1E1B4B); // Deep Indigo
  static const Color primaryBlue = Color(0xFF2563EB);   // Professional Blue
  static const Color accentOrange = Color(0xFFF97316);  // Orange for deals
  static const Color accentOrangeHover = Color(0xFFEA580C);
  
  // Backgrounds
  static const Color bgPrimaryLight = Color(0xFFFFFFFF);
  static const Color bgSecondaryLight = Color(0xFFF8FAFC); // Soft Grey/Slate
  static const Color bgPrimaryDark = Color(0xFF0F172A);
  
  // Text
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  
  // Borders
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color borderHover = Color(0xFFCBD5E1);

  // Gradients
  static const LinearGradient initialGradient = LinearGradient(
    colors: [primaryIndigo, primaryBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient indigoBlueGradient = LinearGradient(
    colors: [Color(0xFF1E1B4B), Color(0xFF312E81), Color(0xFF4338CA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient orangeGradient = LinearGradient(
    colors: [Color(0xFFFB923C), Color(0xFFF97316)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Legacy Compatibility (Required for existing Auth/Shell screens)
  static const Color accentPink = primaryBlue; 
  static const Color primaryPink = primaryBlue;
  static const Color blackDark = Color(0xff020617);
  static const Color navyDark = Color(0xff1a1f3a);
  static const Color midnightIndigo = Color(0xff1a1c2c);
  static const Color accentYellow = Color(0xffffd600);
  static const Color borderDark = Color(0xff1f2937);
  static const Color inputBgDark = Color(0xff0f172a);
  static const Color bgSecondaryDark = Color(0xff121826);
  static const Color textPrimaryDark = Color(0xffffffff);
  static const Color textSecondaryDark = Color(0xffa0a7b5);

  static const RadialGradient bgRadialGradient = RadialGradient(
    center: Alignment.topCenter,
    radius: 1.5,
    colors: [Color(0xff1a1f3a), Color(0xff020617)],
  );

  static const LinearGradient darkNavbarGradient = LinearGradient(
    colors: [Color(0xff121826), Color(0xff0b0f1a)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient pinkGradient = LinearGradient(
    colors: [primaryBlue, Color(0xFF3B82F6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
