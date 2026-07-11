import 'package:flutter/material.dart';
import '../widgets/screen_header.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';


class PerformancesPage extends StatelessWidget {
  const PerformancesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF1E241E)
          : const Color(0xFFE2E5E0),
      body: Column(
        children: [
          const ScreenHeader(title: 'Performances', showBackButton: true),
          Expanded(
            child: Center(
              child: Text(
                'Page Performances en cours de développement...',
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
