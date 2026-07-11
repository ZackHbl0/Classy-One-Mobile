import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // New Sage Green Primary Accent
  static const Color primaryBlue = Color(0xFF708C70); // Kept name for compatibility, but it's sage green
  static const Color primaryColor = Color(0xFF708C70);

  // Light Theme Colors
  static const Color lightBg = Color(0xFFE2E5E0); // Soft light green-gray
  static const Color lightCard = Color(0xFFF6F7F2); // Warm off-white/ivory
  static const Color lightTextPrimary = Color(0xFF2D3A2D);
  static const Color lightTextSecondary = Color(0xFF5A6B5A);

  // Dark Theme Colors
  static const Color darkBg = Color(0xFF1E241E); // Deep dark sage
  static const Color darkCard = Color(0xFF2A322A); // Dark sage card
  static const Color darkTextPrimary = Color(0xFFE2E5E0);
  static const Color darkTextSecondary = Color(0xFF8F9F8F);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: lightBg,
    cardColor: lightCard,
    colorScheme: ColorScheme.light(
      primary: primaryColor,
      secondary: primaryColor.withValues(alpha: 0.8),
      surface: lightCard,
      error: const Color(0xFFEF4444),
    ),
    textTheme: GoogleFonts.interTextTheme().apply(
      bodyColor: lightTextPrimary,
      displayColor: lightTextPrimary,
    ).copyWith(
      titleLarge: GoogleFonts.inter(
        color: lightTextPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 22,
        letterSpacing: -0.3,
      ),
      headlineSmall: GoogleFonts.inter(
        color: lightTextPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 24,
        letterSpacing: -0.4,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: lightBg,
      elevation: 0,
      centerTitle: true,
      iconTheme: const IconThemeData(color: lightTextPrimary),
      titleTextStyle: GoogleFonts.inter(
        color: lightTextPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 22,
        letterSpacing: -0.3,
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: darkBg,
    cardColor: darkCard,
    colorScheme: ColorScheme.dark(
      primary: primaryColor,
      secondary: primaryColor.withValues(alpha: 0.8),
      surface: darkCard,
      onSurface: darkTextPrimary,
      error: const Color(0xFFF87171),
    ),
    textTheme: GoogleFonts.interTextTheme(
      ThemeData.dark().textTheme,
    ).apply(bodyColor: darkTextPrimary, displayColor: darkTextPrimary).copyWith(
      titleLarge: GoogleFonts.inter(
        color: darkTextPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 22,
        letterSpacing: -0.3,
      ),
      headlineSmall: GoogleFonts.inter(
        color: darkTextPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 24,
        letterSpacing: -0.4,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: darkBg,
      elevation: 0,
      centerTitle: true,
      iconTheme: const IconThemeData(color: darkTextPrimary),
      titleTextStyle: GoogleFonts.inter(
        color: darkTextPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 22,
        letterSpacing: -0.3,
      ),
    ),
  );
}
