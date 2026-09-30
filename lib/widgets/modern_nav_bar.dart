import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// NavBarItem â€“ unchanged model (backward-compatible with MainScreen)
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// CustomModernNavBar â€“ Refined floating pill bottom bar
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

  // â”€â”€ design tokens â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const _barHeight = 72.0;

  @override
  void initState() {
    super.initState();
    _bounceControllers = List.generate(widget.items.length, (i) {
      return AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 350),
      );
    });
    _bounceAnims = _bounceControllers.map((ctrl) {
      return TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.12), weight: 40),
        TweenSequenceItem(tween: Tween(begin: 1.12, end: 0.96), weight: 30),
        TweenSequenceItem(tween: Tween(begin: 0.96, end: 1.0), weight: 30),
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
    final bgColor = isDark ? const Color(0xFF1A1A22) : Colors.white;
    final inactiveColor = isDark ? const Color(0xFF8A8AA8) : const Color(0xFF64748B);

    return Container(
      margin: EdgeInsets.fromLTRB(14, 0, 14, bottom == 0 ? 16 : bottom),
      height: _barHeight,
      decoration: BoxDecoration(
        color: bgColor, 
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.45) : Colors.black.withValues(alpha: 0.07),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// _NavItem â€“ vertical column with icon, auto-scaled text, and active indicator
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                padding: EdgeInsets.symmetric(
                  horizontal: widget.isActive ? 6.0 : 2.0, 
                  vertical: 6.0,
                ),
                decoration: BoxDecoration(
                  color: widget.isActive 
                    ? (widget.isDark ? widget.activeColor.withValues(alpha: 0.16) : widget.activeColor.withValues(alpha: 0.10)) 
                    : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.isActive ? widget.item.activeIcon : widget.item.icon,
                      color: displayColor,
                      size: widget.isActive ? 23 : 22,
                    ),
                    const SizedBox(height: 3),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2.0),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          widget.item.label,
                          maxLines: 1,
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            fontWeight: widget.isActive ? FontWeight.w700 : FontWeight.w500,
                            color: displayColor,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.isActive)
                Positioned(
                  bottom: 0,
                  child: Container(
                    width: 16,
                    height: 3,
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
