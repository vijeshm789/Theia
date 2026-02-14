import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // Brand Colors
  static const Color primaryGold = Color(0xFFD4AF37);
  static const Color secondarySilver = Color(0xFFC0C0C0);
  static const Color background = Color(0xFF1A1A2E);
  static const Color surface = Color(0xFF16213E);
  static const Color cardColor = Color(0xFF1F2940);
  static const Color cardColorLight = Color(0xFF263250);
  static const Color profitGreen = Color(0xFF00C853);
  static const Color lossRed = Color(0xFFFF1744);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0BEC5);
  static const Color textMuted = Color(0xFF78909C);
  static const Color dividerColor = Color(0xFF2A3A5C);
  static const Color shimmerBase = Color(0xFF1F2940);
  static const Color shimmerHighlight = Color(0xFF263250);
  static const Color stableYellow = Color(0xFFFFD740);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryGold,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: primaryGold,
        secondary: secondarySilver,
        surface: surface,
        error: lossRed,
        onPrimary: Color(0xFF1A1A2E),
        onSecondary: Color(0xFF1A1A2E),
        onSurface: textPrimary,
        onError: Colors.white,
      ),
      cardTheme: CardTheme(
        color: cardColor,
        elevation: 4,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: primaryGold),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primaryGold,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 16,
        selectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w400,
          fontSize: 11,
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: textPrimary,
          fontSize: 32,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          color: textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        headlineSmall: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: textSecondary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(
          color: textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
        bodyMedium: TextStyle(
          color: textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        bodySmall: TextStyle(
          color: textMuted,
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        labelLarge: TextStyle(
          color: primaryGold,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: dividerColor,
        thickness: 0.5,
      ),
      iconTheme: const IconThemeData(
        color: textSecondary,
        size: 24,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: cardColorLight,
        selectedColor: primaryGold,
        labelStyle: const TextStyle(color: textSecondary, fontSize: 13),
        secondaryLabelStyle: const TextStyle(color: background, fontSize: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
    );
  }
}
