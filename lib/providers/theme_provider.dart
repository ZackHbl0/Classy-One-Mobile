import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadFromPrefs();
  }

  void toggleTheme(bool isOn) {
    _isDarkMode = isOn;
    _saveToPrefs();
    notifyListeners();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    notifyListeners();
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
  }

  // Professional Dark Theme
  ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    fontFamily: GoogleFonts.outfit().fontFamily,
    textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
    scaffoldBackgroundColor: const Color(0xFF0F172A), // Deep Blue-Black
    primaryColor: const Color(0xFF203B68),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF3B82F6), // Professional Blue
      secondary: Color(0xFF10B981), // Success Green
      surface: Color(0xFF1E293B),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFF1E293B),
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.outfit(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF1E293B),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );

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
