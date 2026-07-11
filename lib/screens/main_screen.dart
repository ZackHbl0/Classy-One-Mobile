import 'package:flutter/material.dart';
import 'dashboard_page.dart';
import 'planning_page.dart';
import 'evenements_page.dart';
import 'paiement_page.dart';
import 'profile_page.dart';
import '../widgets/modern_nav_bar.dart';
import '../widgets/custom_sidebar.dart';
import 'courses_screen.dart';

class MainScreen extends StatefulWidget {
  static final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

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
    const PaiementPage(showBackButton: false),
    const ProfilePage(),
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
      icon: Icons.credit_card_outlined,
      activeIcon: Icons.credit_card_rounded,
      label: 'Paiement',
    ),
    NavBarItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Profil',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      key: MainScreen.scaffoldKey,
      extendBody: false,
      backgroundColor: isDark
          ? const Color(0xFF1E241E)
          : const Color(0xFFF6F7F2),
      drawer: const CustomSidebar(currentRoute: '/home'),
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
