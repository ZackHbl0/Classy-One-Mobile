import 'package:flutter/material.dart';
import 'dashboard_page.dart';
import 'planning_page.dart';
import 'evenements_page.dart';
import 'paiement_page.dart';
import 'documents_page.dart';
import '../widgets/modern_nav_bar.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    DashboardPage(),
    PlanningPage(),
    EvenementsPage(),
    PaiementPage(),
    DocumentsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBody: false, // Page content stops above the navbar
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF8F9FE),
      body: SafeArea(child: _pages[_currentIndex]),
      bottomNavigationBar: CustomModernNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          NavBarItem(
            icon: Icons.home_rounded,
            activeIcon: Icons.home_rounded,
            label: '',
          ),
          NavBarItem(
            icon: Icons.calendar_month_rounded,
            activeIcon: Icons.calendar_month_rounded,
            label: '',
          ),
          NavBarItem(
            icon: Icons.event_rounded,
            activeIcon: Icons.event_rounded,
            label: '',
          ),
          NavBarItem(
            icon: Icons.credit_card_rounded,
            activeIcon: Icons.credit_card_rounded,
            label: '',
          ),
          NavBarItem(
            icon: Icons.description_rounded,
            activeIcon: Icons.description_rounded,
            label: '',
          ),
        ],
      ),
    );
  }
}
