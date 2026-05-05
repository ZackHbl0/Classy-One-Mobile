import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryBlue = Color(0xFF0066FF);

  // Light Theme Colors
  static const Color lightBg = Color(0xFFF8FAFC);
  static const Color lightCard = Colors.white;
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF64748B);

  // Dark Theme Colors
  static const Color darkBg = Color(0xFF0F172A); // Deep Navy/Charcoal
  static const Color darkCard = Color(0xFF1E293B); // Slightly Lighter Slate
  static const Color darkTextPrimary = Color(0xFFF1F5F9);
  static const Color darkTextSecondary = Color(0xFF94A3B8);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: primaryBlue,
    scaffoldBackgroundColor: lightBg,
    cardColor: lightCard,
    colorScheme: ColorScheme.light(
      primary: primaryBlue,
      secondary: primaryBlue.withValues(alpha: 0.8),
      surface: lightCard,
      error: const Color(0xFFEF4444),
    ),
    textTheme: GoogleFonts.interTextTheme().apply(
      bodyColor: lightTextPrimary,
      displayColor: lightTextPrimary,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: lightBg,
      elevation: 0,
      iconTheme: IconThemeData(color: lightTextPrimary),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: primaryBlue,
    scaffoldBackgroundColor: darkBg,
    cardColor: darkCard,
    colorScheme: ColorScheme.dark(
      primary: primaryBlue,
      secondary: primaryBlue.withValues(alpha: 0.8),
      surface: darkCard,
      onSurface: darkTextPrimary,
      error: const Color(0xFFF87171),
    ),
    textTheme: GoogleFonts.interTextTheme(
      ThemeData.dark().textTheme,
    ).apply(bodyColor: darkTextPrimary, displayColor: darkTextPrimary),
    appBarTheme: const AppBarTheme(
      backgroundColor: darkBg,
      elevation: 0,
      iconTheme: IconThemeData(color: darkTextPrimary),
    ),
  );
}
