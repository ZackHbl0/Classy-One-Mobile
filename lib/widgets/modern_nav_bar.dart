import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// NavBarItem — unchanged model (backward-compatible with MainScreen)
// ─────────────────────────────────────────────────────────────────────────────
class NavBarItem {
  final IconData icon; // outline / inactive
  final IconData activeIcon; // solid / active
  final String label;

  const NavBarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// CustomModernNavBar  – Pill-shaped bottom bar matching img1
// ─────────────────────────────────────────────────────────────────────────────
class CustomModernNavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<NavBarItem> items;

  const CustomModernNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  State<CustomModernNavBar> createState() => _CustomModernNavBarState();
}

class _CustomModernNavBarState extends State<CustomModernNavBar>
    with TickerProviderStateMixin {
  // One bounce controller per item
  late List<AnimationController> _bounceControllers;
  late List<Animation<double>> _bounceAnims;

  // ── design tokens ────────────────────────────────────────────────────────
  static const _barHeight = 85.0; 

  @override
  void initState() {
    super.initState();
    _bounceControllers = List.generate(widget.items.length, (i) {
      return AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      );
    });
    _bounceAnims = _bounceControllers.map((ctrl) {
      return TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.15), weight: 40),
        TweenSequenceItem(tween: Tween(begin: 1.15, end: 0.95), weight: 30),
        TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.0), weight: 30),
      ]).animate(CurvedAnimation(parent: ctrl, curve: Curves.easeInOut));
    }).toList();
  }

  @override
  void dispose() {
    for (final c in _bounceControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _handleTap(int index) {
    HapticFeedback.lightImpact();
    _bounceControllers[index].forward(from: 0.0);
    widget.onTap(index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mq = MediaQuery.of(context);
    final bottom = mq.padding.bottom;
    
    final primaryColor = theme.primaryColor;
    final bgColor = isDark ? const Color(0xFF1E241E) : Colors.white;
    final inactiveColor = isDark ? Colors.white70 : const Color(0xFF64748B);

    return Container(
      margin: EdgeInsets.fromLTRB(16, 0, 16, bottom == 0 ? 20 : bottom),
      height: _barHeight,
      decoration: BoxDecoration(
        color: bgColor, 
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(widget.items.length, (i) {
            return Expanded(
              child: _NavItem(
                item: widget.items[i],
                isActive: widget.currentIndex == i,
                bounceAnim: _bounceAnims[i],
                activeColor: primaryColor,
                inactiveColor: inactiveColor,
                onTap: () => _handleTap(i),
                isDark: isDark,
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _NavItem  – vertical column with icon, text, and active indicator
// ─────────────────────────────────────────────────────────────────────────────
class _NavItem extends StatefulWidget {
  final NavBarItem item;
  final bool isActive;
  final Animation<double> bounceAnim;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;
  final bool isDark;

  const _NavItem({
    required this.item,
    required this.isActive,
    required this.bounceAnim,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
    required this.isDark,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  @override
  Widget build(BuildContext context) {
    final displayColor = widget.isActive ? widget.activeColor : widget.inactiveColor;
    
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: widget.bounceAnim,
        builder: (context, child) => Transform.scale(
          scale: widget.bounceAnim.value,
          child: child,
        ),
        child: Center(
          child: Stack(
            alignment: Alignment.bottomCenter,
            clipBehavior: Clip.none,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                padding: EdgeInsets.symmetric(
                  horizontal: widget.isActive ? 14.0 : 4.0, 
                  vertical: 10.0
                ),
                decoration: BoxDecoration(
                  color: widget.isActive 
                    ? (widget.isDark ? widget.activeColor.withOpacity(0.15) : widget.activeColor.withOpacity(0.08)) 
                    : Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.isActive ? widget.item.activeIcon : widget.item.icon,
                      color: displayColor,
                      size: 26,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.item.label,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.visible,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: widget.isActive ? FontWeight.w700 : FontWeight.w500,
                        color: displayColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.isActive)
                Positioned(
                  bottom: -1,
                  child: Container(
                    width: 20,
                    height: 4,
                    decoration: BoxDecoration(
                      color: widget.activeColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
