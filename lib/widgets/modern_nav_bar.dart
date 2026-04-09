import 'dart:ui';
import 'package:flutter/material.dart';

class CustomModernNavBar extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final double horizontalPadding = size.width * 0.08;
    final double barWidth = size.width - (horizontalPadding * 2);
    final double itemWidth = barWidth / items.length;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        10,
        horizontalPadding,
        20,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(35),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            height: 70,
            width: barWidth,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E293B).withOpacity(0.8)
                  : Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(35),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.05),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Sliding Active Indicator (The "Circle")
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.elasticOut,
                  left: currentIndex * itemWidth + (itemWidth - 54) / 2,
                  top: 8,
                  child: Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF3B82F6),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3B82F6).withOpacity(0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                ),
                // Icons - No labels
                Row(
                  children: items.asMap().entries.map((entry) {
                    int index = entry.key;
                    var item = entry.value;
                    bool isActive = currentIndex == index;

                    return Expanded(
                      child: GestureDetector(
                        onTap: () => onTap(index),
                        child: Center(
                          child: Icon(
                            isActive ? item.activeIcon : item.icon,
                            color: isActive
                                ? Colors.white
                                : (isDark ? Colors.white60 : Colors.black45),
                            size: 26,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class NavBarItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  NavBarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
