import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

class ThemeProvider with ChangeNotifier {
  bool get isDarkMode => false;

  ThemeProvider();

  void toggleTheme(bool isOn) {
    // Mode sombre supprimé définitivement
  }

  // Professional Light Theme
  ThemeData get lightTheme => ThemeData(
    brightness: Brightness.light,
    fontFamily: GoogleFonts.outfit().fontFamily,
    textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme),
    scaffoldBackgroundColor: const Color(0xFFF8F9FA),
    primaryColor: const Color(0xFF203B68),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF203B68),
      secondary: Color(0xFF10B981),
      surface: Colors.white,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFF203B68),
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.outfit(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}
