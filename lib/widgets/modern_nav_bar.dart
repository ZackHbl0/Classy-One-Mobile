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
// CustomModernNavBar  – Ultra-slim glassmorphic bottom bar
//
// Design:
//  • Height: 60 px (bar) + system padding
//  • Active state: icon switches to solid + primary-blue colour
//                  + a tiny glowing dot underneath
//                  + label fades in below dot
//  • Inactive: thin-line outline icon, slate-grey colour — no label
//  • Tap: bounce scale 1.0 → 1.25 → 1.0 with haptic
//  • Background: BackdropFilter blur 20 + semi-transparent white
//  • No large pill / circle background behind icons
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
  static const _blue = Color(0xFF0066FF); // Vibrant Primary Blue
  static const _inactiveL = Color(
    0xFF64748B,
  ); // Medium Slate Grey (High contrast)
  static const _inactiveD = Color(0xFF94A3B8); // Slate for Dark Mode
  static const _barHeight = 62.0;

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
        TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.28), weight: 40),
        TweenSequenceItem(tween: Tween(begin: 1.28, end: 0.92), weight: 30),
        TweenSequenceItem(tween: Tween(begin: 0.92, end: 1.0), weight: 30),
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

    return SizedBox(
      height: _barHeight + bottom,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: _barHeight + bottom,
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor.withValues(
                alpha: isDark ? 0.85 : 0.88,
              ),
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.05),
                  width: 0.8,
                ),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.only(bottom: bottom),
              child: Row(
                children: List.generate(widget.items.length, (i) {
                  return Expanded(
                    child: _NavItem(
                      item: widget.items[i],
                      isActive: widget.currentIndex == i,
                      bounceAnim: _bounceAnims[i],
                      activeColor: _blue,
                      inactiveColor: isDark ? _inactiveD : _inactiveL,
                      onTap: () => _handleTap(i),
                      isDark: isDark,
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _NavItem  – single icon + optional label + glow dot
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

class _NavItemState extends State<_NavItem>
    with SingleTickerProviderStateMixin {
  // Slide-in controller for the label + dot
  late AnimationController _labelCtrl;
  late Animation<double> _labelOpacity;
  late Animation<double> _labelSlide;

  @override
  void initState() {
    super.initState();
    _labelCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
    _labelOpacity = CurvedAnimation(
      parent: _labelCtrl,
      curve: Curves.easeInOut,
    );
    _labelSlide = Tween(
      begin: 8.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _labelCtrl, curve: Curves.easeInOut));
    if (widget.isActive) _labelCtrl.value = 1.0;
  }

  @override
  void didUpdateWidget(_NavItem old) {
    super.didUpdateWidget(old);
    if (widget.isActive && !old.isActive) {
      _labelCtrl.forward(from: 0.0);
    } else if (!widget.isActive && old.isActive) {
      _labelCtrl.reverse();
    }
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── Bounce-animated icon ───────────────────────────────────────
            AnimatedBuilder(
              animation: widget.bounceAnim,
              builder: (_, child) =>
                  Transform.scale(scale: widget.bounceAnim.value, child: child),
              child: AnimatedScale(
                scale: widget.isActive ? 1.15 : 1.0,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, anim) =>
                      ScaleTransition(scale: anim, child: child),
                  child: Icon(
                    widget.isActive ? widget.item.activeIcon : widget.item.icon,
                    key: ValueKey(widget.isActive),
                    color: widget.isActive
                        ? widget.activeColor
                        : widget.inactiveColor,
                    size: 24,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 5),

            // ── Glow dot + sliding label (active only) ─────────────────────
            AnimatedBuilder(
              animation: _labelCtrl,
              builder: (_, __) {
                return Opacity(
                  opacity: _labelOpacity.value,
                  child: Transform.translate(
                    offset: Offset(0, _labelSlide.value),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Glow dot
                        Container(
                          width: 22,
                          height: 3.5,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: widget.activeColor,
                            boxShadow: [
                              BoxShadow(
                                color: widget.activeColor.withValues(
                                  alpha: 0.6,
                                ),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                              BoxShadow(
                                color: widget.activeColor.withValues(
                                  alpha: 0.3,
                                ),
                                blurRadius: 4,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 3),
                        // Label — only for active
                        Text(
                          widget.item.label,
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            fontWeight:
                                FontWeight.w800, // Extra Bold for Active
                            color: widget.activeColor,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
