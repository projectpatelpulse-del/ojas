import 'package:flutter/material.dart';

class AppColors {
  // Website Color Palette (Exact mapping from requested colors)
  static const Color creamBg = Color(0xFFF8F4F0);        // Cream (Main Background)
  static const Color maroonFestive = Color(0xFF6B1D1D);   // Maroon (Festive Sale Banner)
  static const Color brightRedAccent = Color(0xFFE2232A); // Bright Red (Accent Strip)
  static const Color goldAccent = Color(0xFFC69248);      // Gold (Buttons & Accents)
  static const Color silver = Color(0xFFC5C7C8);          // Silver (Silverware)
  static const Color charcoal = Color(0xFF2E3133);        // Charcoal (Text & Nav)
  static const Color cardBgBeige = Color(0xFFECDCD0);     // Card Background (Soft Beige)
  static const Color cardBorderTint = Color(0xFFD1BBAA);  // Card Border/Shadow Tint

  // Role Mappings to existing variables for seamless integration
  static const Color primaryIndigo = cardBgBeige;         // Card Background (Soft Beige)
  static const Color primaryBlue = goldAccent;            // Gold (Buttons & Accents)
  static const Color accentOrange = goldAccent;           // Gold
  static const Color accentOrangeHover = Color(0xFFB07F37); // Darker Gold for hover
  static const Color primaryPink = maroonFestive;
  // brightRedAccent;       // Accent Strip / Bright Red
  
  // Backgrounds
  static const Color bgPrimaryLight = creamBg;
  static const Color bgSecondaryLight = cardBgBeige;
  static const Color bgPrimaryDark = Color(0xFF1E1C1A);
  
  // Text
  static const Color textPrimary = charcoal;
  static const Color textSecondary = Color(0xFF5E6266);
  static const Color textOnPrimary = charcoal;
  
  // Borders
  static const Color borderLight = cardBorderTint;
  static const Color borderHover = Color(0xFFBCA696);

  // Gradients
  static const LinearGradient initialGradient = LinearGradient(
    colors: [primaryIndigo, primaryBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient indigoBlueGradient = LinearGradient(
    colors: [charcoal, Color(0xFF1E2021), Color(0xFF111213)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient orangeGradient = LinearGradient(
    colors: [goldAccent, Color(0xFFAC7C38)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Legacy Compatibility (Required for existing Auth/Shell screens)
  static const Color accentPink = primaryPink; 
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
    colors: [primaryBlue, Color(0xFFE5B842)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Basic Utility Colors
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color transparent = Colors.transparent;
  static const MaterialColor successGreen = Colors.green;
  static const MaterialColor errorRed = Colors.red;
  static const MaterialColor grey = Colors.grey;

  // Shades
  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey800 = Color(0xFF424242);
  static const Color grey900 = Color(0xFF212121);

  static const Color red50 = Color(0xFFFFEBEE);
  static const Color red100 = Color(0xFFFFCDD2);
  static const Color red200 = Color(0xFFEF9A9A);
  static const Color red300 = Color(0xFFE57373);
  static const Color red400 = Color(0xFFEF5350);
  static const Color red500 = Color(0xFFF44336);
  static const Color red600 = Color(0xFFE53935);
  static const Color red700 = Color(0xFFD32F2F);
  static const Color red800 = Color(0xFFC62828);
  static const Color red900 = Color(0xFFB71C1C);

  static const Color green50 = Color(0xFFE8F5E9);
  static const Color green100 = Color(0xFFC8E6C9);
  static const Color green200 = Color(0xFFA5D6A7);
  static const Color green300 = Color(0xFF81C784);
  static const Color green400 = Color(0xFF66BB6A);
  static const Color green500 = Color(0xFF4CAF50);
  static const Color green600 = Color(0xFF43A047);
  static const Color green700 = Color(0xFF388E3C);
  static const Color green800 = Color(0xFF2E7D32);
  static const Color green900 = Color(0xFF1B5E20);

  static const Color blue50 = Color(0xFFE3F2FD);
  static const Color blue100 = Color(0xFFBBDEFB);
  static const Color blue200 = Color(0xFF90CAF9);
  static const Color blue300 = Color(0xFF64B5F6);
  static const Color blue400 = Color(0xFF42A5F5);
  static const Color blue500 = Color(0xFF2196F3);
  static const Color blue600 = Color(0xFF1E88E5);
  static const Color blue700 = Color(0xFF1976D2);
  static const Color blue800 = Color(0xFF1565C0);
  static const Color blue900 = Color(0xFF0D47A1);

  // Opacity Constants
  static const Color white24 = Color(0x3DFFFFFF);
  static const Color white70 = Color(0xB3FFFFFF);
  static const Color white60 = Color(0x99FFFFFF);
  static const Color white54 = Color(0x8AFFFFFF);
  static const Color white38 = Color(0x62FFFFFF);
  static const Color white30 = Color(0x4DFFFFFF);
  static const Color white12 = Color(0x1FFFFFFF);
  static const Color white10 = Color(0x1AFFFFFF);

  static const Color black87 = Color(0xDE000000);
  static const Color black54 = Color(0x8A000000);
  static const Color black45 = Color(0x73000000);
  static const Color black38 = Color(0x62000000);
  static const Color black26 = Color(0x42000000);
  static const Color black12 = Color(0x1F000000);
}
