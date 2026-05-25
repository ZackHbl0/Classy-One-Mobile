import 'package:flutter/material.dart';
import 'dashboard_page.dart';
import 'planning_page.dart';
import 'evenements_page.dart';
import 'paiement_page.dart';
import 'documents_page.dart';
import '../widgets/modern_nav_bar.dart';
import 'courses_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const DashboardPage(),
    const PlanningPage(),
    const CoursesScreen(),
    const EvenementsPage(),
    const PaiementPage(showBackButton: false),
    const DocumentsPage(),
  ];

  // ── Icon pairs: outline (inactive) → filled (active) ───────────────────────
  static const List<NavBarItem> _navItems = [
    NavBarItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Accueil',
    ),
    NavBarItem(
      icon: Icons.calendar_today_outlined,
      activeIcon: Icons.calendar_today_rounded,
      label: 'Agenda',
    ),
    NavBarItem(
      icon: Icons.school_outlined,
      activeIcon: Icons.school_rounded,
      label: 'Cours',
    ),
    NavBarItem(
      icon: Icons.event_outlined,
      activeIcon: Icons.event_rounded,
      label: 'Événements',
    ),
    NavBarItem(
      icon: Icons.credit_card_outlined,
      activeIcon: Icons.credit_card_rounded,
      label: 'Paiements',
    ),
    NavBarItem(
      icon: Icons.description_outlined,
      activeIcon: Icons.description_rounded,
      label: 'Documents',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBody: false,
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF8F9FE),
      body: SafeArea(
        bottom: false,
        child: IndexedStack(index: _currentIndex, children: _pages),
      ),
      bottomNavigationBar: CustomModernNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: _navItems,
      ),
    );
  }
}
